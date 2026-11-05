import mongoose from "mongoose";
const supplierSchema = new mongoose.Schema({
  name : {type: String, required: true , trim: true},
  email : {type: String, trim: true , lowercase: true , default: ""},
  phone : {type: String, trim: true , default: ""},
  address : {type: String, trim: true , default: ""},
  createdAt : {type: Date, default: Date.now},
  updatedAt : {type: Date, default: Date.now},
});
export const Supplier = mongoose.model("Supplier", supplierSchema);