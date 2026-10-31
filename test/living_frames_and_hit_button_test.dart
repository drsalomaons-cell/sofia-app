import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia/core/frames/living_frame_spec.dart';
import 'package:sofia/widgets/living_frame_avatar.dart';
import 'package:sofia/widgets/lucky_hit_button.dart';

void main() {
  group('Biblioteca de molduras com vida', () {
    test('tem pelo menos 100 molduras e ids únicos', () {
      final all = LivingFrameLibrary.all;
      expect(all.length, greaterThanOrEqualTo(100));
      expect(all.map((f) => f.id).toSet().length, all.length);
    });

    test('toda função tem moldura e a plaqueta tem o nome certo', () {
      for (final role in FrameRole.values) {
        expect(LivingFrameLibrary.byRole(role), isNotEmpty);
      }
      expect(FrameRole.adminOfficial.label, 'ADM OFICIAL');
      expect(FrameRole.superAdmin.label, 'SUPER ADM');
      expect(FrameRole.bd.label, 'BD');
    });

    test('molduras épicas têm efeito de raio, fogo ou asas', () {
      final epic = LivingFrameLibrary.byTier(FrameTier.epic);
      expect(epic, isNotEmpty);
      for (final f in epic) {
        expect(
          [FrameEffect.lightning, FrameEffect.fire, FrameEffect.wings]
              .contains(f.effect),
          isTrue,
        );
      }
    });

    testWidgets('avatar mostra a plaqueta com o nome da função', (tester) async {
      final spec = LivingFrameLibrary.all.firstWhere(
        (f) => f.role == FrameRole.superAdmin && f.effect == FrameEffect.wings,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LivingFrameAvatar(
                spec: spec,
                photo: const ColoredBox(color: Colors.grey),
                animate: false,
              ),
            ),
          ),
        ),
      );
      expect(find.text('SUPER ADM'), findsOneWidget);
    });
  });

  group('Botão de bater', () {
    testWidgets('desconta na hora e confirma o saldo do servidor',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LuckyHitButton(
                balance: 1000,
                cost: 50,
                onHit: () async =>
                    const LuckyHitResult(balanceAfter: 970, returnedCoins: 20),
              ),
            ),
          ),
        ),
      );
      expect(find.text('1.000'), findsOneWidget);
      await tester.tap(find.text('BATER'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('970'), findsOneWidget);
      expect(find.text('x1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sem saldo o botão não bate', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LuckyHitButton(
                balance: 10,
                cost: 50,
                onHit: () async {
                  calls++;
                  return const LuckyHitResult(balanceAfter: 0, returnedCoins: 0);
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('BATER'));
      await tester.pump();
      expect(calls, 0);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
