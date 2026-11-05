import { Supplier } from "../models/Supplier.js";

export async function list(req, res, next){
    try{
        res.json(await Supplier.find().sort("name"));
    }catch(error){
        next(error);
    }
}

export async function create(req, res, next){
    try{
        res.status(201).json(await Supplier.create(req.body));
    }catch(error){
        next(error);
    }
}

export async function update(req, res, next){
    try{
        const doc = await Supplier.findByIdAndUpdate(req.params.id, req.body, {new: true , runValidators: true});
        if(!doc)return res.status(404).json({message: "Supplier not found"});
        res.json(doc);
    }catch(error){
        next(error);
    }
}

export async function remove(req, res, next){   
    try{
        const doc = await Supplier.findByIdAndDelete(req.params.id, req.body, {new: true , runValidators: true});
        if(!doc)return res.status(404).json({message: "Supplier not found"});
        res.status(204).end();
    }catch(error){
        next(error);
    }
}