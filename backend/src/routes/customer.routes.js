import express from 'express';
import { requireAuth } from '../middlewares/auth.middleware.js';
import { requireRole } from '../middlewares/role.middleware.js';
import { addAddress, getAddresses, deleteAddress, setDefaultAddress, searchAddresses} from '../controllers/customer_address.controller.js';

const router = express.Router();

router.get(
  '/dashboard',
  requireAuth,
  requireRole('customer'),
  (req, res) => {
    res.json({
      message: 'Welcome customer',
      userId: req.user.userId,
    });
  }
);
router.post("/address", requireAuth, addAddress);
router.get("/address", requireAuth, getAddresses);
router.delete("/address/:id", requireAuth, deleteAddress);
router.put("/address/:id/default", requireAuth, setDefaultAddress);
router.get("/address/search", requireAuth, searchAddresses);

export default router;