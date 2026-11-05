import { Router } from "express";
import * as c from "../controllers/categoryController.js";
import {auth} from "../middleware/auth.js";
import {authorize} from "../middleware/authorize.js";

const router = Router();
router.use(auth);
router.get("/", c.list);
router.post("/", authorize("admin"), c.create);
router.put("/:id", authorize("admin"), c.update);
router.delete("/:id", authorize("admin"), c.remove);

export default router;

/*
GET /api/categories
POST /api/categories
PUT /api/categories/<id>
DELETE /api/categories/<id>
*/