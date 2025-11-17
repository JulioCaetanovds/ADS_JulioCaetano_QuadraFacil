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

    const matchesSnapshot = await db.collection('partidasAbertas')
      .where('status', '==', 'aberta')
      .where('startTime', '>', now)
      .orderBy('startTime', 'asc')
      .get();

    if (matchesSnapshot.empty) {
      return res.status(200).json([]);
    }

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

    let quadraData = {};
    
    let organizadorData: { nome: string; fotoUrl: string | null } = { 
      nome: 'Organizador N/D', 
      fotoUrl: null 
    };

    let participantesData: any[] = [];

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

    // TODO: Buscar o perfil de cada participante se necessário
    participantesData = participantesIds.map(id => ({
      id: id,
      nome: id === organizadorId ? organizadorData.nome : 'Participante' 
    }));

    return res.status(200).json({
      id: matchDoc.id,
      ...matchData,
      quadraData: quadraData,
      organizadorData: organizadorData,
      participantesData: participantesData,
    });

  } catch (error) {
    console.error('Erro ao buscar detalhes da partida:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar detalhes.' });
  }
};

// --- NOVA FUNÇÃO (RF09) ---
// POST /matches/:matchId/join
export const joinMatch = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid; // ID do atleta que quer entrar
    const { matchId } = req.params;

    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    const matchRef = db.collection('partidasAbertas').doc(matchId);

    // Executa a lógica como uma transação para evitar race conditions
    await db.runTransaction(async (transaction) => {
      const matchDoc = await transaction.get(matchRef);

      if (!matchDoc.exists) {
        throw new Error('Partida não encontrada.');
      }

      const matchData = matchDoc.data()!;

      // --- Regras de Negócio ---
      if (matchData.status !== 'aberta') {
        throw new Error('Esta partida não está mais aberta a novos participantes.');
      }
      if (matchData.vagasDisponiveis <= 0) {
        throw new Error('Não há mais vagas disponíveis para esta partida.');
      }
      if (matchData.participantesIds.includes(userId)) {
        throw new Error('Você já está participando desta partida.');
      }
      if (matchData.startTime.toDate() < new Date()) {
        throw new Error('Esta partida já ocorreu.');
      }

      // --- Atualização dos dados ---
      const novasVagas = matchData.vagasDisponiveis - 1;
      const novoStatus = (novasVagas === 0) ? 'fechada' : 'aberta';

      transaction.update(matchRef, {
        participantesIds: admin.firestore.FieldValue.arrayUnion(userId), // Adiciona o ID à lista
        vagasDisponiveis: admin.firestore.FieldValue.increment(-1), // Decrementa 1
        status: novoStatus, // Atualiza o status se as vagas acabarem
      });
    });

    return res.status(200).json({ message: 'Você entrou na partida com sucesso!' });

  } catch (error: any) {
    console.error('Erro ao entrar na partida:', error);
    // Retorna a mensagem de erro da regra de negócio (ex: "Não há mais vagas")
    return res.status(400).json({ message: error.message || 'Erro interno ao entrar na partida.' });
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