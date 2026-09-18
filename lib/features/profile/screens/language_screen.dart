import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sofia/core/themes/app_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'pt-BR';

  final _languages = const [
    ('pt-BR', 'Português (Brasil)'),
    ('en-US', 'English (US)'),
    ('es-ES', 'Español'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selected = prefs.getString('app_language') ?? 'pt-BR');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Idioma')),
      body: ListView(
        children: _languages.map((lang) {
          return ListTile(
            title: Text(lang.$2),
            leading: Radio<String>(
              value: lang.$1,
              groupValue: _selected,
              activeColor: AppTheme.roxo,
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _selected = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('app_language', value);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Idioma alterado para ${lang.$2}')),
                  );
                }
              },
            ),
            onTap: () async {
              setState(() => _selected = lang.$1);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('app_language', lang.$1);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Idioma alterado para ${lang.$2}')),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
