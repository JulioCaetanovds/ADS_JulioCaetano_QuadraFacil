// src/controllers/booking.controller.ts

import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase'; // Nossa conexão com o Firestore

// --- FUNÇÃO HELPER (AUXILIAR) ---
// Converte um objeto Date (em UTC) para a chave de dia (segunda, terca...)
// Nota: getUTCDay() no JS: 0 = Domingo, 1 = Segunda, 2 = Terça...
const getDayKeyFromDate = (date: Date): string => {
  const dayIndex = date.getUTCDay(); // Usamos UTC para consistência
  switch (dayIndex) {
    case 0: return 'domingo';
    case 1: return 'segunda';
    case 2: return 'terca';
    case 3: return 'quarta';
    case 4: return 'quinta';
    case 5: return 'sexta';
    case 6: return 'sabado';
    default: return 'segunda'; // Fallback
  }
};

// --- Função para CRIAR uma nova reserva ---
// (MODIFICADA para calcular o preço dinamicamente)
export const createBooking = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid; // ID do Atleta logado
    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado. Usuário não autenticado.' });
    }

    // Dados esperados do front-end
    // O front-end já envia o 'priceTotal' calculado no body
    const { courtId, startTime, endTime, priceTotal } = req.body; 
    
    if (!courtId || !startTime || !endTime) {
      return res.status(400).json({ message: 'courtId, startTime e endTime são obrigatórios.' });
    }

    // 1. Busca dados da quadra para pegar o ownerId
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

    // --- CORREÇÃO DO PREÇO ---
    // 2. Converte a string 'startTime' (que está em UTC) para um objeto Date
    const startTimeDate = new Date(startTime);

    // 3. Obtém a chave do dia (ex: 'sexta')
    const dayKey = getDayKeyFromDate(startTimeDate);

    // 4. Busca o preço real na disponibilidade da quadra
    let calculatedPrice = 0.0;
    if (courtData.availability && courtData.availability[dayKey] && courtData.availability[dayKey].pricePerHour != null) {
      calculatedPrice = courtData.availability[dayKey].pricePerHour;
    } else {
      // Fallback se o preço não estiver definido para aquele dia (não deveria acontecer)
      console.warn(`Preço não encontrado para ${dayKey} na quadra ${courtId}. Usando fallback 0.`);
      // Você pode definir um preço padrão ou retornar um erro
      // Por segurança, vamos usar o preço que o front-end enviou (priceTotal)
      calculatedPrice = priceTotal ?? 0.0; 
    }
    // -------------------------

    // TO-DO: Adicionar validação para checar se o horário já está ocupado

    // Criar a nova reserva no Firestore
    const newBookingRef = await db.collection('reservas').add({
      courtId,
      userId,
      ownerId, // Salva o ID do dono para facilitar a busca dele
      startTime: admin.firestore.Timestamp.fromDate(startTimeDate), // Converte a data para Timestamp
      endTime: admin.firestore.Timestamp.fromDate(new Date(endTime)),
      priceTotal: calculatedPrice, // 5. Salva o PREÇO CORRETO
      status: 'pendente', // Status inicial
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
      if (!bookingData) return null; // Pula se os dados estiverem indefinidos

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

    const bookingsList = (await Promise.all(bookingPromises)).filter(b => b !== null); // Filtra nulos
    return res.status(200).json(bookingsList);

  } catch (error) {
    console.error('Erro ao buscar reservas do dono:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar reservas.' });
  }
};

// --- Função para LISTAR as reservas de um ATLETA ---
// (Sem alterações)
export const getBookingsByAthlete = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid;
    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    const bookingsSnapshot = await db.collection('reservas')
                                      .where('userId', '==', userId)
                                      .get();

    const bookingPromises = bookingsSnapshot.docs.map(async (doc) => {
      const bookingData = doc.data();
      if (!bookingData) return null; // Pula se os dados estiverem indefinidos

      const courtId = bookingData.courtId;
      let courtName = 'Quadra N/D';
      let courtAddress = 'Endereço N/D';

      try {
        const courtDoc = await db.collection('quadras').doc(courtId).get();
        if (courtDoc.exists) {
          courtName = courtDoc.data()?.nome ?? courtName;
          courtAddress = courtDoc.data()?.endereco ?? courtAddress;
        }
      } catch (e) {
        console.error(`Erro ao buscar dados da quadra ${courtId} para reserva ${doc.id}:`, e);
      }

      return {
        id: doc.id,
        ...bookingData,
        quadraNome: courtName,
        quadraEndereco: courtAddress,
      };
    });

    const bookingsList = (await Promise.all(bookingPromises)).filter(b => b !== null); // Filtra nulos
    return res.status(200).json(bookingsList);

  } catch (error) {
    console.error('Erro ao buscar reservas do atleta:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar reservas.' });
  }
};


// --- Função para CANCELAR uma reserva (Atleta) ---
// (Sem alterações)
export const cancelBooking = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid; 
    const { bookingId } = req.params; 

    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }
    if (!bookingId) {
      return res.status(400).json({ message: 'ID da reserva é obrigatório.' });
    }

    const bookingRef = db.collection('reservas').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      return res.status(404).json({ message: 'Reserva não encontrada.' });
    }

    const bookingData = bookingDoc.data();

    if (!bookingData) {
      return res.status(404).json({ message: 'Não foi possível ler os dados da reserva.' });
    }

    if (bookingData.userId !== userId) {
      return res.status(403).json({ message: 'Você não tem permissão para cancelar esta reserva.' });
    }

    if (bookingData.status === 'cancelada' || bookingData.status === 'finalizada') {
      return res.status(400).json({ message: 'Esta reserva não pode mais ser cancelada.' });
    }

    const startTime = bookingData.startTime.toDate(); // Em UTC
    const now = new Date(); // Em UTC

    if (startTime < now) {
      return res.status(400).json({ message: 'Não é possível cancelar uma reserva que já ocorreu.' });
    }

    const startOfBookingDayUtc = new Date(Date.UTC(
      startTime.getUTCFullYear(),
      startTime.getUTCMonth(),
      startTime.getUTCDate()
    ));

    const startOfTodayUtc = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate()
    ));

    if (startOfBookingDayUtc.getTime() === startOfTodayUtc.getTime()) {
      return res.status(400).json({ message: 'Não é possível cancelar uma reserva no mesmo dia do jogo.' });
    }

    await bookingRef.update({
      status: 'cancelada',
      updatedAt: admin.firestore.FieldValue.serverTimestamp() 
    });

    return res.status(200).json({ message: 'Reserva cancelada com sucesso.' });

  } catch (error) {
    console.error('Erro ao cancelar reserva:', error);
    return res.status(500).json({ message: 'Erro interno ao cancelar reserva.' });
  }
};