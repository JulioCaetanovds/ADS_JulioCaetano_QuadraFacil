import { Router } from 'express';
// Importa todas as funções do controller
import {
  createBooking,
  getBookingsByOwner,
  getBookingsByAthlete,
  cancelBooking, // Do atleta
  confirmBooking, // Do dono
  rejectBooking, // Do dono
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
bookingRouter.delete('/:bookingId', isAuthenticated, cancelBooking);

// --- NOVAS ROTAS DO DONO ---

// PUT /:bookingId/confirm : Dono confirma uma reserva (requer autenticação de dono)
bookingRouter.put('/:bookingId/confirm', isAuthenticated, confirmBooking);

// PUT /:bookingId/reject : Dono recusa/cancela uma reserva (requer autenticação de dono)
bookingRouter.put('/:bookingId/reject', isAuthenticated, rejectBooking);


export default bookingRouter;