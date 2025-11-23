// src/controllers/booking.controller.ts

import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase'; // Nossa conexão com o Firestore

// --- FUNÇÃO HELPER (AUXILIAR) ---
// (Sem alterações)
const getDayKeyFromDate = (date: Date): string => {
  const dayIndex = date.getUTCDay();
  switch (dayIndex) {
    case 0: return 'domingo';
    case 1: return 'segunda';
    case 2: return 'terca';
    case 3: return 'quarta';
    case 4: return 'quinta';
    case 5: return 'sexta';
    case 6: return 'sabado';
    default: return 'segunda';
  }
};

// --- Função para CRIAR uma nova reserva ---
// (Sem alterações)
export const createBooking = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid;
    const { courtId, startTime, endTime, priceTotal } = req.body; 
    
    if (!courtId || !startTime || !endTime) {
      return res.status(400).json({ message: 'courtId, startTime e endTime são obrigatórios.' });
    }

    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();
    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }
    const courtData = courtDoc.data();
    if (!courtData) {
      return res.status(404).json({ message: 'Dados da quadra não encontrados.' });
    }
    
    const ownerId = courtData.ownerId;
    const startTimeDate = new Date(startTime);
    const dayKey = getDayKeyFromDate(startTimeDate);

    let calculatedPrice = 0.0;
    if (courtData.availability && courtData.availability[dayKey] && courtData.availability[dayKey].pricePerHour != null) {
      calculatedPrice = courtData.availability[dayKey].pricePerHour;
    } else {
      console.warn(`Preço não encontrado para ${dayKey} na quadra ${courtId}. Usando fallback 0.`);
      calculatedPrice = priceTotal ?? 0.0; 
    }

    const newBookingRef = await db.collection('reservas').add({
      courtId,
      userId,
      ownerId,
      startTime: admin.firestore.Timestamp.fromDate(startTimeDate),
      endTime: admin.firestore.Timestamp.fromDate(new Date(endTime)),
      priceTotal: calculatedPrice,
      status: 'pendente',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
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


// --- Função para LISTAR as reservas de um DONO ---
// (Sem alterações)
export const getBookingsByOwner = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    if (!ownerId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    const bookingsSnapshot = await db.collection('reservas')
                                      .where('ownerId', '==', ownerId)
                                      .get();

    const bookingPromises = bookingsSnapshot.docs.map(async (doc) => {
      const bookingData = doc.data();
      if (!bookingData) return null; 

      const courtId = bookingData.courtId;
      const userId = bookingData.userId;
      let courtName = 'Quadra N/D';
      let userName = 'Atleta N/D';

      try {
        const courtDoc = await db.collection('quadras').doc(courtId).get();
        if (courtDoc.exists) {
          courtName = courtDoc.data()?.nome ?? courtName;
        }
        const userRecord = await admin.auth().getUser(userId);
        userName = userRecord.displayName ?? userRecord.email ?? userName;
      } catch (e) {
        console.error(`Erro ao buscar dados extras para reserva ${doc.id}:`, e);
      }

      return {
        id: doc.id,
        ...bookingData,
        quadraNome: courtName,
        userName: userName,
      };
    });

    const bookingsList = (await Promise.all(bookingPromises)).filter(b => b !== null);
    return res.status(200).json(bookingsList);

  } catch (error) {
    console.error('Erro ao buscar reservas do dono:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar reservas.' });
  }
};

export const getBookingsByAthlete = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid;
    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    // --- Query 1: Reservas que EU ORGANIZEI ---
    const bookingsSnapshot = await db.collection('reservas')
                                      .where('userId', '==', userId)
                                      .get();

    const bookingPromises = bookingsSnapshot.docs.map(async (doc) => {
      const bookingData = doc.data();
      if (!bookingData) return null; 

      const courtId = bookingData.courtId;
      let quadraNome = 'Quadra N/D';
      let quadraEndereco = 'Endereço N/D';

      try {
        const courtDoc = await db.collection('quadras').doc(courtId).get();
        if (courtDoc.exists) {
          quadraNome = courtDoc.data()?.nome ?? quadraNome;
          quadraEndereco = courtDoc.data()?.endereco ?? quadraEndereco;
        }
      } catch (e) {
        console.error(`Erro ao buscar dados da quadra ${courtId} para reserva ${doc.id}:`, e);
      }

      return {
        id: doc.id,
        ...bookingData,
        quadraNome: quadraNome,
        quadraEndereco: quadraEndereco,
        type: 'booking', // Tipo para o front-end
      };
    });

    // --- Query 2: Partidas que EU ENTREI ---
    const matchesSnapshot = await db.collection('partidasAbertas')
                                      .where('participantesIds', 'array-contains', userId)
                                      .orderBy('startTime', 'asc') // Ordena por data
                                      .get();

    const matchPromises = matchesSnapshot.docs.map(async (doc) => {
      const matchData = doc.data();
      if (!matchData) return null;
      
      // Evita duplicidade: Se o atleta for o organizador, a Query 1 já pegou
      if (matchData.organizadorId === userId) {
        return null;
      }

      const courtId = matchData.quadraId;
      let quadraNome = 'Quadra N/D';
      let quadraEndereco = 'Endereço N/D';

      try {
        const courtDoc = await db.collection('quadras').doc(courtId).get();
        if (courtDoc.exists) {
          quadraNome = courtDoc.data()?.nome ?? quadraNome;
          quadraEndereco = courtDoc.data()?.endereco ?? quadraEndereco;
        }
      } catch (e) {
        console.error(`Erro ao buscar dados da quadra ${courtId} para partida ${doc.id}:`, e);
      }

      return {
        id: doc.id,
        ...matchData,
        quadraNome: quadraNome,
        quadraEndereco: quadraEndereco,
        type: 'match', // Tipo para o front-end
      };
    });

    // --- Combinar Resultados ---
    const bookingsList = (await Promise.all(bookingPromises)).filter(b => b !== null);
    const matchesList = (await Promise.all(matchPromises)).filter(m => m !== null);
    
    const combinedList = [...bookingsList, ...matchesList];

    // --- CORREÇÃO AQUI ---
    // Usamos '(a as any)' para informar ao TypeScript que o campo 'startTime' existe
    combinedList.sort((a, b) => ((b as any).startTime.toMillis() - (a as any).startTime.toMillis()));
    // ---------------------

    return res.status(200).json(combinedList);

  } catch (error: any) {
    if (error.code === 'FAILED_PRECONDITION') {
       console.error('ERRO DE ÍNDICE DO FIRESTORE:', error.message);
       // Este é o erro que VAI acontecer se o índice não for criado
       return res.status(500).json({ 
         message: 'Erro no banco de dados: A consulta requer um índice. Verifique o console do Firebase.',
         details: error.message
       });
    }
    console.error('Erro ao buscar calendário do atleta:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar calendário do atleta.' });
  }
};


export const cancelBooking = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid; 
    const { bookingId } = req.params; 

    if (!userId) return res.status(403).json({ message: 'Acesso negado.' });
    if (!bookingId) return res.status(400).json({ message: 'ID da reserva é obrigatório.' });

    const bookingRef = db.collection('reservas').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) return res.status(404).json({ message: 'Reserva não encontrada.' });

    const bookingData = bookingDoc.data()!;

    if (bookingData.userId !== userId) {
      return res.status(403).json({ message: 'Você não tem permissão para cancelar esta reserva.' });
    }

    if (bookingData.status === 'cancelada' || bookingData.status === 'finalizada') {
      return res.status(400).json({ message: 'Esta reserva não pode mais ser cancelada.' });
    }

    // Regras de Horário (Mantidas do seu código original)
    const startTime = bookingData.startTime.toDate();
    const now = new Date();
    if (startTime < now) {
      return res.status(400).json({ message: 'Não é possível cancelar uma reserva que já ocorreu.' });
    }
    const startOfBookingDayUtc = new Date(Date.UTC(startTime.getUTCFullYear(), startTime.getUTCMonth(), startTime.getUTCDate()));
    const startOfTodayUtc = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
    
    if (startOfBookingDayUtc.getTime() === startOfTodayUtc.getTime()) {
      return res.status(400).json({ message: 'Não é possível cancelar uma reserva no mesmo dia do jogo.' });
    }

    // 1. Atualiza a Reserva
    await bookingRef.update({
      status: 'cancelada',
      updatedAt: admin.firestore.FieldValue.serverTimestamp() 
    });

    // --- CORREÇÃO AQUI: Cancelar também a Partida Aberta vinculada ---
    const matchesSnapshot = await db.collection('partidasAbertas')
        .where('reservaId', '==', bookingId) // Procura partidas ligadas a esta reserva
        .get();

    if (!matchesSnapshot.empty) {
        const batch = db.batch();
        matchesSnapshot.docs.forEach(doc => {
            batch.update(doc.ref, { status: 'cancelada' });
        });
        await batch.commit();
        console.log('Partida pública vinculada foi cancelada automaticamente.');
    }
    // ----------------------------------------------------------------

    return res.status(200).json({ message: 'Reserva cancelada com sucesso.' });

  } catch (error) {
    console.error('Erro ao cancelar reserva:', error);
    return res.status(500).json({ message: 'Erro interno ao cancelar reserva.' });
  }
};

// --- Função para DONO CONFIRMAR uma reserva ---
// (Sem alterações)
export const confirmBooking = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { bookingId } = req.params;

    if (!ownerId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    const bookingRef = db.collection('reservas').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      return res.status(404).json({ message: 'Reserva não encontrada.' });
    }
    const bookingData = bookingDoc.data();
    if (!bookingData) {
      return res.status(404).json({ message: 'Dados da reserva não encontrados.' });
    }

    if (bookingData.ownerId !== ownerId) {
      return res.status(403).json({ message: 'Você não tem permissão para alterar esta reserva.' });
    }

    await bookingRef.update({
      status: 'confirmada',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return res.status(200).json({ message: 'Reserva confirmada com sucesso.' });

  } catch (error) {
    console.error('Erro ao confirmar reserva:', error);
    return res.status(500).json({ message: 'Erro interno ao confirmar reserva.' });
  }
};

export const rejectBooking = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { bookingId } = req.params;

    if (!ownerId) return res.status(403).json({ message: 'Acesso negado.' });

    const bookingRef = db.collection('reservas').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) return res.status(404).json({ message: 'Reserva não encontrada.' });
    
    const bookingData = bookingDoc.data()!;

    if (bookingData.ownerId !== ownerId) {
      return res.status(403).json({ message: 'Você não tem permissão para alterar esta reserva.' });
    }

    // 1. Atualiza a Reserva
    await bookingRef.update({
      status: 'cancelada', 
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // --- CORREÇÃO AQUI: Cancelar também a Partida Aberta vinculada ---
    const matchesSnapshot = await db.collection('partidasAbertas')
        .where('reservaId', '==', bookingId)
        .get();

    if (!matchesSnapshot.empty) {
        const batch = db.batch();
        matchesSnapshot.docs.forEach(doc => {
            batch.update(doc.ref, { status: 'cancelada' });
        });
        await batch.commit();
        console.log('Partida pública vinculada foi cancelada pelo dono.');
    }
    // ----------------------------------------------------------------

    return res.status(200).json({ message: 'Reserva recusada/cancelada com sucesso.' });

  } catch (error) {
    console.error('Erro ao recusar reserva:', error);
    return res.status(500).json({ message: 'Erro interno ao recusar reserva.' });
  }
};