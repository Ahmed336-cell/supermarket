import dotenv from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";

dotenv.config({
  path: path.join(path.dirname(fileURLToPath(import.meta.url)), "../.env"),
});
import app from "./app.js";
import { connectDb } from "./config/db.js";

const port = process.env.PORT || 4000;

await connectDb();
app.listen(port, () => console.log(`API on http://localhost:${port}`));