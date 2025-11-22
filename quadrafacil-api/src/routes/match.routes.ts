import { Router } from 'express';
import {
  openMatch,
  getPublicMatches,
  getMatchDetails,
  joinMatch,
  leaveMatch,
  approveRequest, // Nova função
  rejectRequest   // Nova função
} from '../controllers/match.controller';
import { isAuthenticated } from '../middleware/auth.middleware';

const matchRouter = Router();

// GET /matches/public : Lista todas as partidas abertas
matchRouter.get('/public', getPublicMatches);

// POST /matches/open : Transforma uma reserva em uma partida aberta
matchRouter.post('/open', isAuthenticated, openMatch);

// GET /matches/:matchId : Busca os detalhes de UMA partida específica
matchRouter.get('/:matchId', getMatchDetails);

// POST /matches/:matchId/join : Atleta SOLICITA entrada (vai para pendentes)
matchRouter.post('/:matchId/join', isAuthenticated, joinMatch);

// DELETE /matches/:matchId/leave : Atleta sai de uma partida
matchRouter.delete('/:matchId/leave', isAuthenticated, leaveMatch);

// --- NOVAS ROTAS DE APROVAÇÃO (Organizador) ---

// POST /matches/:matchId/approve : Aprova um participante pendente
matchRouter.post('/:matchId/approve', isAuthenticated, approveRequest);

// POST /matches/:matchId/reject : Recusa um participante pendente
matchRouter.post('/:matchId/reject', isAuthenticated, rejectRequest);

export default matchRouter;