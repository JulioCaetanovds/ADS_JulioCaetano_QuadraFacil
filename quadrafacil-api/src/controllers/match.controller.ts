import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase';
import { addMemberToMatchChat, removeMemberFromMatchChat } from './chat.controller';

// POST /matches/open
export const openMatch = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid; 
    const { bookingId, vagasAbertas } = req.body;

    if (!userId) return res.status(403).json({ message: 'Acesso negado.' });
    if (!bookingId || !vagasAbertas) return res.status(400).json({ message: 'Dados incompletos.' });

    const bookingRef = db.collection('reservas').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) return res.status(404).json({ message: 'Reserva não encontrada.' });
    
    const bookingData = bookingDoc.data()!;

    if (bookingData.userId !== userId) return res.status(403).json({ message: 'Você não é o dono desta reserva.' });
    if (bookingData.status !== 'confirmada') return res.status(400).json({ message: 'Apenas reservas confirmadas podem ser abertas.' });
    if (bookingData.partidaAbertaId) return res.status(400).json({ message: 'Esta reserva já virou partida.' });
    
    const startTime = bookingData.startTime.toDate();
    if (startTime < new Date()) return res.status(400).json({ message: 'Reserva já expirada.' });

    // --- CRIAÇÃO DA PARTIDA ---
    const newMatchData = {
      reservaId: bookingId,
      organizadorId: userId,
      quadraId: bookingData.courtId || bookingData.quadraId, 
      startTime: bookingData.startTime, 
      endTime: bookingData.endTime,     
      vagasDisponiveis: Number(vagasAbertas),
      participantesIds: [userId], 
      status: 'aberta',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      // CORREÇÃO 1: Copiamos o preço da reserva para a partida
      priceTotal: bookingData.priceTotal ?? 0.0, 
    };

    const newMatchRef = await db.collection('partidasAbertas').add(newMatchData);

    await bookingRef.update({ partidaAbertaId: newMatchRef.id });

    return res.status(201).json({
      message: 'Partida aberta com sucesso!',
      matchId: newMatchRef.id,
      data: newMatchData
    });

  } catch (error) {
    console.error('Erro ao abrir partida:', error);
    return res.status(500).json({ message: 'Erro interno.' });
  }
};

export const getPublicMatches = async (req: Request, res: Response) => {
  try {
    const now = admin.firestore.Timestamp.now();
    const { esporte, busca } = req.query; 

    const matchesSnapshot = await db.collection('partidasAbertas')
      .where('status', '==', 'aberta')
      .where('startTime', '>', now)
      .orderBy('startTime', 'asc')
      .get();

    if (matchesSnapshot.empty) return res.status(200).json([]);

    const matchesPromises = matchesSnapshot.docs.map(async (doc) => {
      const matchData = doc.data();
      const quadraId = matchData.quadraId;

      let quadraNome = 'Quadra N/D';
      let quadraEndereco = 'Endereço N/D';
      let esporteQuadra = 'Esporte N/D';

      // CORREÇÃO 2: Fallback visual para preço na listagem se não tiver salvo
      let priceTotal = matchData.priceTotal;

      try {
        if (quadraId) {
            const courtDoc = await db.collection('quadras').doc(quadraId).get();
            if (courtDoc.exists) {
              const cData = courtDoc.data()!;
              quadraNome = cData.nome ?? quadraNome;
              quadraEndereco = cData.endereco ?? quadraEndereco;
              esporteQuadra = cData.esporte ?? esporteQuadra;
            }
        }
        // Se a partida antiga não tem preço, tenta buscar na reserva (esforço extra)
        if (priceTotal === undefined && matchData.reservaId) {
             const bDoc = await db.collection('reservas').doc(matchData.reservaId).get();
             if (bDoc.exists) priceTotal = bDoc.data()?.priceTotal;
        }
      } catch (e) { console.error(e); }

      return {
        id: doc.id,
        ...matchData,
        priceTotal: priceTotal ?? 0.0, // Envia garantido
        quadraNome: quadraNome,
        quadraEndereco: quadraEndereco,
        esporte: esporteQuadra,
      };
    });

    const enrichedMatchesList = await Promise.all(matchesPromises);

    // Filtros em memória
    let resultado = enrichedMatchesList;
    if (esporte && typeof esporte === 'string') {
        resultado = resultado.filter(m => m.esporte?.toLowerCase() === esporte.toLowerCase());
    }
    if (busca && typeof busca === 'string') {
        const t = busca.toLowerCase();
        resultado = resultado.filter(m => m.quadraNome.toLowerCase().includes(t) || m.quadraEndereco.toLowerCase().includes(t));
    }

    return res.status(200).json(resultado);

  } catch (error) {
    console.error('Erro ao listar:', error);
    return res.status(500).json({ message: 'Erro interno.' });
  }
};

export const getMatchDetails = async (req: Request, res: Response) => {
  try {
    const { matchId } = req.params;
    if (!matchId) return res.status(400).json({ message: 'ID obrigatório.' });

    const matchRef = db.collection('partidasAbertas').doc(matchId);
    const matchDoc = await matchRef.get();

    if (!matchDoc.exists) return res.status(404).json({ message: 'Partida não encontrada.' });

    const matchData = matchDoc.data()!;
    
    // CORREÇÃO 3: Lógica de Resgate de Preço (Salva vidas de partidas antigas)
    if (matchData.priceTotal === undefined || matchData.priceTotal === null) {
        console.log("⚠️ Partida sem preço, buscando na reserva original...");
        try {
            const bDoc = await db.collection('reservas').doc(matchData.reservaId).get();
            if (bDoc.exists) {
                matchData.priceTotal = bDoc.data()?.priceTotal;
                // Opcional: Salvar de volta na partida pra não buscar de novo
                await matchRef.update({ priceTotal: matchData.priceTotal });
            }
        } catch(e) { console.error("Erro no fallback de preço", e); }
    }

    const quadraId = matchData.quadraId;
    const organizadorId = matchData.organizadorId;
    const participantesIds: string[] = matchData.participantesIds || [];
    const participantesPendentesIds: string[] = matchData.participantesPendentes || [];

    let quadraData = {};
    let organizadorData = { nome: 'Organizador N/D', fotoUrl: null };

    // Buscas paralelas para ser rápido
    const [courtDoc, userRecord] = await Promise.all([
        db.collection('quadras').doc(quadraId).get().catch(() => null),
        admin.auth().getUser(organizadorId).catch(() => null)
    ]);

    if (courtDoc && courtDoc.exists) quadraData = courtDoc.data() ?? {};
    if (userRecord) {
        organizadorData = {
            nome: (userRecord as any).displayName ?? (userRecord as any).email ?? 'Organizador',
            fotoUrl: (userRecord as any).photoURL ?? null
        };
    }

    // Função auxiliar para buscar dados de usuários
    const fetchUsersData = async (ids: string[]) => {
      return Promise.all(ids.map(async (id) => {
        try {
          if (id === organizadorId) return { id, ...organizadorData };
          const u = await admin.auth().getUser(id);
          return {
            id: id,
            nome: u.displayName ?? u.email ?? 'Usuário',
            fotoUrl: u.photoURL ?? null
          };
        } catch (e) { return { id: id, nome: 'Usuário', fotoUrl: null }; }
      }));
    };

    const participantesData = await fetchUsersData(participantesIds);
    const pendentesData = await fetchUsersData(participantesPendentesIds);

    const responseData = {
      id: matchDoc.id,
      ...matchData,
      priceTotal: matchData.priceTotal ?? 0.0, // Garante que vai no JSON
      quadraData: quadraData,
      organizadorData: organizadorData,
      participantesData: participantesData,
      pendentesData: pendentesData,
    };

    return res.status(200).json(responseData);

  } catch (error) {
    console.error('Erro detalhe partida:', error);
    return res.status(500).json({ message: 'Erro interno.' });
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

      if (matchData.startTime.toDate() < new Date()) {
        throw new Error('Esta partida já ocorreu.');
      }
      if (!matchData.participantesIds.includes(userId)) {
        throw new Error('Você não está participando desta partida.');
      }
      if (matchData.organizadorId === userId) {
        throw new Error('O organizador não pode sair da partida (apenas cancelá-la).');
      }

      // Remove da lista de participantes confirmados e devolve a vaga (BACK-END)
      const novoStatus = 'aberta'; 
      transaction.update(matchRef, {
        participantesIds: admin.firestore.FieldValue.arrayRemove(userId),
        vagasDisponiveis: admin.firestore.FieldValue.increment(1),
        status: novoStatus,
      });
    });

    // 2. AÇÃO DE CHAT: Remove o usuário do grupo de conversa
    await removeMemberFromMatchChat(matchId, userId);

    return res.status(200).json({ message: 'Você saiu da partida com sucesso!' });

  } catch (error: any) {
    console.error('Erro ao sair da partida:', error);
    return res.status(400).json({ message: error.message || 'Erro interno ao sair da partida.' });
  }
};

export const approveRequest = async (req: Request, res: Response) => {
  try {
    const organizerId = req.currentUser?.uid;
    const { matchId } = req.params;
    // O nome da chave é 'userIdToApprove'
    const userIdToApprove = req.body.userIdToApprove;

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

      // 1. Move de pendente para confirmado (BACK-END)
      const novasVagas = matchData.vagasDisponiveis - 1;
      const novoStatus = (novasVagas === 0) ? 'fechada' : 'aberta';

      transaction.update(matchRef, {
        participantesPendentes: admin.firestore.FieldValue.arrayRemove(userIdToApprove),
        participantesIds: admin.firestore.FieldValue.arrayUnion(userIdToApprove),
        vagasDisponiveis: admin.firestore.FieldValue.increment(-1),
        status: novoStatus
      });
    });

    // 2. AÇÃO DE CHAT: Adiciona o usuário ao grupo de conversa (CROSS-COLLECTION)
    await addMemberToMatchChat(matchId, userIdToApprove);

    return res.status(200).json({ message: 'Solicitação aprovada com sucesso!' });

  } catch (error: any) {
    console.error('Erro ao aprovar solicitação:', error);
    return res.status(400).json({ message: error.message || 'Erro ao aprovar solicitação.' });
  }
};

export const rejectRequest = async (req: Request, res: Response) => {
  try {
    const organizerId = req.currentUser?.uid; // [CORRETO]
    const { matchId } = req.params;
    const userIdToReject = req.body.userIdToReject;

    // AQUI ESTÁ A VERIFICAÇÃO INICIAL QUE ESTAVA CAUSANDO O ERRO
    if (!organizerId) return res.status(403).json({ message: 'Acesso negado.' }); 
    if (!userIdToReject) return res.status(400).json({ message: 'ID do usuário a recusar é obrigatório.' });

    const matchRef = db.collection('partidasAbertas').doc(matchId);

    await db.runTransaction(async (transaction) => {
      const matchDoc = await transaction.get(matchRef);
      if (!matchDoc.exists) throw new Error('Partida não encontrada.');

      const matchData = matchDoc.data()!;

      // CORREÇÃO: Usar 'organizerId' (a variável local)
      if (matchData.organizadorId !== organizerId) {
        throw new Error('Apenas o organizador pode recusar solicitações.');
      }
      if (!matchData.participantesPendentes || !matchData.participantesPendentes.includes(userIdToReject)) {
        throw new Error('Este usuário não tem uma solicitação pendente.');
      }

      transaction.update(matchRef, {
        participantesPendentes: admin.firestore.FieldValue.arrayRemove(userIdToReject)
      });
    });

    await removeMemberFromMatchChat(matchId, userIdToReject);

    return res.status(200).json({ message: 'Solicitação recusada.' });

  } catch (error: any) {
    console.error('Erro ao recusar solicitação:', error);
    return res.status(400).json({ message: error.message || 'Erro ao recusar solicitação.' });
  }
};

