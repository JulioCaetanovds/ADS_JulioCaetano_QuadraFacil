import { Router } from 'express';
// Importa ambas as funções do controller
import { getBookingsByOwner, createBooking } from '../controllers/booking.controller';
import { isAuthenticated } from '../middleware/auth.middleware'; // Nosso "porteiro"

const bookingRouter = Router();

// --- Rotas para /bookings ---

// Rota GET para buscar as reservas do Dono logado
bookingRouter.get('/owner', isAuthenticated, getBookingsByOwner);

// Rota POST para CRIAR uma nova reserva (requer atleta logado)
bookingRouter.post('/', isAuthenticated, createBooking);


// --- Outras rotas (buscar reserva por ID, cancelar, etc.) virão aqui ---

export default bookingRouter;