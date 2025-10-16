// src/routes/auth.routes.ts

import { Router, Request, Response } from 'express';
import { db } from '../config/firebase'; // Importamos o db
import { registerUser } from '../controllers/auth.controller';
import { isAuthenticated } from '../middleware/auth.middleware';

const authRouter = Router();

authRouter.post('/register', registerUser);

// Rota protegida atualizada para retornar o perfil do usuário
authRouter.get('/me', isAuthenticated, async (req: Request, res: Response) => {
  try {
    const { uid, email } = req.currentUser!; // Pegamos o UID do usuário verificado pelo middleware

    // Consultamos o documento do usuário no Firestore
    const userDoc = await db.collection('usuarios').doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ message: 'Dados do usuário não encontrados no Firestore.' });
    }
    
    // Extraímos os dados do documento
    const userData = userDoc.data();

    // Retornamos os dados completos do usuário, incluindo o 'role'
    res.status(200).json({
      message: `Usuário ${email} autenticado com sucesso.`,
      user: {
        uid: uid,
        email: email,
        name: userData?.name,
        role: userData?.role, // A informação crucial que precisamos!
      },
    });
  } catch (error) {
    console.error('Erro ao buscar dados do usuário:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar perfil do usuário.' });
  }
});

export default authRouter;