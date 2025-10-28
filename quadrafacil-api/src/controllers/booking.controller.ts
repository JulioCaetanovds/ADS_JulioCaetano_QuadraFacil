import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase';

// --- Função para LISTAR as reservas de um Dono ---
export const getBookingsByOwner = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    if (!ownerId) {
      return res.status(403).json({ message: 'Acesso negado. UID do usuário não encontrado.' });
    }

    // Busca na coleção 'reservas' todos os documentos onde 'ownerId' é igual ao do usuário logado
    // OBS: Assumindo que o campo 'ownerId' será adicionado ao documento de reserva no futuro.
    const bookingsSnapshot = await db.collection('reservas')
                                     .where('ownerId', '==', ownerId)
                                     // Poderíamos ordenar por data aqui se necessário e se o índice existir
                                     // .orderBy('startTime', 'desc')
                                     .get();

    const bookingsList = bookingsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.status(200).json(bookingsList);

  } catch (error) {
    console.error('Erro ao buscar reservas do dono:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar reservas.' });
  }
};

// --- Função para CRIAR uma nova reserva (RF06) ---
export const createBooking = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid; // ID do atleta logado (vem do middleware)
    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado. Usuário não autenticado.' });
    }

    const { courtId, startTime, endTime } = req.body; // Dados enviados pelo app Flutter

    // Validação básica
    if (!courtId || !startTime || !endTime) {
      return res.status(400).json({ message: 'ID da quadra, horário de início e fim são obrigatórios.' });
    }

    // 1. Buscar dados da quadra para pegar o ownerId e o preço
    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();
    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }
    const courtData = courtDoc.data();
    const ownerId = courtData?.ownerId;
    // TO-DO: Buscar o preço correto com base no dia/hora da disponibilidade
    const pricePerHour = courtData?.availability?.segunda?.pricePerHour ?? 80.0; // Exemplo pegando preço da segunda

    // 2. Converter horários (assumindo que o front envia strings ISO 8601 ou Timestamps)
    //    É crucial definir um formato padrão entre front e back!
    //    Exemplo: Se o front envia Timestamp do JS (milissegundos):
    //    const startTimestamp = admin.firestore.Timestamp.fromMillis(startTime);
    //    const endTimestamp = admin.firestore.Timestamp.fromMillis(endTime);
    //    Se envia string ISO:
    const startTimestamp = admin.firestore.Timestamp.fromDate(new Date(startTime));
    const endTimestamp = admin.firestore.Timestamp.fromDate(new Date(endTime));

    // TO-DO: Adicionar validação de conflito de horário aqui!
    // (Verificar se já existe reserva para esta quadra neste período)

    // 3. Criar o documento da reserva
    const newBookingRef = await db.collection('reservas').add({
      courtId: courtId,
      userId: userId, // ID do atleta que reservou
      ownerId: ownerId, // ID do dono da quadra (para facilitar a busca dele)
      startTime: startTimestamp,
      endTime: endTimestamp,
      status: 'pendente', // Status inicial
      precoTotal: pricePerHour, // Calcular com base na duração se necessário
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      // Adicionar campo de pagamento futuramente (QR Code, status confirmação)
      pagamento: { qrCode: null, statusConfirmacao: 'aguardando' }
    });

    return res.status(201).json({
      message: 'Reserva criada com sucesso! Aguardando pagamento.',
      bookingId: newBookingRef.id,
    });

  } catch (error) {
    console.error('Erro ao criar reserva:', error);
    return res.status(500).json({ message: 'Erro interno ao criar reserva.' });
  }
};

