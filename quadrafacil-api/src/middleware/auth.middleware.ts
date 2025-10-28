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
  const idToken = authorization.split('Bearer ')[1].trim();

  console.log('--- TOKEN RECEBIDO PELA API ---');
  console.log(`Comprimento na API: ${idToken.length}`);
  console.log(idToken);
  console.log('--- FIM DO TOKEN RECEBIDO ---');

  try {
    // 2. Usa o Firebase Admin para verificar se o token é válido
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // 3. Anexa os dados do usuário à requisição para uso futuro
    req.currentUser = decodedToken;
    
    // 4. Chama a próxima função na cadeia (o controller da rota)
    return next();
  } catch (error: any) { // Usamos 'any' para poder inspecionar o objeto de erro
    // Logs detalhados em caso de falha na verificação
    console.error('--- ERRO DETALHADO AO VERIFICAR TOKEN ---'); 
    console.error(error); // Loga o objeto de erro completo
    if (error.code) { // Verifica se é um erro específico do Firebase com código
      console.error('Código do erro Firebase:', error.code); 
    }
    console.error('-----------------------------------------'); 
    return res.status(401).json({ message: 'Não autorizado: Token inválido ou expirado.' });
  }
};