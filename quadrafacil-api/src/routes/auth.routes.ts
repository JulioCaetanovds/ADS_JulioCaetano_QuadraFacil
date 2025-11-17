// src/routes/auth.routes.ts

import { Router } from 'express';
// 1. Importa as funções do controller
import { 
  registerUser, 
  getUserProfile, 
  updateUserProfile 
} from '../controllers/auth.controller';
import { isAuthenticated } from '../middleware/auth.middleware';

const authRouter = Router();

// Rota de Registro
authRouter.post('/register', registerUser);

// Rota protegida GET para buscar o perfil do usuário
// (Lógica movida para o controller)
authRouter.get('/me', isAuthenticated, getUserProfile);

// Rota protegida PUT para ATUALIZAR o perfil do usuário (RF10)
authRouter.put('/me', isAuthenticated, updateUserProfile);

export default authRouter;