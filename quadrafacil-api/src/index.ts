// src/index.ts
import express, { Request, Response } from 'express';
import cors from 'cors'; // Import do cors
import { db } from './config/firebase';
import authRouter from './routes/auth.routes';
import courtRouter from './routes/court.routes';

const app = express();
const PORT = 3000;

// Habilita o CORS para todas as origens (deve vir antes das rotas!)
app.use(cors()); 
// --------------------

// Habilita o Express para entender JSON
app.use(express.json());

// Rota principal
app.get('/', (req: Request, res: Response) => {
  res.status(200).json({ message: 'Bem vindo à API do Quadra Fácil!' });
});

// Nossas rotas
app.use('/auth', authRouter);
app.use('/courts', courtRouter);

// Inicia o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT} 🚀`);
});