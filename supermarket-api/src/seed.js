import dotenv from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";

dotenv.config({
  path: path.join(path.dirname(fileURLToPath(import.meta.url)), "../.env"),
});
import { connectDb } from "./config/db.js";
import { User } from "./models/User.js";

await connectDb();
const email = "admin@shop.local";
const exists = await User.findOne({ email });
if (!exists) {
  await User.create({
    name: "Admin",
    email,
    password: "Admin123!",
    role: "admin",
  });
  console.log("Admin created:", email);
} else {
  console.log("Admin already exists");
}
process.exit(0);