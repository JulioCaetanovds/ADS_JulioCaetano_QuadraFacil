import { Router } from 'express';
import { 
  getUserChats, 
  sendMessage, 
  getOrCreateBookingChat,
  getOrCreateMatchChat,
  getChatMessages // 1. Função para buscar o histórico
} from '../controllers/chat.controller';
import { isAuthenticated } from '../middleware/auth.middleware';

const chatRouter = Router();

// --- Rotas para /chats ---

// GET /chats : Lista todas as conversas do usuário (protegida)
chatRouter.get('/', isAuthenticated, getUserChats);

// POST /chats/match/:matchId : Cria ou retorna o ID do chat de grupo da partida (RF11)
chatRouter.post('/match/:matchId', isAuthenticated, getOrCreateMatchChat);

// --- ROTAS DE MENSAGENS (RF11) ---
chatRouter.post('/booking/:bookingId', isAuthenticated, getOrCreateBookingChat);

// GET /chats/:chatId/messages : Busca o histórico de mensagens de um chat
chatRouter.get('/:chatId/messages', isAuthenticated, getChatMessages); // 2. NOVA ROTA

// POST /chats/:chatId/messages : Envia uma nova mensagem
chatRouter.post('/:chatId/messages', isAuthenticated, sendMessage);

// TODO: Adicionar rota para iniciar nova conversa 1:1

export default chatRouter;