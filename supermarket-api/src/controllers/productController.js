import { Product } from "../models/Product.js";


export async function list(req,res,next){
    try{
        const {
            q,
            category,
            supplier,
            lowStock,
            page=1,
            limit=20,
        }= req.query;
        const filter = {};
        if(q)filter.$text={$search: q};
        if(category)filter.category=category;
        if(supplier)filter.supplier=supplier;
        if(lowStock =="true"){
            filter.$expr = { $lte: ["$stock", "$lowStockThreshold"] };
        }
        const skip = (Number(page)-1)*Number(limit);
        const [  items, total] = await Promise.all([
            Product.find(filter)
        .populate("category","name")
        .populate("supplier","name")
        .skip(skip)
        .limit(Number(limit))
        .sort("-createdAt"),
        Product.countDocuments(filter),
        ]);

        res.json({
            items,
            total,
            page:Number(page),
            limit:Math.ceil(total/Number(limit)),
        })
    }catch(error){
        next(error);
    }
}


export async function getProduct(req,res,next){
    try{
        const doc = await Product.findById(req.params.id)
        .populate("category","name")
        .populate("supplier","name")
        if(!doc)return res.status(404).json({message: "Product not found"});
        res.json(doc);
    }catch(error){
        next(error);
    }
}

export async function create(req,res,next){
    try{
        const doc = new Product(req.body);
        await doc.save();
        res.status(201).json(doc);
    }catch(error){
        next(error);
    }

}


export async function update(req,res,next){
    try{
        const doc = await Product.findByIdAndUpdate(req.params.id ,req.body , {new: true , runValidators: true});
        if(!doc)return res.status(404).json({message: "Product not found"});
        res.json(doc);
    }catch(error){
        next(error);
    }
}

export async function remove(req,res,next){

try{

    const doc = await Product.findByIdAndDelete(req.params.id);
    if(!doc)return res.status(404).json({message: "Product not found"});
    res.status(204).end();

}catch(error){
    next(error);
}

}


export async function restock(req,res,next){
try{
    const qty = Number(req.body.quantity);
    if(!qty|| qty <= 0)return res.status(400).json({message: "Invalid quantity : should be >=1"});
    const doc = await Product.findByIdAndUpdate(
        req.params.id,
        {$inc:{stock:qty}},
        {new: true , runValidators: true}
    );

    if(!doc)return res.status(404).json({message: "Product not found"});
    res.json(doc);

}catch(error){
    next(error);
}

}
