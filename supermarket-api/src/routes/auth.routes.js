import { Router } from "express";
import {register, login, logout, getMe} from "../controllers/authController.js";
import { auth } from "../middleware/auth.js";
import { authorize } from "../middleware/authorize.js";

const router = Router();

router.post("/register", auth, authorize("admin"), register);
router.post("/login", login);
router.post("/logout", auth, logout);
router.get("/me", auth, getMe);

export default router;

/*
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
GET /api/auth/me
*/