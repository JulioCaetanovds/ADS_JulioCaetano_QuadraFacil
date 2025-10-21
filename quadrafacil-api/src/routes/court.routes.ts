// src/routes/court.routes.ts

import { Router } from 'express';
import { createCourt, getCourtsByOwner, getCourtById, updateCourt, deleteCourt } from '../controllers/court.controller';
import { isAuthenticated } from '../middleware/auth.middleware'; // Nosso "porteiro"

const courtRouter = Router();

// ... (rotas POST '/' e GET '/')

// Rota POST para criar uma nova quadra.
// O middleware 'isAuthenticated' garante que só um usuário logado pode acessar.
courtRouter.post('/', isAuthenticated, createCourt);

// Rota GET para listar as quadras do usuário logado.
courtRouter.get('/', isAuthenticated, getCourtsByOwner);

// Nova rota GET para buscar uma quadra específica pelo ID
// O ':courtId' é um parâmetro dinâmico na URL
courtRouter.get('/:courtId', isAuthenticated, getCourtById);

// 2. Nova rota PUT para ATUALIZAR uma quadra
courtRouter.put('/:courtId', isAuthenticated, updateCourt);

// 2. Nova rota DELETE para EXCLUIR uma quadra
courtRouter.delete('/:courtId', isAuthenticated, deleteCourt);

export default courtRouter;