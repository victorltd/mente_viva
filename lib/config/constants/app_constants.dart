// lib/config/constants/app_constants.dart

class AppConstants {
  // App Info
  static const String appName = 'MenteViva';
  static const String appTagline = 'Potencialize a jornada terapêutica';
  static const String appVersion = '1.0.0';

  // Roles
  static const String rolePsychologist = 'psychologist';
  static const String rolePatient = 'patient';

  // Emotions
  static const List<Map<String, String>> emotions = [
    {'key': 'ansiedade', 'label': 'Ansiedade', 'emoji': '😰'},
    {'key': 'tristeza', 'label': 'Tristeza', 'emoji': '😢'},
    {'key': 'raiva', 'label': 'Raiva', 'emoji': '😠'},
    {'key': 'medo', 'label': 'Medo', 'emoji': '😨'},
    {'key': 'alegria', 'label': 'Alegria', 'emoji': '😊'},
    {'key': 'calma', 'label': 'Calma', 'emoji': '😌'},
    {'key': 'frustração', 'label': 'Frustração', 'emoji': '😤'},
    {'key': 'confusão', 'label': 'Confusão', 'emoji': '🤔'},
  ];

  // Mood Labels
  static const Map<int, String> moodLabels = {
    1: 'Muito mal',
    2: 'Mal',
    3: 'Mais ou menos',
    4: 'Bem',
    5: 'Muito bem',
  };

  // Mood Emojis
  static const Map<int, String> moodEmojis = {
    1: '😢',
    2: '😟',
    3: '😐',
    4: '🙂',
    5: '😊',
  };

  // Task Types
  static const List<Map<String, String>> taskTypes = [
    {
      'key': 'breathing',
      'label': 'Exercício de Respiração',
      'icon': '🫁',
    },
    {
      'key': 'thought_record',
      'label': 'Registro de Pensamento',
      'icon': '📝',
    },
    {
      'key': 'journaling',
      'label': 'Diário / Journaling',
      'icon': '📓',
    },
    {
      'key': 'mindfulness',
      'label': 'Mindfulness',
      'icon': '🧘',
    },
    {
      'key': 'behavioral',
      'label': 'Atividade Comportamental',
      'icon': '🎯',
    },
    {
      'key': 'custom',
      'label': 'Personalizada',
      'icon': '✨',
    },
  ];

  // Alert Messages
  static const String cvvMessage = 
    'Se você está em crise, ligue para o CVV: 188 '
    '(24h, gratuito)';
}