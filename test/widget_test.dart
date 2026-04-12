// Teste básico do MenteViva - sem dependência de Supabase
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:menteviva/config/constants/app_constants.dart';

/// Test básico das constantes do app
/// (Não requer Supabase inicializado)
void main() {
  group('AppConstants', () {
    test('appName deve ser definido', () {
      expect(AppConstants.appName, isNotEmpty);
      expect(AppConstants.appName, 'MenteViva');
    });

    test('moodEmojis deve ter 5 níveis', () {
      expect(AppConstants.moodEmojis.length, 5);
    });

    test('emotions deve ter entries', () {
      expect(AppConstants.emotions.length, greaterThan(0));
    });
  });

  // Test visual simples sem dependências
  testWidgets('MaterialApp renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: Center(
            child: Text('MenteViva Test'),
          ),
        ),
      ),
    );

    expect(find.text('MenteViva Test'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
