// src/routes/auth.routes.ts

import { Router, Request, Response } from 'express';
import { registerUser } from '../controllers/auth.controller';
import { isAuthenticated } from '../middleware/auth.middleware'; // 1. Importe o middleware

const authRouter = Router();

authRouter.post('/register', registerUser);

// 2. Nova rota protegida para testar o middleware
// Note como 'isAuthenticated' é passado ANTES da função final
authRouter.get('/me', isAuthenticated, (req: Request, res: Response) => {
  // Graças ao middleware, agora temos acesso a req.currentUser
  const user = req.currentUser;

  res.status(200).json({
    message: `Olá, ${user?.email}! Seu UID é ${user?.uid}.`,
    user: user,
  });
});

export default authRouter;