import mongoose from "mongoose";
const productSchema = new mongoose.Schema({
  name : {type: String, required: true , trim: true},
  description : {type: String, trim: true , default: ""},
  price : {type: Number, required: true , min: 0},
  quantity : {type: Number, required: true , min: 0},
  stock : {type: Number, required: true , min: 0},
  discountPercentage : {type: Number, default: 0 , min: 0 , max: 100},
  category : {type: mongoose.Schema.Types.ObjectId, ref: "Category", required: true},
  supplier : {type: mongoose.Schema.Types.ObjectId, ref: "Supplier", required: true},
  createdAt : {type: Date, default: Date.now},
  updatedAt : {type: Date, default: Date.now},
  lowStockThreshold : {type: Number, default: 10 , min: 0},
});

productSchema.index({ name: "text" });
productSchema.index({ category: 1 });
productSchema.virtual("isLowStock").get(function(){
return this.stock <=this.lowStockThreshold;
});
productSchema.set("toJSON", {virtuals: true});
export const Product = mongoose.model("Product", productSchema);
