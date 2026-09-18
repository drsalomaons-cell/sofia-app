import 'package:sofia/models/room_model.dart';
import 'package:sofia/services/api_client.dart';

class AIService {
  // Simulação de Inteligência Artificial
  Future<List<RoomModel>> suggestRooms(String userId, String userGender, String interestedIn) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // IA sugere salas baseadas no perfil do usuário
    final allRooms = await _getAllRooms();
    
    // Filtra e ranqueia salas baseadas em preferências
    final suggestions = allRooms.where((room) {
      // Lógica de recomendação baseada em gênero e interesse
      return room.currentUsers < room.chairs && room.isActive;
    }).toList();
    
    return suggestions.take(5).toList();
  }

  Future<bool> moderateContent(String content, {String region = 'Global'}) async {
    final data = await ApiClient.post('/api/moderation/check', {'text': content, 'region': region});
    if (data != null) return data['allowed'] == true;

    const forbiddenWords = ['palavrão', 'ofensa', 'discriminação', 'racismo'];
    final lower = content.toLowerCase();
    for (final word in forbiddenWords) {
      if (lower.contains(word)) return false;
    }
    return true;
  }

  Future<String> detectInappropriateContent(String content) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulação de detecção de conteúdo inadequado
    if (content.contains('http') || content.contains('www.')) {
      return 'link';
    }
    
    if (content.length > 500) {
      return 'spam';
    }
    
    return 'none';
  }

  Future<String> translateMessage(String message, String fromLanguage, String toLanguage) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Simulação de tradução automática
    // Em produção, usar API como Google Translate ou DeepL
    return '[Traduzido] $message';
  }

  Future<Map<String, dynamic>> analyzeUserBehavior(String userId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // IA analisa comportamento do usuário
    return {
      'engagement': 0.85,
      'activityLevel': 'high',
      'preferredThemes': ['Festa', 'Música', 'Conversa'],
      'bestTimeToPost': '20:00 - 23:00',
      'suggestedActions': [
        'Participe de mais salas de música',
        'Convide amigos para aumentar ganhos',
        'Complete seu perfil para mais visibilidade',
      ],
    };
  }

  Future<int> calculateUserLevel(int points) async {
    // Sistema de níveis baseado em pontos
    if (points >= 10000) return 10;
    if (points >= 5000) return 8;
    if (points >= 2500) return 6;
    if (points >= 1000) return 4;
    if (points >= 500) return 3;
    if (points >= 100) return 2;
    return 1;
  }

  Future<Map<String, int>> calculateRanking() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulação de ranking global
    return {
      '1': 15000,
      '2': 12500,
      '3': 10000,
      '4': 8500,
      '5': 7000,
    };
  }

  Future<List<String>> getSuggestedTasks(String userGender, String userLevel) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // IA sugere tarefas baseadas no perfil
    if (userGender == 'Masculino') {
      return [
        'Indique 3 mulheres para a plataforma',
        'Participe de 5 salas esta semana',
        'Crie uma sala com tema Festa',
      ];
    } else {
      return [
        'Indique 3 homens para a plataforma',
        'Participe de 5 lives esta semana',
        'Compartilhe 2 eventos',
      ];
    }
  }

  Future<List<RoomModel>> _getAllRooms() async {
    // Simula busca de todas as salas
    return [
      RoomModel(
        id: '1',
        name: 'Festa na Praia',
        description: 'Venha curtir uma festa incrível!',
        theme: 'Festa',
        chairs: 20,
        currentUsers: 12,
        hostId: '1',
        hostName: 'João',
        participants: ['1', '2', '3'],
        earnings: 150.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RoomModel(
        id: '2',
        name: 'Conversa sobre Tecnologia',
        description: 'Discussões sobre as últimas novidades em tech',
        theme: 'Conversa',
        chairs: 15,
        currentUsers: 8,
        hostId: '2',
        hostName: 'Maria',
        participants: ['1', '2', '3', '4'],
        earnings: 80.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      RoomModel(
        id: '3',
        name: 'Noite de Música',
        description: 'Música ao vivo e boa conversa',
        theme: 'Música',
        chairs: 30,
        currentUsers: 25,
        hostId: '3',
        hostName: 'Pedro',
        participants: ['1', '2', '3', '4', '5'],
        earnings: 200.0,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }
}