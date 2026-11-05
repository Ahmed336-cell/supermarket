import { Router } from "express";
import * as s from "../controllers/supplierController.js";
import {auth} from "../middleware/auth.js";
import {authorize} from "../middleware/authorize.js";

const router = Router();
router.use(auth);
router.get("/", s.list);
router.post("/", authorize("admin"), s.create);
router.put("/:id", authorize("admin"), s.update);
router.delete("/:id", authorize("admin"), s.remove);

export default router;

/*
GET /api/suppliers
POST /api/suppliers
PUT /api/suppliers/<id>
DELETE /api/suppliers/<id>
*/