import { Router } from "express";
import * as p from "../controllers/productController.js";
import {auth} from "../middleware/auth.js";
import {authorize} from "../middleware/authorize.js";


const router = Router();
router.use(auth);
router.get("/", p.list);
router.get("/:id", p.getProduct);
router.post("/", authorize("admin"), p.create);
router.put("/:id", authorize("admin"), p.update);
router.delete("/:id", authorize("admin"), p.remove);
router.post("/:id/restock", authorize("admin"), p.restock);

export default router;


/*
GET /api/products?q=milk&page=1&limit=10
GET /api/products?category=<id>&lowStock=true
GET /api/products/<id>
POST /api/products
PUT /api/products/<id>
DELETE /api/products/<id>
POST /api/products/<id>/restock
*/