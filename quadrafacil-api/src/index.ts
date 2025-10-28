import express, { Request, Response } from 'express';
import cors from 'cors';
import { db } from './config/firebase';
import authRouter from './routes/auth.routes';
import courtRouter from './routes/court.routes';
import bookingRouter from './routes/booking.routes'; // 1. Importe o novo roteador

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req: Request, res: Response) => {
  res.status(200).json({ message: 'Bem-vindo à API do Quadra Fácil!' });
});

// Nossas rotas
app.use('/auth', authRouter);
app.use('/courts', courtRouter);
app.use('/bookings', bookingRouter); // 2. Adicione as rotas de reservas

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT} 🚀`);
});

export default app;