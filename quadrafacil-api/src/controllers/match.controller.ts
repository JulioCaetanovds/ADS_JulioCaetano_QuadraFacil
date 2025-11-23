import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase';
import { addMemberToMatchChat, removeMemberFromMatchChat } from './chat.controller';

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

export const getPublicMatches = async (req: Request, res: Response) => {
  try {
    const now = admin.firestore.Timestamp.now();
    
    // 1. Captura os filtros da URL (Query Params)
    // Ex: /matches/public?esporte=Futsal&busca=Arena
    const { esporte, busca } = req.query; 

    // 2. Busca TODAS as partidas abertas futuras (Filtro grosso no Banco)
    const matchesSnapshot = await db.collection('partidasAbertas')
      .where('status', '==', 'aberta')
      .where('startTime', '>', now)
      .orderBy('startTime', 'asc')
      .get();

    if (matchesSnapshot.empty) {
      return res.status(200).json([]);
    }

    // 3. Cruzamento de dados (Enrichment) - Busca dados da Quadra
    const matchesPromises = matchesSnapshot.docs.map(async (doc) => {
      const matchData = doc.data();
      const quadraId = matchData.quadraId;

      let quadraNome = 'Quadra N/D';
      let quadraEndereco = 'Endereço N/D';
      let esporteQuadra = 'Esporte N/D'; // Variável local para filtrar depois

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
      } catch (e) {
        console.error(`Erro ao buscar quadra ${quadraId}:`, e);
      }

      return {
        id: doc.id,
        ...matchData,
        quadraNome: quadraNome,
        quadraEndereco: quadraEndereco,
        esporte: esporteQuadra, // Importante retornar isso pro front saber
      };
    });

    const enrichedMatchesList = await Promise.all(matchesPromises);

    // 4. APLICAÇÃO DOS FILTROS (Na memória do servidor) 🧠
    let resultadoFiltrado = enrichedMatchesList;

    // A. Filtro por Esporte (Exato)
    if (esporte && typeof esporte === 'string' && esporte.trim() !== '') {
        resultadoFiltrado = resultadoFiltrado.filter(match => 
            match.esporte?.toLowerCase() === esporte.toLowerCase()
        );
    }

    // B. Filtro por Busca Geral (Nome da Quadra ou Endereço)
    if (busca && typeof busca === 'string' && busca.trim() !== '') {
        const termo = busca.toLowerCase();
        resultadoFiltrado = resultadoFiltrado.filter(match => 
            match.quadraNome.toLowerCase().includes(termo) ||
            match.quadraEndereco.toLowerCase().includes(termo)
        );
    }

    return res.status(200).json(resultadoFiltrado);

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

