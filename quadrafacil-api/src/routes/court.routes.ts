import { Router } from 'express';
import {
  createCourt,
  getCourtsByOwner,
  getCourtById,
  updateCourt,
  deleteCourt,
  setCourtAvailability,
  getCourtAvailability,
  getAllPublicCourts,
  getPublicCourtDetails // 1. Importa a nova função (RF10)
} from '../controllers/court.controller';
import { isAuthenticated } from '../middleware/auth.middleware';

const courtRouter = Router();

// --- Rotas para /courts ---

// Rota POST para criar (protegida)
courtRouter.post('/', isAuthenticated, createCourt);

// Rota GET para listar quadras DO DONO LOGADO (protegida)
courtRouter.get('/', isAuthenticated, getCourtsByOwner);

// Rota GET para listar TODAS as quadras (pública)
courtRouter.get('/public', getAllPublicCourts);

// Rota GET para buscar UMA quadra específica (protegida por dono no controller)
courtRouter.get('/:courtId', isAuthenticated, getCourtById);

// Rota PUT para ATUALIZAR uma quadra (protegida)
courtRouter.put('/:courtId', isAuthenticated, updateCourt);

// Rota DELETE para EXCLUIR uma quadra (protegida)
courtRouter.delete('/:courtId', isAuthenticated, deleteCourt);

// --- Rotas de Disponibilidade (e Detalhes Públicos) ---

// Rota PUT para Dono definir disponibilidade (protegida)
courtRouter.put('/:courtId/availability', isAuthenticated, setCourtAvailability);

// Rota GET para Atleta buscar disponibilidade (pública)
courtRouter.get('/:courtId/availability', getCourtAvailability);

// 2. NOVA ROTA PÚBLICA (RF10)
// Rota GET para Atleta buscar detalhes públicos e PIX do Dono
courtRouter.get('/:courtId/public-details', getPublicCourtDetails);


export default courtRouter;