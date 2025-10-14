// src/middleware/auth.middleware.ts

import { Request, Response, NextFunction } from 'express';
import admin from 'firebase-admin';

// Adicionamos uma propriedade 'currentUser' à interface de Request do Express
// Isso nos permite anexar os dados do usuário autenticado à requisição
declare global {
  namespace Express {
    interface Request {
      currentUser?: admin.auth.DecodedIdToken;
    }
  }
}

export const isAuthenticated = async (req: Request, res: Response, next: NextFunction) => {
  // 1. Pega o token do cabeçalho 'Authorization'
  const { authorization } = req.headers;

  if (!authorization || !authorization.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Não autorizado: Token não fornecido ou em formato inválido.' });
  }

  // O token vem no formato "Bearer <token>", então pegamos só a segunda parte
  const idToken = authorization.split('Bearer ')[1];

  try {
    // 2. Usa o Firebase Admin para verificar se o token é válido
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // 3. Anexa os dados do usuário à requisição para uso futuro
    req.currentUser = decodedToken;
    
    // 4. Chama a próxima função na cadeia (o controller da rota)
    return next();
  } catch (error) {
    console.error('Erro ao verificar token:', error);
    return res.status(401).json({ message: 'Não autorizado: Token inválido ou expirado.' });
  }
};