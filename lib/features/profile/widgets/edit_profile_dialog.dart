import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/models/user_model.dart';

/// Diálogo modal para edição de dados pessoais do perfil (Nome, Bio, Gênero, Idade).
class EditProfileDialog extends StatefulWidget {
  final UserModel user;

  const EditProfileDialog({super.key, required this.user});

  static Future<void> show(BuildContext context, UserModel user) {
    return showDialog<void>(
      context: context,
      builder: (_) => EditProfileDialog(user: user),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _ageController;
  late String _gender;
  bool _saving = false;

  final _genderOptions = ['Masculino', 'Feminino', 'Outro'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _ageController = TextEditingController(
      text: widget.user.age != null ? widget.user.age.toString() : '',
    );
    _gender = _genderOptions.firstWhere(
      (g) => g.toLowerCase() == (widget.user.gender).toLowerCase(),
      orElse: () => 'Masculino',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ageParsed = int.tryParse(_ageController.text.trim());
    final updated = widget.user.copyWith(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      gender: _gender,
      age: ageParsed,
    );

    await context.read<AuthProvider>().updateProfile(updated);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil atualizado com sucesso!'),
        backgroundColor: AppTheme.verde,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131732),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'EDITAR PERFIL',
                    style: TextStyle(
                      color: AppTheme.dourado,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Nome
              const Text('Nome', style: TextStyle(fontSize: 12, color: AppTheme.cinzaMedio)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Seu nome'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
              ),

              const SizedBox(height: 12),

              // Bio
              const Text('Bio / Recado', style: TextStyle(fontSize: 12, color: AppTheme.cinzaMedio)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Conte um pouco sobre você...'),
              ),

              const SizedBox(height: 12),

              // Gênero
              const Text('Gênero', style: TextStyle(fontSize: 12, color: AppTheme.cinzaMedio)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                dropdownColor: const Color(0xFF181C3D),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Selecione seu gênero'),
                items: _genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _gender = val);
                },
              ),

              const SizedBox(height: 12),

              // Idade
              const Text('Idade', style: TextStyle(fontSize: 12, color: AppTheme.cinzaMedio)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Sua idade (opcional)'),
              ),

              const SizedBox(height: 20),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dourado,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Salvar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      filled: true,
      fillColor: const Color(0x661A2045),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.dourado),
      ),
    );
  }
}
