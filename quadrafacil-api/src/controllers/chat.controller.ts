import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase';

// --- Função para LISTAR as conversas do usuário logado (GET /chats) ---
export const getUserChats = async (req: Request, res: Response) => {
    try {
        const userId = req.currentUser?.uid;
        if (!userId) {
            return res.status(403).json({ message: 'Acesso negado.' });
        }

        const chatsSnapshot = await db.collection('conversas')
            .where('participantesIds', 'array-contains', userId)
            .orderBy('ultimaMensagem.timestamp', 'desc')
            .get();

        // 1. Mapeamento assíncrono para buscar o nome do interlocutor
        const chatsPromises = chatsSnapshot.docs.map(async doc => {
            const data = doc.data();
            // Encontra o ID do outro participante
            const otherId = data.participantesIds.find((id: string) => id !== userId);
            
            let otherUserName = 'Usuário Desconhecido';

            if (otherId) {
                try {
                    // Busca o nome do usuário no Firebase Auth
                    const userRecord = await admin.auth().getUser(otherId);
                    otherUserName = userRecord.displayName ?? userRecord.email ?? otherUserName;
                } catch (e) { console.error("Erro ao buscar usuário do chat:", e); }
            }

            return {
                chatId: doc.id,
                ...data,
                otherUserName: otherUserName, // 2. Adicionado o nome para o Flutter
                otherUserId: otherId,
            };
        });

        const chatsList = await Promise.all(chatsPromises); // 3. Espera todas as buscas de nomes

        return res.status(200).json(chatsList);

    } catch (error) {
        console.error('Erro ao buscar conversas:', error);
        return res.status(500).json({ message: 'Erro interno ao buscar conversas.' });
    }
};


export const sendMessage = async (req: Request, res: Response) => {
    try {
        const userId = req.currentUser?.uid;
        const { chatId } = req.params;
        const { texto } = req.body; 

        if (!userId) return res.status(403).json({ message: 'Acesso negado.' });
        if (!texto || texto.trim() === '') return res.status(400).json({ message: 'A mensagem não pode ser vazia.' });

        const chatRef = db.collection('conversas').doc(chatId);
        
        await db.runTransaction(async (transaction) => {
            const chatDoc = await transaction.get(chatRef);

            if (!chatDoc.exists) throw new Error('Chat não encontrado.');
            
            const chatData = chatDoc.data();
            if (!chatData?.participantesIds.includes(userId)) {
                throw new Error('Você não é um participante deste chat.');
            }
            
            // 1. Adiciona a mensagem à subcoleção 'mensagens'
            const newMessage = {
                remetenteId: userId,
                texto: texto,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            };
            
            const messageRef = chatRef.collection('mensagens').doc();
            transaction.set(messageRef, newMessage);

            // 2. Atualiza o status da conversa principal
            transaction.update(chatRef, {
                ultimaMensagem: {
                    texto: texto,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    remetenteId: userId,
                },
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // TODO: (RF12) Implementar a Notificação Push aqui
        });

        return res.status(201).json({ message: 'Mensagem enviada com sucesso!' });

    } catch (error: any) {
        console.error('Erro ao enviar mensagem:', error);
        return res.status(400).json({ message: error.message || 'Erro ao enviar mensagem.' });
    }
};

export const getOrCreateMatchChat = async (req: Request, res: Response) => {
    try {
        const userId = req.currentUser?.uid;
        const { matchId } = req.params;

        if (!userId) {
            return res.status(403).json({ message: 'Acesso negado. Usuário não autenticado.' });
        }

        // 1. Tenta encontrar um chat existente para a partida
        const existingChatSnapshot = await db.collection('conversas')
            .where('matchId', '==', matchId)
            .limit(1)
            .get();

        if (!existingChatSnapshot.empty) {
            const existingChatId = existingChatSnapshot.docs[0].id;
            return res.status(200).json({ chatId: existingChatId, message: 'Chat existente retornado.' });
        }

        // 2. Se não existir, busca dados da partida para criar o chat
        const matchDoc = await db.collection('partidasAbertas').doc(matchId).get();
        if (!matchDoc.exists) {
            return res.status(404).json({ message: 'Partida não encontrada para criar o chat.' });
        }

        const matchData = matchDoc.data()!;
        const organizadorId = matchData.organizadorId;
        const participantesIds = matchData.participantesIds || [];
        
        // Garante que o organizador e participantes confirmados estejam na lista
        const initialParticipants = Array.from(new Set([organizadorId, ...participantesIds]));

        // 3. Cria um novo chat
        const newChat = {
            tipo: 'grupo', 
            matchId: matchId,
            participantesIds: initialParticipants,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            ultimaMensagem: {
                texto: `${matchData.quadraNome || 'A partida'} foi criada!`,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            },
        };

        const chatRef = await db.collection('conversas').add(newChat);
        return res.status(201).json({ chatId: chatRef.id, message: 'Novo chat criado.' });

    } catch (error) {
        console.error('Erro ao buscar/criar chat de partida:', error);
        return res.status(500).json({ message: 'Erro interno ao processar chat.' });
    }
};

export const addMemberToMatchChat = async (matchId: string, userId: string) => {
    try {
        const chatSnapshot = await db.collection('conversas')
            .where('matchId', '==', matchId)
            .limit(1)
            .get();

        if (!chatSnapshot.empty) {
            const chatId = chatSnapshot.docs[0].id;
            const chatRef = db.collection('conversas').doc(chatId);

            await chatRef.update({
                participantesIds: admin.firestore.FieldValue.arrayUnion(userId),
                ultimaMensagem: {
                    texto: 'Novo membro entrou no chat.',
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                },
            });
            return { success: true };
        }
    } catch (error) {
        console.error(`Erro ao adicionar usuário ${userId} ao chat ${matchId}:`, error);
        return { success: false, error };
    }
};

export const removeMemberFromMatchChat = async (matchId: string, userId: string) => {
    try {
        const chatSnapshot = await db.collection('conversas')
            .where('matchId', '==', matchId)
            .limit(1)
            .get();

        if (!chatSnapshot.empty) {
            const chatId = chatSnapshot.docs[0].id;
            const chatRef = db.collection('conversas').doc(chatId);

            await chatRef.update({
                participantesIds: admin.firestore.FieldValue.arrayRemove(userId),
                ultimaMensagem: {
                    texto: 'Um membro saiu do chat.',
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                },
            });
            return { success: true };
        }
    } catch (error) {
        console.error(`Erro ao remover usuário ${userId} do chat ${matchId}:`, error);
        return { success: false, error };
    }
};

export const getChatMessages = async (req: Request, res: Response) => {
    try {
        const userId = req.currentUser?.uid;
        const { chatId } = req.params;

        if (!userId) {
            return res.status(403).json({ message: 'Acesso negado. Usuário não autenticado.' });
        }

        // 1. Verificar se o chat existe e se o usuário é participante
        const chatDoc = await db.collection('conversas').doc(chatId).get();

        if (!chatDoc.exists) {
            return res.status(404).json({ message: 'Chat não encontrado.' });
        }

        const chatData = chatDoc.data();
        if (!chatData?.participantesIds.includes(userId)) {
            return res.status(403).json({ message: 'Você não é um participante deste chat.' });
        }

        // 2. Buscar as 50 mensagens mais recentes
        const messagesSnapshot = await db.collection('conversas').doc(chatId)
            .collection('mensagens')
            .orderBy('timestamp', 'desc') 
            .limit(50) 
            .get();

        const messages = messagesSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
            timestamp: doc.data().timestamp ? doc.data().timestamp.toDate() : null 
        })).reverse(); 

        return res.status(200).json(messages);

    } catch (error) {
        console.error('Erro ao buscar mensagens do chat:', error);
        return res.status(500).json({ message: 'Erro interno ao buscar mensagens.' });
    }
};

export const getOrCreateBookingChat = async (req: Request, res: Response) => {
    try {
        const currentUserId = req.currentUser?.uid;
        const { bookingId } = req.params;

        if (!currentUserId) return res.status(403).json({ message: 'Acesso negado.' });
        if (!bookingId) return res.status(400).json({ message: 'ID da reserva inválido.' });

        // 1. Verificar se já existe chat
        const existingChatSnapshot = await db.collection('conversas')
            .where('bookingId', '==', bookingId)
            .limit(1)
            .get();

        if (!existingChatSnapshot.empty) {
            return res.status(200).json({ chatId: existingChatSnapshot.docs[0].id });
        }

        // 2. Buscar dados da Reserva
        const bookingDoc = await db.collection('reservas').doc(bookingId).get();
        
        if (!bookingDoc.exists) {
            return res.status(404).json({ message: 'Reserva não encontrada.' });
        }
        
        const bookingData = bookingDoc.data()!;
        
        // --- CORREÇÃO AQUI: Lendo os campos em Inglês OU Português ---
        const atletaId = bookingData.userId || bookingData.usuarioId;
        // const quadraId = bookingData.courtId || bookingData.quadraId; // Nem vamos precisar se já tiver o ownerId
        
        // Otimização: Se já tem o ownerId na reserva, usa direto!
        let donoId = bookingData.ownerId; 
        let quadraNome = bookingData.quadraNome || 'Quadra';

        // Fallback: Se por acaso não tiver ownerId, buscamos na quadra (segurança)
        if (!donoId) {
             const quadraId = bookingData.courtId || bookingData.quadraId;
             if (quadraId) {
                const courtDoc = await db.collection('quadras').doc(quadraId).get();
                if (courtDoc.exists) {
                    donoId = courtDoc.data()?.donoId;
                    quadraNome = courtDoc.data()?.nome || quadraNome;
                }
             }
        }

        if (!donoId || !atletaId) {
             console.error('❌ Dados incompletos na reserva:', bookingData);
             return res.status(400).json({ message: 'Reserva com dados inconsistentes (falta ID de dono ou atleta).' });
        }

        // 3. Criar o Chat
        const newChat = {
            tipo: 'reserva',
            bookingId: bookingId,
            participantesIds: [atletaId, donoId], // IDs Corretos agora!
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            ultimaMensagem: {
                texto: `Chat iniciado sobre a reserva: ${quadraNome}`,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            }
        };

        const chatRef = await db.collection('conversas').add(newChat);
        return res.status(201).json({ chatId: chatRef.id, message: 'Chat criado.' });

    } catch (error: any) {
        console.error('🔥 ERRO NO CONTROLLER DE CHAT:', error);
        return res.status(500).json({ message: 'Erro interno ao criar chat.' });
    }
};