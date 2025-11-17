// lib/core/config.dart

// Importamos a biblioteca foundation para detectar a plataforma
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Seu IP local - MANTENHA ATUALIZADO!
  static const String _localIp = '192.168.0.5'; 
  
  // Porta da sua API
  static const String _port = '3000';

  // Escolhe o host correto baseado na plataforma
  static String get _host {
    // kIsWeb é true se estiver rodando no navegador
    if (kIsWeb) {
      return 'localhost';
    } else {
      // Para Android/iOS (ou desktop nativo), usamos o IP local
      return _localIp;
    }
  }

  // A URL base completa da API
  static String get apiUrl => 'http://$_host:$_port'; 
}