// src/routes/court.routes.ts

import { Router } from 'express';
import { createCourt, getCourtsByOwner, getCourtById, updateCourt, deleteCourt, setCourtAvailability, getCourtAvailability } from '../controllers/court.controller';
import { isAuthenticated } from '../middleware/auth.middleware'; // Nosso "porteiro"

const courtRouter = Router();

// --- Rotas para /courts ---
courtRouter.post('/', isAuthenticated, createCourt);
courtRouter.get('/', isAuthenticated, getCourtsByOwner);
courtRouter.get('/:courtId', isAuthenticated, getCourtById);
courtRouter.put('/:courtId', isAuthenticated, updateCourt);
courtRouter.delete('/:courtId', isAuthenticated, deleteCourt);

// --- Rotas específicas para Disponibilidade ---
// PUT para definir/atualizar a disponibilidade (requer autenticação de dono)
courtRouter.put('/:courtId/availability', isAuthenticated, setCourtAvailability); 
// GET para buscar a disponibilidade (pode ser pública ou requerer autenticação simples)
courtRouter.get('/:courtId/availability', getCourtAvailability);

export default courtRouter;