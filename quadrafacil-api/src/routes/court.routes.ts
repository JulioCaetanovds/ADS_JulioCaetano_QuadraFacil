import { Router } from 'express';
import {
  createCourt,
  getCourtsByOwner,
  getCourtById,
  updateCourt,
  deleteCourt,
  setCourtAvailability,
  getCourtAvailability,
  getAllPublicCourts // Importa a nova função
} from '../controllers/court.controller';
import { isAuthenticated } from '../middleware/auth.middleware';

const courtRouter = Router();

// --- Rotas para /courts ---

// Rota POST para criar (protegida)
courtRouter.post('/', isAuthenticated, createCourt);

// Rota GET para listar quadras DO DONO LOGADO (protegida)
courtRouter.get('/', isAuthenticated, getCourtsByOwner);

// --- NOVA ROTA PÚBLICA ---
// Rota GET para listar TODAS as quadras (pública - SEM isAuthenticated)
// Deve vir ANTES de /:courtId para não ser confundida
courtRouter.get('/public', getAllPublicCourts);
// -------------------------

// Rota GET para buscar UMA quadra específica (protegida por dono no controller)
courtRouter.get('/:courtId', isAuthenticated, getCourtById);

// Rota PUT para ATUALIZAR uma quadra (protegida)
courtRouter.put('/:courtId', isAuthenticated, updateCourt);

// Rota DELETE para EXCLUIR uma quadra (protegida)
courtRouter.delete('/:courtId', isAuthenticated, deleteCourt);

// --- Rotas de Disponibilidade ---
courtRouter.put('/:courtId/availability', isAuthenticated, setCourtAvailability);
courtRouter.get('/:courtId/availability', getCourtAvailability); // Pública

export default courtRouter;