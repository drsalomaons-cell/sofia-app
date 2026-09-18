import 'package:flutter/material.dart';
import 'package:sofia/features/auth/screens/splash_screen.dart';
import 'package:sofia/features/auth/screens/login_screen.dart';
import 'package:sofia/features/auth/screens/register_screen.dart';
import 'package:sofia/features/home/screens/home_screen.dart';
import 'package:sofia/features/home/screens/search_screen.dart';
import 'package:sofia/features/wallet/screens/wallet_screen.dart';
import 'package:sofia/features/rooms/screens/create_room_screen.dart';
import 'package:sofia/features/rooms/screens/room_screen.dart';
import 'package:sofia/features/admin/screens/admin_screen.dart';
import 'package:sofia/features/profile/screens/settings_screen.dart';
import 'package:sofia/features/profile/screens/referrals_screen.dart';
import 'package:sofia/features/profile/screens/language_screen.dart';
import 'package:sofia/features/events/screens/event_detail_screen.dart';
import 'package:sofia/features/events/screens/country_rooms_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String wallet = '/wallet';
  static const String createRoom = '/create-room';
  static const String room = '/room';
  static const String admin = '/admin';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String referrals = '/referrals';
  static const String language = '/language';
  static const String eventDetail = '/event-detail';
  static const String countryRooms = '/country-rooms';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case wallet:
        return MaterialPageRoute(builder: (_) => const WalletScreen());
      case createRoom:
        return MaterialPageRoute(builder: (_) => const CreateRoomScreen());
      case room:
        final args = routeSettings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => RoomScreen(
            roomId: args['id'],
            roomName: args['name']!,
            roomTheme: args['theme']!,
            spectatorCount: int.tryParse(args['spectators'] ?? '12') ?? 12,
            chairCount: int.tryParse(args['chairs'] ?? '12') ?? 12,
          ),
        );
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminScreen());
      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case referrals:
        return MaterialPageRoute(builder: (_) => const ReferralsScreen());
      case language:
        return MaterialPageRoute(builder: (_) => const LanguageScreen());
      case eventDetail:
        final args = routeSettings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            title: args['title'] as String,
            date: args['date'] as String,
            participants: args['participants'] as int,
          ),
        );
      case countryRooms:
        final args = routeSettings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => CountryRoomsScreen(country: args['country']!),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Rota não encontrada: ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
