// src/controllers/court.controller.ts

import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase'; // Nossa conexão com o Firestore

// --- Função para CRIAR uma nova quadra ---
export const createCourt = async (req: Request, res: Response) => {
  try {
    // Pegamos o UID do usuário que foi validado pelo nosso middleware
    const ownerId = req.currentUser?.uid;
    if (!ownerId) {
      return res.status(403).json({ message: 'Acesso negado. UID do usuário não encontrado.' });
    }

    // Pegamos os dados da quadra do corpo da requisição
    const { nome, descricao, esporte, endereco, regras } = req.body;
    if (!nome || !esporte || !endereco) {
      return res.status(400).json({ message: 'Nome, esporte e endereço são obrigatórios.' });
    }

    // Criamos um novo documento na coleção 'quadras'
    const newCourtRef = await db.collection('quadras').add({
      ownerId, // Ligamos a quadra ao dono
      nome,
      descricao,
      esporte,
      endereco,
      regras,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(201).json({ 
      message: 'Quadra criada com sucesso!',
      courtId: newCourtRef.id 
    });

  } catch (error) {
    console.error('Erro ao criar quadra:', error);
    return res.status(500).json({ message: 'Erro interno ao criar quadra.' });
  }
};

// --- Função para LISTAR as quadras de um dono ---
export const getCourtsByOwner = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    if (!ownerId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    // Buscamos na coleção 'quadras' todos os documentos onde 'ownerId' é igual ao do usuário logado
    const courtsSnapshot = await db.collection('quadras').where('ownerId', '==', ownerId).get();

    // Transformamos o resultado em uma lista
    const courtsList = courtsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.status(200).json(courtsList);

  } catch (error) {
    console.error('Erro ao buscar quadras:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar quadras.' });
  }
};

// --- Função para BUSCAR UMA ÚNICA quadra pelo ID ---
export const getCourtById = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { courtId } = req.params; // Pega o ID da URL (ex: /courts/ABC123)

    const courtDoc = await db.collection('quadras').doc(courtId).get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }

    const courtData = courtDoc.data();

    // Verificação de segurança: este dono é realmente o dono desta quadra?
    if (courtData?.ownerId !== ownerId) {
      return res.status(403).json({ message: 'Acesso negado a este recurso.' });
    }

    return res.status(200).json({ id: courtDoc.id, ...courtData });

  } catch (error) {
    console.error('Erro ao buscar quadra por ID:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar quadra.' });
  }
};

export const updateCourt = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { courtId } = req.params; // Pega o ID da quadra pela URL
    const courtData = req.body; // Pega os novos dados (nome, descricao, etc.) do corpo

    // Busca a quadra para garantir que o dono é o mesmo
    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }
    
    // Verificação de segurança
    if (courtDoc.data()?.ownerId !== ownerId) {
      return res.status(403).json({ message: 'Acesso negado. Você não é o dono desta quadra.' });
    }

    // Atualiza o documento no Firestore com os novos dados
    await courtRef.update(courtData);

    return res.status(200).json({ 
      message: 'Quadra atualizada com sucesso!',
      updatedData: courtData 
    });

  } catch (error) {
    console.error('Erro ao atualizar quadra:', error);
    return res.status(500).json({ message: 'Erro interno ao atualizar quadra.' });
  }
};

// --- Função para DELETAR uma quadra ---
export const deleteCourt = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { courtId } = req.params; // Pega o ID da quadra pela URL

    // Busca a quadra para garantir que o dono é o mesmo
    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }
    
    // Verificação de segurança
    if (courtDoc.data()?.ownerId !== ownerId) {
      return res.status(403).json({ message: 'Acesso negado. Você não é o dono desta quadra.' });
    }

    // Deleta o documento no Firestore
    await courtRef.delete();

    return res.status(200).json({ message: 'Quadra excluída com sucesso!' });

  } catch (error) {
    console.error('Erro ao excluir quadra:', error);
    return res.status(500).json({ message: 'Erro interno ao excluir quadra.' });
  }
};

// --- Função para DEFINIR/ATUALIZAR a disponibilidade de uma quadra ---
export const setCourtAvailability = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { courtId } = req.params;
    const availabilityData = req.body; // Espera receber um objeto como o exemplo acima

    // Validação básica (poderia ser mais robusta)
    if (!availabilityData || typeof availabilityData !== 'object') {
       return res.status(400).json({ message: 'Dados de disponibilidade inválidos.' });
    }

    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }
    if (courtDoc.data()?.ownerId !== ownerId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    // Atualiza APENAS o campo 'availability' no documento da quadra
    // O 'merge: true' garante que outros campos não sejam apagados
    await courtRef.set({ availability: availabilityData }, { merge: true });

    return res.status(200).json({ message: 'Disponibilidade atualizada com sucesso!' });

  } catch (error) {
    console.error('Erro ao definir disponibilidade:', error);
    return res.status(500).json({ message: 'Erro interno ao definir disponibilidade.' });
  }
};

// --- Função para BUSCAR a disponibilidade de uma quadra ---
export const getCourtAvailability = async (req: Request, res: Response) => {
  try {
    const { courtId } = req.params;
    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }

    const courtData = courtDoc.data();
    const availability = courtData?.availability || {}; // Retorna objeto vazio se não houver dados

    return res.status(200).json(availability);

  } catch (error) {
    console.error('Erro ao buscar disponibilidade:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar disponibilidade.' });
  }
};