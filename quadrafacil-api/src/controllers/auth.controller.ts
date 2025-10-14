// src/controllers/auth.controller.ts

import { Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from '../config/firebase'; // Nossa conexão com o Firestore

// A função 'registerUser' agora se comunicará com o Firebase
export const registerUser = async (req: Request, res: Response) => {
  try {
    // 1. Pegamos os dados do corpo da requisição
    const { name, email, password, role } = req.body;

    // Validação simples dos dados recebidos
    if (!email || !password || !name || !role) {
      return res.status(400).json({ message: 'Todos os campos são obrigatórios.' });
    }

    // 2. Usamos o Firebase Admin para criar o usuário no Authentication
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    // 3. Salvamos os dados complementares (como o 'role') no Firestore
    // O 'doc(userRecord.uid)' garante que o documento no Firestore tenha o mesmo ID do usuário na autenticação
    await db.collection('usuarios').doc(userRecord.uid).set({
      name: name,
      email: email,
      role: role, // 'atleta' ou 'dono'
      createdAt: admin.firestore.FieldValue.serverTimestamp(), // Salva a data de criação
    });

    // 4. Retornamos uma resposta de sucesso
    return res.status(201).json({
      message: 'Usuário criado com sucesso!',
      uid: userRecord.uid,
    });

  } catch (error: any) {
    // Tratamento de erros comuns, como e-mail já existente
    console.error('Erro ao criar usuário:', error);
    if (error.code === 'auth/email-already-exists') {
      return res.status(400).json({ message: 'Este e-mail já está em uso.' });
    }
    return res.status(500).json({ message: 'Ocorreu um erro interno ao criar o usuário.' });
  }
};