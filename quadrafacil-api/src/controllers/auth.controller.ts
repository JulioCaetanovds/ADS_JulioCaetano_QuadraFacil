// src/controllers/auth.controller.ts

import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase'; // Nossa conexão com o Firestore

// --- FUNÇÃO DE REGISTRO (Sem alterações) ---
export const registerUser = async (req: Request, res: Response) => {
  try {
    const { name, email, password, role } = req.body;

    if (!email || !password || !name || !role) {
      return res.status(400).json({ message: 'Todos os campos são obrigatórios.' });
    }

    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    // Salva dados no Firestore
    await db.collection('usuarios').doc(userRecord.uid).set({
      name: name,
      email: email,
      role: role, // 'atleta' ou 'dono'
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      pixKey: null, // 1. Adiciona o campo pixKey como nulo no cadastro
    });

    return res.status(201).json({
      message: 'Usuário criado com sucesso!',
      uid: userRecord.uid,
    });

  } catch (error: any) {
    console.error('Erro ao criar usuário:', error);
    if (error.code === 'auth/email-already-exists') {
      return res.status(400).json({ message: 'Este e-mail já está em uso.' });
    }
    return res.status(500).json({ message: 'Ocorreu um erro interno ao criar o usuário.' });
  }
};

// --- NOVA FUNÇÃO (Movida do auth.routes.ts) ---
// GET /auth/me
export const getUserProfile = async (req: Request, res: Response) => {
  try {
    const { uid, email } = req.currentUser!; // Pegamos o UID do usuário verificado pelo middleware

    // Consultamos o documento do usuário no Firestore
    const userDoc = await db.collection('usuarios').doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ message: 'Dados do usuário não encontrados no Firestore.' });
    }
    
    const userData = userDoc.data();

    // Retornamos os dados completos do usuário, incluindo o 'role' e 'pixKey'
    res.status(200).json({
      message: `Usuário ${email} autenticado com sucesso.`,
      user: {
        uid: uid,
        email: email,
        name: userData?.name,
        role: userData?.role,
        pixKey: userData?.pixKey ?? null, // 2. Retorna a chave PIX (se existir)
      },
    });
  } catch (error) {
    console.error('Erro ao buscar dados do usuário:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar perfil do usuário.' });
  }
};

// --- NOVA FUNÇÃO (Para RF10) ---
// PUT /auth/me
export const updateUserProfile = async (req: Request, res: Response) => {
  try {
    const userId = req.currentUser?.uid;
    // 3. Pega 'name' e 'pixKey' do body
    const { name, pixKey } = req.body; 

    if (!userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    const userRef = db.collection('usuarios').doc(userId);

    // 4. Cria um objeto dinâmico apenas com os campos que foram enviados
    const dataToUpdate: { [key: string]: any } = {};

    if (name) {
      dataToUpdate.name = name;
    }
    if (pixKey !== undefined) { // Permite salvar 'null' ou uma string vazia
      dataToUpdate.pixKey = pixKey;
    }

    if (Object.keys(dataToUpdate).length === 0) {
      return res.status(400).json({ message: 'Nenhum dado para atualizar.' });
    }

    // 5. Atualiza o documento no Firestore
    await userRef.update(dataToUpdate);

    // 6. Se o nome foi atualizado, atualiza também no Firebase Auth
    if (name) {
      await admin.auth().updateUser(userId, { displayName: name });
    }

    return res.status(200).json({ message: 'Perfil atualizado com sucesso.' });

  } catch (error) {
    console.error('Erro ao atualizar perfil:', error);
    return res.status(500).json({ message: 'Erro interno ao atualizar perfil.' });
  }
};