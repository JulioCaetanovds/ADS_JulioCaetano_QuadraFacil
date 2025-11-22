import { Router } from 'express';
import { getUserChats, sendMessage, getOrCreateMatchChat } from '../controllers/chat.controller';
import { isAuthenticated } from '../middleware/auth.middleware';

const chatRouter = Router();

// --- Rotas para /chats ---

// GET /chats : Lista todas as conversas do usuário (protegida)
chatRouter.get('/', isAuthenticated, getUserChats);

// --- NOVA ROTA PARA CHAT DE GRUPO ---
// POST /chats/match/:matchId : Cria ou retorna o ID do chat de grupo da partida (protegida)
chatRouter.post('/match/:matchId', isAuthenticated, getOrCreateMatchChat);

// POST /chats/:chatId/messages : Envia uma nova mensagem (protegida)
chatRouter.post('/:chatId/messages', isAuthenticated, sendMessage);

// TODO: Adicionar rota para buscar histórico de mensagens
// TODO: Adicionar rota para iniciar nova conversa 1:1
// TODO: Adicionar rota para buscar histórico de mensagens

export default chatRouter;