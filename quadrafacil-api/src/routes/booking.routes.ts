// src/routes/booking.routes.ts

import { Router } from 'express';
// Importa todas as funções do controller
import {
  createBooking,
  getBookingsByOwner,
  getBookingsByAthlete,
  cancelBooking, // 1. Importa a nova função de cancelamento
} from '../controllers/booking.controller';
import { isAuthenticated } from '../middleware/auth.middleware'; // Nosso "porteiro"

const bookingRouter = Router();

// --- Rotas para /bookings ---

// POST / : Cria uma nova reserva (requer autenticação de atleta)
bookingRouter.post('/', isAuthenticated, createBooking);

// GET /owner : Lista as reservas das quadras de um dono (requer autenticação de dono)
bookingRouter.get('/owner', isAuthenticated, getBookingsByOwner);

// GET /athlete : Lista as reservas feitas por um atleta (requer autenticação de atleta)
bookingRouter.get('/athlete', isAuthenticated, getBookingsByAthlete);

// DELETE /:bookingId : Atleta cancela uma reserva (requer autenticação de atleta)
bookingRouter.delete('/:bookingId', isAuthenticated, cancelBooking); // 2. Adiciona a nova rota DELETE

// TODO: Adicionar rotas para buscar uma reserva específica (GET /:bookingId)
//       ou confirmar pagamento (PUT /:bookingId/confirm) etc.

export default bookingRouter;