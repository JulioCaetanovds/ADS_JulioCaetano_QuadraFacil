// src/routes/court.routes.ts

import { Router } from 'express';
import { createCourt, getCourtsByOwner, getCourtById } from '../controllers/court.controller';
import { isAuthenticated } from '../middleware/auth.middleware'; // Nosso "porteiro"

const courtRouter = Router();

// --- Rotas para /courts ---

// Rota POST para criar uma nova quadra.
// O middleware 'isAuthenticated' garante que só um usuário logado pode acessar.
courtRouter.post('/', isAuthenticated, createCourt);

// Rota GET para listar as quadras do usuário logado.
courtRouter.get('/', isAuthenticated, getCourtsByOwner);

// Nova rota GET para buscar uma quadra específica pelo ID
// O ':courtId' é um parâmetro dinâmico na URL
courtRouter.get('/:courtId', isAuthenticated, getCourtById);

export default courtRouter;