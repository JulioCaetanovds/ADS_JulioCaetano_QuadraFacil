import { Router } from 'express';
// 1. Importa a nova função 'leaveMatch'
import {
  openMatch,
  getPublicMatches,
  getMatchDetails,
  joinMatch,
  leaveMatch 
} from '../controllers/match.controller';
import { isAuthenticated } from '../middleware/auth.middleware';

const matchRouter = Router();

// --- Rotas para /matches ---

// GET /matches/public : Lista todas as partidas abertas (RF05, RF09)
matchRouter.get('/public', getPublicMatches);

// POST /matches/open : Transforma uma reserva em uma partida aberta (RF08)
matchRouter.post('/open', isAuthenticated, openMatch);

// GET /matches/:matchId : Busca os detalhes de UMA partida específica
matchRouter.get('/:matchId', getMatchDetails);

// POST /matches/:matchId/join : Atleta entra em uma partida (RF09)
matchRouter.post('/:matchId/join', isAuthenticated, joinMatch);

// --- NOVA ROTA (RF09 - Sair) ---
// DELETE /matches/:matchId/leave : Atleta sai de uma partida (requer autenticação)
matchRouter.delete('/:matchId/leave', isAuthenticated, leaveMatch);


export default matchRouter;