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


// --- Função para ENVIAR uma nova mensagem (POST /chats/:chatId/messages) ---
export const sendMessage = async (req: Request, res: Response) => {
    try {
        const userId = req.currentUser?.uid;
        const { chatId } = req.params;
        const { texto } = req.body;

        if (!userId || !chatId || !texto) {
            return res.status(400).json({ message: 'Usuário, Chat ID e Texto são obrigatórios.' });
        }

        const conversaRef = db.collection('conversas').doc(chatId);
        
        // 1. Cria a mensagem na subcoleção 'mensagens'
        await conversaRef.collection('mensagens').add({
            remetenteId: userId,
            texto: texto,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 2. Atualiza o documento principal da conversa com a última mensagem (para ordenação)
        await conversaRef.update({
            ultimaMensagem: {
                texto: texto.substring(0, 50) + (texto.length > 50 ? '...' : ''), // Preview da mensagem
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            },
        });

        return res.status(201).json({ message: 'Mensagem enviada.' });

    } catch (error) {
        console.error('Erro ao enviar mensagem:', error);
        return res.status(500).json({ message: 'Erro interno ao enviar mensagem.' });
    }
};

export const getOrCreateMatchChat = async (req: Request, res: Response) => {
    try {
        const userId = req.currentUser?.uid;
        const { matchId } = req.params;

        if (!userId) {
            return res.status(403).json({ message: 'Acesso negado.' });
        }
        if (!matchId) {
            return res.status(400).json({ message: 'ID da partida é obrigatório.' });
        }

        // 1. Verificar se o chat já existe para esta partida
        const existingChatSnapshot = await db.collection('conversas')
            .where('matchId', '==', matchId)
            .limit(1)
            .get();

        if (existingChatSnapshot.empty) {
            // --- Chat não existe: Criar um novo ---

            // A. Buscar todos os UIDs necessários (Organizadores, Participantes e Dono da Quadra)
            const matchDoc = await db.collection('partidasAbertas').doc(matchId).get();
            if (!matchDoc.exists) {
                return res.status(404).json({ message: 'Partida não encontrada para criar o chat.' });
            }
            const matchData = matchDoc.data()!;
            const courtId = matchData.quadraId; // ID da quadra na partida

            // Buscar ID do Dono da Quadra
            const courtDoc = await db.collection('quadras').doc(courtId).get();
            const courtOwnerId = courtDoc.exists ? courtDoc.data()?.ownerId : null;

            const confirmedParticipants: string[] = matchData.participantesIds || [];
            
            // 2. Montar a lista final de UIDs (Organizadores, Dono da Quadra, Participantes)
            let allParticipants = new Set<string>(confirmedParticipants);
            if (courtOwnerId) {
                allParticipants.add(courtOwnerId);
            }
            
            const participantesIdsArray = Array.from(allParticipants);
            
            // 3. Criar a nova conversa
            const newChatRef = await db.collection('conversas').add({
                matchId: matchId, // Linka o chat diretamente à partida
                participantesIds: participantesIdsArray,
                titulo: matchData.quadraNome || 'Chat da Partida', // Usa o nome da quadra como título
                ultimaMensagem: {
                    texto: 'Chat criado para a partida!',
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return res.status(201).json({
                message: 'Chat de grupo criado com sucesso!',
                chatId: newChatRef.id,
                isNew: true,
            });

        } else {
            // --- Chat já existe: Apenas retornar a ID existente ---
            const existingChatId = existingChatSnapshot.docs[0].id;

            return res.status(200).json({
                message: 'Chat de grupo encontrado.',
                chatId: existingChatId,
                isNew: false,
            });
        }

    } catch (error) {
        console.error('Erro ao criar/buscar chat de grupo:', error);
        return res.status(500).json({ message: 'Erro interno ao criar/buscar chat.' });
    }
};

// TODO: Adicionar função para buscar histórico de mensagens
// TODO: Adicionar função para iniciar nova conversa (Verificar se já existe)