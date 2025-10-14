// src/index.ts
import express, { Request, Response } from 'express';
import { db } from './config/firebase'; // Verificando que a conexão está importada
import authRouter from './routes/auth.routes'; // 1. Importamos nossas novas rotas

const app = express();
const PORT = 3000;

app.use(express.json());

// A rota principal continua funcionando
app.get('/', (req: Request, res: Response) => {
  res.status(200).json({ message: 'Bem-vindo à API do Quadra Fácil!' });
});

// 2. Dizemos ao Express para usar nosso roteador de autenticação
// Todas as rotas dentro de authRouter terão o prefixo '/auth'
app.use('/auth', authRouter);

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT} 🚀`);
});