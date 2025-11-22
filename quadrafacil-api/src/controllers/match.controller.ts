import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase';

// POST /matches/open
export const openMatch = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid; 
    const { bookingId, vagasAbertas } = req.body;

    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }
    if (!bookingId || !vagasAbertas) {
      return res.status(400).json({ message: 'bookingId e vagasAbertas são obrigatórios.' });
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

    if (bookingData.userId !== userId) {
      return res.status(403).json({ message: 'Você não é o dono desta reserva.' });
    }
    if (bookingData.status !== 'confirmada') {
      return res.status(400).json({ message: 'Apenas reservas "confirmadas" podem ser abertas.' });
    }
    if (bookingData.partidaAbertaId) {
      return res.status(400).json({ message: 'Esta reserva já foi aberta como uma partida.' });
    }
    const startTime = bookingData.startTime.toDate();
    if (startTime < new Date()) {
      return res.status(400).json({ message: 'Não é possível abrir uma partida para uma reserva que já ocorreu.' });
    }

    const newMatchData = {
      reservaId: bookingId,
      organizadorId: userId,
      quadraId: bookingData.courtId, // Correção que fizemos
      startTime: bookingData.startTime, 
      endTime: bookingData.endTime,     
      vagasDisponiveis: Number(vagasAbertas),
      participantesIds: [userId], 
      status: 'aberta',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const newMatchRef = await db.collection('partidasAbertas').add(newMatchData);

    await bookingRef.update({
      partidaAbertaId: newMatchRef.id
    });

    return res.status(201).json({
      message: 'Partida aberta com sucesso!',
      matchId: newMatchRef.id,
      data: newMatchData
    });

  } catch (error) {
    console.error('Erro ao abrir partida:', error);
    return res.status(500).json({ message: 'Erro interno ao abrir partida.' });
  }
};

// GET /matches/public
export const getPublicMatches = async (req: Request, res: Response) => {
  try {
    const now = admin.firestore.Timestamp.now();

    // 1. Busca partidas que estão explicitamente 'aberta' e que ainda não aconteceram
    const matchesSnapshot = await db.collection('partidasAbertas')
      .where('status', '==', 'aberta') // <-- Garante que não apareçam partidas canceladas ou fechadas
      .where('startTime', '>', now)
      .orderBy('startTime', 'asc')
      .get();

    if (matchesSnapshot.empty) {
      return res.status(200).json([]);
    }

    // 2. Mapeamento assíncrono para "enriquecer" os dados
    const matchesPromises = matchesSnapshot.docs.map(async (doc) => {
      const matchData = doc.data();
      const quadraId = matchData.quadraId;

      let quadraNome = 'Quadra N/D';
      let quadraEndereco = 'Endereço N/D';
      let esporte = 'Esporte N/D';

      try {
        const courtDoc = await db.collection('quadras').doc(quadraId).get();
        if (courtDoc.exists) {
          quadraNome = courtDoc.data()?.nome ?? quadraNome;
          quadraEndereco = courtDoc.data()?.endereco ?? quadraEndereco;
          esporte = courtDoc.data()?.esporte ?? esporte;
        }
      } catch (e) {
        console.error(`Erro ao buscar dados da quadra ${quadraId} para partida ${doc.id}:`, e);
      }

      // 4. Retorna o objeto combinado
      return {
        id: doc.id,
        ...matchData,
        quadraNome: quadraNome,
        quadraEndereco: quadraEndereco,
        esporte: esporte,
      };
    });

    const enrichedMatchesList = await Promise.all(matchesPromises);

    return res.status(200).json(enrichedMatchesList);

  } catch (error) {
    console.error('Erro ao buscar partidas públicas:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar partidas.' });
  }
};

// GET /matches/:matchId
export const getMatchDetails = async (req: Request, res: Response) => {
  try {
    const { matchId } = req.params;
    if (!matchId) {
      return res.status(400).json({ message: 'ID da partida é obrigatório.' });
    }

    const matchRef = db.collection('partidasAbertas').doc(matchId);
    const matchDoc = await matchRef.get();

    if (!matchDoc.exists) {
      return res.status(404).json({ message: 'Partida não encontrada.' });
    }

    const matchData = matchDoc.data()!;
    const quadraId = matchData.quadraId;
    const organizadorId = matchData.organizadorId;
    const participantesIds: string[] = matchData.participantesIds || [];
    const participantesPendentesIds: string[] = matchData.participantesPendentes || []; // [!code focus]

    let quadraData = {};
    let organizadorData: { nome: string; fotoUrl: string | null } = {
      nome: 'Organizador N/D',
      fotoUrl: null
    };

    try {
      const courtDoc = await db.collection('quadras').doc(quadraId).get();
      if (courtDoc.exists) {
        quadraData = courtDoc.data() ?? {};
      }
    } catch (e) { console.error("Erro ao buscar quadra:", e); }

    try {
      const userRecord = await admin.auth().getUser(organizadorId);
      organizadorData = {
        nome: userRecord.displayName ?? userRecord.email ?? 'Organizador',
        fotoUrl: userRecord.photoURL ?? null
      };
    } catch (e) { console.error("Erro ao buscar organizador:", e); }

    const fetchUsersData = async (ids: string[]) => {
      return Promise.all(ids.map(async (id) => {
        try {
          if (id === organizadorId) {
            return { id, ...organizadorData };
          }
          const userRecord = await admin.auth().getUser(id);
          return {
            id: id,
            nome: userRecord.displayName ?? userRecord.email ?? 'Usuário',
            fotoUrl: userRecord.photoURL ?? null
          };
        } catch (e) {
          return { id: id, nome: 'Usuário Desconhecido', fotoUrl: null };
        }
      }));
    };

    const participantesData = await fetchUsersData(participantesIds);
    const pendentesData = await fetchUsersData(participantesPendentesIds); // [!code focus]

    // ----------------------------------------------------
    // ** DEBUG 1: VERIFICAÇÃO DE DADOS CRÍTICOS **
    // ----------------------------------------------------
    console.log("--- DEBUG 1: API BACKEND START ---");
    console.log("Organizador ID:", organizadorId);
    console.log("Qtd. Participantes Confirmados:", participantesData.length);
    console.log("Qtd. Solicitantes Pendentes:", pendentesData.length); // [!code focus]
    console.log("Dados dos Pendentes:", pendentesData.map(p => p.nome)); // [!code focus]
    console.log("--- DEBUG 1: API BACKEND END ---");
    // ----------------------------------------------------

    const responseData = {
      id: matchDoc.id,
      ...matchData,
      quadraData: quadraData,
      organizadorData: organizadorData,
      participantesData: participantesData,
      pendentesData: pendentesData,
    };

    return res.status(200).json(responseData);

  } catch (error) {
    console.error('Erro ao buscar detalhes da partida:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar detalhes.' });
  }
};

// --- UPDATED FUNCTION (RF09) ---
// POST /matches/:matchId/join
// Now adds to 'participantesPendentes' instead of 'participantesIds'
export const joinMatch = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid;
    const { matchId } = req.params;

    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    const matchRef = db.collection('partidasAbertas').doc(matchId);

    await db.runTransaction(async (transaction) => {
      const matchDoc = await transaction.get(matchRef);

      if (!matchDoc.exists) {
        throw new Error('Partida não encontrada.');
      }

      const matchData = matchDoc.data()!;

      // --- Business Rules ---
      if (matchData.status !== 'aberta') {
        throw new Error('Esta partida não está mais aberta a novos participantes.');
      }
      if (matchData.vagasDisponiveis <= 0) {
        throw new Error('Não há mais vagas disponíveis para esta partida.');
      }
      if (matchData.participantesIds.includes(userId)) {
        throw new Error('Você já está participando desta partida.');
      }
      // Check if already pending
      if (matchData.participantesPendentes && matchData.participantesPendentes.includes(userId)) {
        throw new Error('Sua solicitação já está pendente.');
      }
      if (matchData.startTime.toDate() < new Date()) {
        throw new Error('Esta partida já ocorreu.');
      }

      // --- Update Data ---
      // Add to pending list, NOT confirmed list
      transaction.update(matchRef, {
        participantesPendentes: admin.firestore.FieldValue.arrayUnion(userId)
      });
    });

    return res.status(200).json({ message: 'Solicitação enviada! Aguarde a aprovação do organizador.' });

  } catch (error: any) {
    console.error('Erro ao solicitar entrada na partida:', error);
    return res.status(400).json({ message: error.message || 'Erro interno ao solicitar entrada.' });
  }
};

export const leaveMatch = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid; // ID do atleta que quer sair
    const { matchId } = req.params;

    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    const matchRef = db.collection('partidasAbertas').doc(matchId);

    // Usa uma transação para garantir a consistência dos dados
    await db.runTransaction(async (transaction) => {
      const matchDoc = await transaction.get(matchRef);

      if (!matchDoc.exists) {
        throw new Error('Partida não encontrada.');
      }

      const matchData = matchDoc.data()!;

      // --- Regras de Negócio ---
      if (matchData.startTime.toDate() < new Date()) {
        throw new Error('Esta partida já ocorreu.');
      }
      if (!matchData.participantesIds.includes(userId)) {
        throw new Error('Você não está participando desta partida.');
      }
      if (matchData.organizadorId === userId) {
        throw new Error('O organizador não pode sair da partida (apenas cancelá-la).');
      }

      // --- Atualização dos dados ---
      const novoStatus = 'aberta'; // Se alguém sair, a partida reabre (mesmo que estivesse 'fechada')

      transaction.update(matchRef, {
        participantesIds: admin.firestore.FieldValue.arrayRemove(userId), // Remove o ID da lista
        vagasDisponiveis: admin.firestore.FieldValue.increment(1), // Devolve 1 vaga
        status: novoStatus, // Garante que a partida fique 'aberta'
      });
    });

    return res.status(200).json({ message: 'Você saiu da partida com sucesso!' });

  } catch (error: any) {
    console.error('Erro ao sair da partida:', error);
    // Retorna a mensagem de erro da regra de negócio
    return res.status(400).json({ message: error.message || 'Erro interno ao sair da partida.' });
  }
};

export const approveRequest = async (req: Request, res: Response) => {
  try {
    const organizerId = req.currentUser?.uid;
    const { matchId } = req.params;
    const { userIdToApprove } = req.body; // ID of the user to approve

    if (!organizerId) return res.status(403).json({ message: 'Acesso negado.' });
    if (!userIdToApprove) return res.status(400).json({ message: 'ID do usuário a aprovar é obrigatório.' });

    const matchRef = db.collection('partidasAbertas').doc(matchId);

    await db.runTransaction(async (transaction) => {
      const matchDoc = await transaction.get(matchRef);
      if (!matchDoc.exists) throw new Error('Partida não encontrada.');

      const matchData = matchDoc.data()!;

      if (matchData.organizadorId !== organizerId) {
        throw new Error('Apenas o organizador pode aprovar solicitações.');
      }
      if (!matchData.participantesPendentes || !matchData.participantesPendentes.includes(userIdToApprove)) {
        throw new Error('Este usuário não tem uma solicitação pendente.');
      }
      if (matchData.vagasDisponiveis <= 0) {
        throw new Error('Não há mais vagas disponíveis.');
      }

      // Move from pending to confirmed
      const novasVagas = matchData.vagasDisponiveis - 1;
      const novoStatus = (novasVagas === 0) ? 'fechada' : 'aberta';

      transaction.update(matchRef, {
        participantesPendentes: admin.firestore.FieldValue.arrayRemove(userIdToApprove),
        participantesIds: admin.firestore.FieldValue.arrayUnion(userIdToApprove),
        vagasDisponiveis: admin.firestore.FieldValue.increment(-1),
        status: novoStatus
      });
    });

    return res.status(200).json({ message: 'Solicitação aprovada com sucesso!' });

  } catch (error: any) {
    console.error('Erro ao aprovar solicitação:', error);
    return res.status(400).json({ message: error.message || 'Erro ao aprovar solicitação.' });
  }
};

export const rejectRequest = async (req: Request, res: Response) => {
  try {
    const organizerId = req.currentUser?.uid;
    const { matchId } = req.params;
    const { userIdToReject } = req.body;

    if (!organizerId) return res.status(403).json({ message: 'Acesso negado.' });
    if (!userIdToReject) return res.status(400).json({ message: 'ID do usuário a recusar é obrigatório.' });

    const matchRef = db.collection('partidasAbertas').doc(matchId);

    await db.runTransaction(async (transaction) => {
      const matchDoc = await transaction.get(matchRef);
      if (!matchDoc.exists) throw new Error('Partida não encontrada.');

      const matchData = matchDoc.data()!;

      if (matchData.organizadorId !== organizerId) {
        throw new Error('Apenas o organizador pode recusar solicitações.');
      }
      if (!matchData.participantesPendentes || !matchData.participantesPendentes.includes(userIdToReject)) {
        throw new Error('Este usuário não tem uma solicitação pendente.');
      }

      // Just remove from pending list
      transaction.update(matchRef, {
        participantesPendentes: admin.firestore.FieldValue.arrayRemove(userIdToReject)
      });
    });

    return res.status(200).json({ message: 'Solicitação recusada.' });

  } catch (error: any) {
    console.error('Erro ao recusar solicitação:', error);
    return res.status(400).json({ message: error.message || 'Erro ao recusar solicitação.' });
  }
};