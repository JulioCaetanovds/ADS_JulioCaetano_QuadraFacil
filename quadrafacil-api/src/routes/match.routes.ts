import { Router } from 'express';
// 1. Importa a nova função
import { openMatch, getPublicMatches, getMatchDetails } from '../controllers/match.controller';
import { isAuthenticated } from '../middleware/auth.middleware';

const matchRouter = Router();

// --- Rotas para /matches ---

// GET /matches/public : Lista todas as partidas abertas (RF05, RF09)
matchRouter.get('/public', getPublicMatches);

// POST /matches/open : Transforma uma reserva em uma partida aberta (RF08)
matchRouter.post('/open', isAuthenticated, openMatch);

// --- NOVA ROTA ---
// GET /matches/:matchId : Busca os detalhes de UMA partida específica
matchRouter.get('/:matchId', getMatchDetails); // Não requer auth, é tela pública

// TODO: Adicionar rota para atleta 'entrar' na partida (POST /matches/:matchId/join)
// TODO: Adicionar rota para atleta 'sair' da partida (DELETE /matches/:matchId/leave)

export default matchRouter;