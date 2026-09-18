import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sofia/core/themes/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _autoDark = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('settings_notifications') ?? true;
      _autoDark = prefs.getBool('settings_auto_dark') ?? true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notificações'),
            subtitle: const Text('Receber alertas de salas e eventos'),
            value: _notifications,
            activeTrackColor: AppTheme.roxo.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.dourado,
            onChanged: (v) {
              setState(() => _notifications = v);
              _save('settings_notifications', v);
            },
          ),
          SwitchListTile(
            title: const Text('Modo escuro automático'),
            subtitle: const Text('Ajusta conforme o horário'),
            value: _autoDark,
            activeTrackColor: AppTheme.roxo.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.dourado,
            onChanged: (v) {
              setState(() => _autoDark = v);
              _save('settings_auto_dark', v);
            },
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacidade'),
            subtitle: Text('Quem pode ver seu perfil'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}
