import { Router } from "express";
import * as o from "../controllers/orderController.js";
import { auth } from "../middleware/auth.js";
import { authorize } from "../middleware/authorize.js";

const router = Router();
router.use(auth, authorize("admin", "cashier"));
router.get("/", o.list);
router.get("/:id", o.getOne);
router.post("/", o.create);
router.put("/:id", o.update);
router.delete("/:id", o.remove);
export default router;

/*
GET /api/orders
GET /api/orders/<id>
POST /api/orders
PUT /api/orders/<id>
DELETE /api/orders/<id>
*/