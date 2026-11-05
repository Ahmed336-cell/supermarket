import mongoose from "mongoose";
const OrderStatus = ["pending", "confirmed", "shipped", "delivered", "cancelled"];

const itemSchema = new mongoose.Schema({
  product:{type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true},
  name :String,
  quantity:{type: Number, required: true , min: 1},
  unitPrice:{type: Number, required: true , min: 0},
  discountPercentage:{type: Number, default: 0 , min: 0 , max: 100},
  lineTotal:{type: Number, required: true , min: 0},

},
{_id: false}
);

const orderSchema = new mongoose.Schema({
cashier:{type: mongoose.Schema.Types.ObjectId, ref: "User", required: true},
items:{type: [itemSchema], required: true},
subtotal:{type: Number, required: true , min: 0},
orderDiscountPercent : {type: Number, default: 0 , min: 0 , max: 100},
total:{type: Number, required: true , min: 0},
status:{type: String, enum: OrderStatus, default: "pending"},
createdAt:{type: Date, default: Date.now},
updatedAt:{type: Date, default: Date.now},
});

export const Order = mongoose.model("Order", orderSchema);
