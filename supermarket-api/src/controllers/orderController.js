import mongoose from "mongoose";
import { Product } from "../models/Product.js";
import { Order } from "../models/Order.js";

function lineTotal(price, qty, discountPercent) {
  return Math.round(price * qty * (1 - discountPercent / 100) * 100) / 100;
}

export async function create(req, res, next) {
  try {
    const { items, orderDiscountPercent = 0 } = req.body;
    if (!Array.isArray(items) || items.length === 0) {
      throw Object.assign(new Error("items required"), { status: 400 });
    }

    const built = [];
    const warnings = [];

    for (const row of items) {
      if (!mongoose.isValidObjectId(row.product)) {
        throw Object.assign(new Error("items[].product must be a product _id"), { status: 400 });
      }
      const product = await Product.findById(row.product);
      if (!product) throw Object.assign(new Error("Product not found"), { status: 404 });
      if (product.stock < row.quantity) {
        throw Object.assign(
          new Error(`Not enough stock for ${product.name}`),
          { status: 400 }
        );
      }

      product.stock -= row.quantity;
      await product.save();

      const discount = row.discountPercent ?? product.discountPercentage ?? 0;
      const lt = lineTotal(product.price, row.quantity, discount);
      built.push({
        product: product._id,
        name: product.name,
        quantity: row.quantity,
        unitPrice: product.price,
        discountPercentage: discount,
        lineTotal: lt,
      });

      if (product.stock <= product.lowStockThreshold) {
        warnings.push(`${product.name} low (${product.stock} left)`);
      }
    }

    const subtotal = built.reduce((s, i) => s + i.lineTotal, 0);
    const total =
      Math.round(subtotal * (1 - orderDiscountPercent / 100) * 100) / 100;

    const order = await Order.create({
      cashier: req.user._id,
      items: built,
      subtotal,
      orderDiscountPercent,
      total,
    });

    res.status(201).json({ ...order.toObject(), lowStockWarnings: warnings });
  } catch (err) {
    next(err);
  }
}

export async function list(req, res, next) {
  try {
    const filter = req.user.role === "admin" ? {} : { cashier: req.user._id };
    const orders = await Order.find(filter)
      .populate("cashier", "name email")
      .sort("-createdAt")
      .limit(100);
    res.json(orders);
  } catch (err) {
    next(err);
  }
}

export async function getOne(req, res, next) {
  try {
    const order = await Order.findById(req.params.id).populate("cashier", "name");
    if (!order) return res.status(404).json({ message: "Not found" });
    if (req.user.role !== "admin" && String(order.cashier) !== String(req.user._id)) {
      return res.status(403).json({ message: "Forbidden" });
    }
    res.json(order);
  } catch (err) {
    next(err);
  }
}

export async function update(req, res, next) {
  try {
    const order = await Order.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!order) return res.status(404).json({ message: "Not found" });
    res.json(order);
  } catch (err) {
    next(err);
  }
}

export async function remove(req, res, next) {
  try {
    const order = await Order.findByIdAndDelete(req.params.id);
    if (!order) return res.status(404).json({ message: "Not found" });
    res.status(204).end();
  } catch (err) {
    next(err);
  }
}   