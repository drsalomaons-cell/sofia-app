import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/providers/room_provider.dart';
import 'package:sofia/routes/app_routes.dart';
import 'package:sofia/widgets/room/sofia_seats_layout.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedTheme;
  int _chairs = 8;
  bool _isPrivate = false;
  bool _allowGuests = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _themes = ['Festa', 'Conversa', 'Música', 'Jogos', 'Networking', 'Outro'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTheme == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um tema'), backgroundColor: AppTheme.vermelho),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final ok = await context.read<RoomProvider>().createRoom(
          name: _nameController.text,
          description: _descriptionController.text,
          theme: _selectedTheme!,
          chairs: _chairs,
          hostId: user.id,
          hostName: user.name,
          isPrivate: _isPrivate,
          allowGuests: _allowGuests,
          region: user.region,
        );

    if (!mounted) return;
    if (ok) {
      final room = context.read<RoomProvider>().rooms.first;
      Navigator.pushReplacementNamed(context, AppRoutes.room, arguments: {
        'id': room.id,
        'name': room.name,
        'theme': room.theme,
        'spectators': '${room.currentUsers}',
        'chairs': '${room.chairs}',
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<RoomProvider>().errorMessage ?? 'Erro ao criar sala'), backgroundColor: AppTheme.vermelho),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sala'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Capa da sala
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradienteRoxoDourado,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.image,
                    size: 80,
                    color: AppTheme.branco,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Informações da Sala',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.preto,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Sala',
                    hintText: 'Ex: Festa na Praia',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite o nome da sala';
                    }
                    if (value.length < 3) {
                      return 'Nome muito curto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Descreva sua sala...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite uma descrição';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTheme,
                  decoration: const InputDecoration(
                    labelText: 'Tema',
                    prefixIcon: Icon(Icons.palette_outlined),
                  ),
                  items: _themes.map((theme) {
                    return DropdownMenuItem(
                      value: theme,
                      child: Text(theme),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione um tema';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.preto,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Cadeiras', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SofiaSeatsLayout.chairPresets.map((n) {
                    final selected = _chairs == n;
                    return ChoiceChip(
                      label: Text('$n'),
                      selected: selected,
                      selectedColor: AppTheme.dourado,
                      labelStyle: TextStyle(color: selected ? AppTheme.preto : AppTheme.branco, fontWeight: FontWeight.bold),
                      backgroundColor: AppTheme.roxo,
                      onSelected: (_) => setState(() => _chairs = n),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text('Trono + ${ _chairs - 1 } convidados', style: const TextStyle(fontSize: 12, color: AppTheme.cinzaMedio)),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Sala Privada'),
                  subtitle: const Text('Apenas convidados podem entrar'),
                  value: _isPrivate,
                  activeTrackColor: AppTheme.roxo.withValues(alpha: 0.5),
                  activeThumbColor: AppTheme.dourado,
                  onChanged: (value) {
                    setState(() {
                      _isPrivate = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Permitir Convidados'),
                  subtitle: const Text('Qualquer pessoa pode participar'),
                  value: _allowGuests,
                  activeTrackColor: AppTheme.roxo.withValues(alpha: 0.5),
                  activeThumbColor: AppTheme.dourado,
                  onChanged: (value) {
                    setState(() {
                      _allowGuests = value;
                    });
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.roxo,
                      foregroundColor: AppTheme.branco,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'CRIAR SALA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}