import mongoose from "mongoose";
const categoryScehma = new mongoose.Schema({
  name : {type: String, required: true , trim: true , unique: true},
  description : {type: String, trim: true , default: ""},
  createdAt : {type: Date, default: Date.now},
  updatedAt : {type: Date, default: Date.now},
});
export const Category = mongoose.model("Category", categoryScehma);