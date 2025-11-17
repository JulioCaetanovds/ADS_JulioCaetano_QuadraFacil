// src/controllers/court.controller.ts

import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase'; // Nossa conexão com o Firestore

// --- Função para CRIAR uma nova quadra ---
// (Sem alterações)
export const createCourt = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    if (!ownerId) {
      return res.status(403).json({ message: 'Acesso negado. UID do usuário não encontrado.' });
    }
    const { nome, descricao, esporte, endereco, regras } = req.body;
    if (!nome || !esporte || !endereco) {
      return res.status(400).json({ message: 'Nome, esporte e endereço são obrigatórios.' });
    }
    const newCourtRef = await db.collection('quadras').add({
      ownerId,
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
// (Sem alterações)
export const getCourtsByOwner = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    if (!ownerId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }
    const courtsSnapshot = await db.collection('quadras').where('ownerId', '==', ownerId).get();
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

// --- Função para BUSCAR UMA ÚNICA quadra pelo ID (Rota do Dono) ---
// (Sem alterações)
export const getCourtById = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { courtId } = req.params; 
    const courtDoc = await db.collection('quadras').doc(courtId).get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }
    const courtData = courtDoc.data();
    if (courtData?.ownerId !== ownerId) {
      return res.status(403).json({ message: 'Acesso negado a este recurso.' });
    }
    return res.status(200).json({ id: courtDoc.id, ...courtData });
  } catch (error) {
    console.error('Erro ao buscar quadra por ID:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar quadra.' });
  }
};

// --- Função para ATUALIZAR uma quadra ---
// (Sem alterações)
export const updateCourt = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { courtId } = req.params;
    const courtData = req.body; 
    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }
    if (courtDoc.data()?.ownerId !== ownerId) {
      return res.status(403).json({ message: 'Acesso negado. Você não é o dono desta quadra.' });
    }
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
// (Sem alterações)
export const deleteCourt = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { courtId } = req.params;
    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }
    if (courtDoc.data()?.ownerId !== ownerId) {
      return res.status(403).json({ message: 'Acesso negado. Você não é o dono desta quadra.' });
    }
    await courtRef.delete();
    return res.status(200).json({ message: 'Quadra excluída com sucesso!' });
  } catch (error) {
    console.error('Erro ao excluir quadra:', error);
    return res.status(500).json({ message: 'Erro interno ao excluir quadra.' });
  }
};

// --- Função para DEFINIR/ATUALIZAR a disponibilidade ---
// (Sem alterações)
export const setCourtAvailability = async (req: Request, res: Response) => {
  try {
    const ownerId = req.currentUser?.uid;
    const { courtId } = req.params;
    const availabilityData = req.body; 
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
    await courtRef.set({ availability: availabilityData }, { merge: true });
    return res.status(200).json({ message: 'Disponibilidade atualizada com sucesso!' });
  } catch (error) {
    console.error('Erro ao definir disponibilidade:', error);
    return res.status(500).json({ message: 'Erro interno ao definir disponibilidade.' });
  }
};

// --- Função para BUSCAR a disponibilidade de uma quadra (Pública) ---
// (Sem alterações)
export const getCourtAvailability = async (req: Request, res: Response) => {
  try {
    const { courtId } = req.params;
    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }
    const courtData = courtDoc.data();
    const availability = courtData?.availability || {}; 
    return res.status(200).json(availability);
  } catch (error) {
    console.error('Erro ao buscar disponibilidade:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar disponibilidade.' });
  }
};

// --- Função para LISTAR TODAS as quadras (Pública) ---
// (Sem alterações)
export const getAllPublicCourts = async (req: Request, res: Response) => {
  try {
    const courtsSnapshot = await db.collection('quadras').get();
    const courtsList = courtsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
    return res.status(200).json(courtsList);
  } catch (error) {
    console.error('Erro ao buscar todas as quadras:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar quadras.' });
  }
};

// --- NOVA FUNÇÃO (RF10) ---
// GET /courts/:courtId/public-details (Rota do Atleta)
export const getPublicCourtDetails = async (req: Request, res: Response) => {
  try {
    const { courtId } = req.params;
    const courtRef = db.collection('quadras').doc(courtId);
    const courtDoc = await courtRef.get();

    if (!courtDoc.exists) {
      return res.status(404).json({ message: 'Quadra não encontrada.' });
    }

    const courtData = courtDoc.data()!;
    const ownerId = courtData.ownerId; // Pega o ID do dono

    let ownerPixKey = null;

    // Busca o dono na coleção 'usuarios' para pegar a chave PIX
    if (ownerId) {
      const ownerDoc = await db.collection('usuarios').doc(ownerId).get();
      if (ownerDoc.exists) {
        ownerPixKey = ownerDoc.data()?.pixKey ?? null;
      }
    }
    
    // Retorna os dados da quadra E a chave PIX do dono
    return res.status(200).json({
      id: courtDoc.id,
      ...courtData,
      ownerPixKey: ownerPixKey, // Adiciona a chave PIX
    });

  } catch (error) {
    console.error('Erro ao buscar detalhes públicos da quadra:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar detalhes da quadra.' });
  }
};