import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia/core/frames/frame_catalog.dart';
import 'package:sofia/models/user_model.dart';
import 'package:sofia/widgets/frame_avatar.dart';

void main() {
  group('FrameCatalog tests', () {
    test('Catálogo contém exatamente 14 molduras (7 tipos x 2 estilos)', () {
      expect(FrameCatalog.allFrames.length, 14);

      final byType = FrameCatalog.byType();
      expect(byType.keys.length, 7);

      for (final type in FrameType.values) {
        final frames = byType[type]!;
        expect(frames.length, 2);
        expect(frames.any((f) => f.style == FrameStyle.a), isTrue);
        expect(frames.any((f) => f.style == FrameStyle.b), isTrue);
      }
    });

    test('IDs são únicos e seguem o padrão <tipo>_<estilo>', () {
      final ids = FrameCatalog.allFrames.map((f) => f.id).toSet();
      expect(ids.length, 14);
      expect(ids.contains('baby_a'), isTrue);
      expect(ids.contains('baby_b'), isTrue);
      expect(ids.contains('official_a'), isTrue);
      expect(ids.contains('official_b'), isTrue);
      expect(ids.contains('official_admin_a'), isTrue);
      expect(ids.contains('official_admin_b'), isTrue);
      expect(ids.contains('room_a'), isTrue);
      expect(ids.contains('room_b'), isTrue);
      expect(ids.contains('face_a'), isTrue);
      expect(ids.contains('face_b'), isTrue);
      expect(ids.contains('host_a'), isTrue);
      expect(ids.contains('host_b'), isTrue);
      expect(ids.contains('vip_a'), isTrue);
      expect(ids.contains('vip_b'), isTrue);
    });

    test('Paletas por gênero retornam variantes distintas', () {
      final frame = FrameCatalog.officialAdminA;
      final malePalette = frame.getPalette('Masculino');
      final femalePalette = frame.getPalette('Feminino');
      final unisexPalette = frame.getPalette('Outro');

      expect(malePalette.borderGradient, isNot(equals(femalePalette.borderGradient)));
      expect(malePalette.glowColor, isNot(equals(femalePalette.glowColor)));
      expect(unisexPalette, isNotNull);
    });

    test('Mapeamento de compatibilidade de nomes legados', () {
      expect(FrameCatalog.normalizeFrameId('bronze'), 'host_a');
      expect(FrameCatalog.normalizeFrameId('silver'), 'official_a');
      expect(FrameCatalog.normalizeFrameId('gold'), 'official_admin_a');
      expect(FrameCatalog.normalizeFrameId('platinum'), 'vip_a');
      expect(FrameCatalog.normalizeFrameId('diamond'), 'vip_b');
      expect(FrameCatalog.normalizeFrameId('host1'), 'host_a');
      expect(FrameCatalog.normalizeFrameId('host2'), 'host_b');
      expect(FrameCatalog.normalizeFrameId('oficial1'), 'official_a');
      expect(FrameCatalog.normalizeFrameId('oficial4'), 'official_admin_a');
      expect(FrameCatalog.normalizeFrameId(null), 'host_a');
    });

    test('FrameCatalog.resolve sempre retorna frame e palette válidos', () {
      final res = FrameCatalog.resolve('qualquer_coisa_invalida', gender: 'Feminino');
      expect(res.frame, isNotNull);
      expect(res.palette, isNotNull);
    });
  });

  group('UserModel Fase 1 tests', () {
    test('UserModel serializa e desserializa coverUrl e frameId', () {
      final json = {
        'id': 'test-123',
        'name': 'Sofia Test',
        'email': 'test@sofia.app',
        'phone': '11999999999',
        'gender': 'Feminino',
        'interestedIn': 'Todos',
        'cover_url': 'https://sofia.app/cover.jpg',
        'frame_id': 'official_admin_b',
        'bio': 'Desenvolvedor SOFIA',
        'createdAt': '2026-10-24T12:00:00Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.coverUrl, 'https://sofia.app/cover.jpg');
      expect(user.frameId, 'official_admin_b');
      expect(user.effectiveFrameId, 'official_admin_b');
      expect(user.bio, 'Desenvolvedor SOFIA');

      final serialized = user.toJson();
      expect(serialized['coverUrl'], 'https://sofia.app/cover.jpg');
      expect(serialized['frameId'], 'official_admin_b');
      expect(serialized['bio'], 'Desenvolvedor SOFIA');
    });
  });

  group('FrameAvatar widget tests', () {
    testWidgets('FrameAvatar renderiza corretamente com plaqueta e fallback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FrameAvatar(
                frameId: 'official_admin_a',
                gender: 'Feminino',
                name: 'Sofia Silva',
                size: FrameAvatarSize.large,
                animate: false,
              ),
            ),
          ),
        ),
      );

      // Encontra a inicial 'S' do nome
      expect(find.text('S'), findsOneWidget);
      // Encontra a plaqueta 'ADM OFICIAL'
      expect(find.text('ADM OFICIAL'), findsOneWidget);
    });
  });
}
