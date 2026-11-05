import mongoose from "mongoose";
import bcrypt from "bcryptjs";
const userSchema = new mongoose.Schema({
  name : {type: String, required: true , trim: true},
  email : {type: String, required: true , trim: true , unique: true , lowercase: true},
  password : {type: String, required: true , trim: true , minlength: 8 , select:false},
  role : {type: String, enum: ["admin", "cashier"], default: "cashier"},
  createdAt : {type: Date, default: Date.now},
  updatedAt : {type: Date, default: Date.now}, 
});
userSchema.pre("save",async function(){
if (!this.isModified("password")) return;
this.password = await bcrypt.hash(this.password, 10);
});
userSchema.methods.comparePassword = async function(npassword){
return await bcrypt.compare(npassword, this.password);
};

export const User = mongoose.model("User", userSchema);