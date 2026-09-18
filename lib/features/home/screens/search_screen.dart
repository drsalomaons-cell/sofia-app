import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/routes/app_routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  List<int> _results = List.generate(10, (i) => i);

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = List.generate(10, (i) => i);
      } else {
        _results = List.generate(10, (i) => i)
            .where((i) => 'Sala ${i + 1}'.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar salas...',
            border: InputBorder.none,
          ),
          onChanged: _filter,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final roomIndex = _results[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.meeting_room, color: AppTheme.roxo),
              title: Text('Sala ${roomIndex + 1}'),
              subtitle: const Text('Tema da sala'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.room,
                arguments: {
                  'name': 'Sala ${roomIndex + 1}',
                  'theme': 'Tema da sala',
                  'spectators': '${10 + roomIndex * 3}',
                  'chairs': '12',
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
