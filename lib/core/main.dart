import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/routes/app_routes.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/providers/room_provider.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/services/media_service.dart';
import 'package:sofia/services/face_recognition_service.dart';
import 'package:sofia/services/branding_service.dart';
import 'package:sofia/services/socket_service.dart';
import 'package:sofia/widgets/sofia_mobile_shell.dart';
import 'package:sofia/services/screen_protect_service.dart';
import 'package:sofia/features/sunlight/services/sofia_gift_effect_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await ScreenProtectService.enable();
}

class SofiaApp extends StatefulWidget {
  const SofiaApp({super.key});

  @override
  State<SofiaApp> createState() => _SofiaAppState();
}

class _SofiaAppState extends State<SofiaApp> {
  late final BrandingService _brandingService;

  @override
  void initState() {
    super.initState();
    _brandingService = BrandingService();
    _brandingService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => MediaService()),
        ChangeNotifierProvider(create: (_) => FaceRecognitionService()),
        ChangeNotifierProvider(create: (_) => SocketService()),
        ChangeNotifierProvider(create: (_) => SofiaGiftEffectService()),
        ChangeNotifierProvider.value(value: _brandingService),
      ],
      child: Consumer2<BrandingService, AuthProvider>(
        builder: (context, branding, auth, _) {
          if (auth.isAuthenticated && auth.user != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final wallet = context.read<WalletProvider>();
              if (wallet.user?.id != auth.user!.id) {
                wallet.setUser(auth.user!);
              }
            });
          }
          final coverId = branding.activeCoverId;
          return MaterialApp(
            title: dotenv.env['APP_NOME'] ?? 'SOFIA',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeForCover(coverId, isDark: false),
            darkTheme: AppTheme.themeForCover(coverId, isDark: true),
            themeMode: ThemeMode.system,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            builder: (context, child) {
              return SofiaMobileShell(child: child ?? const SizedBox());
            },
          );
        },
      ),
    );
  }
}
