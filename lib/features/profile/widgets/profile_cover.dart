import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/services/api_client.dart';

/// Capa superior do perfil com suporte a imagem do usuário ou gradiente padrão.
class ProfileCover extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileCover({super.key, this.onLogout});

  @override
  State<ProfileCover> createState() => _ProfileCoverState();
}

class _ProfileCoverState extends State<ProfileCover> {
  bool _uploading = false;

  Future<void> _pickCover() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleção de foto disponível no app mobile')),
      );
      return;
    }

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF161936),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.dourado),
              title: const Text('Escolher da galeria', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.dourado),
              title: const Text('Tirar foto com câmera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploading = true);
      final file = File(picked.path);
      final success = await context.read<AuthProvider>().uploadCover(file);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capa do perfil atualizada com sucesso!'),
            backgroundColor: AppTheme.verde,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar a capa no servidor.'),
            backgroundColor: AppTheme.vermelho,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar capa: $e'),
            backgroundColor: AppTheme.vermelho,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final coverUrl = ApiClient.resolveUrl(user?.coverUrl);

    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagem de capa ou gradiente cósmico padrão
          if (coverUrl != null && coverUrl.isNotEmpty)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _defaultCoverGradient(),
            )
          else
            _defaultCoverGradient(),

          // 2. Sobreposição com sombreado inferior suave
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Colors.transparent,
                  Color(0xDD080A1A),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Botão de logout no canto superior direito
          if (widget.onLogout != null)
            Positioned(
              top: 14,
              right: 14,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  tooltip: 'Sair da conta',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFFF7777),
                    size: 20,
                  ),
                  onPressed: widget.onLogout,
                ),
              ),
            ),

          // 4. Botão "Editar Capa" no canto inferior direito
          Positioned(
            bottom: 14,
            right: 14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _uploading ? null : _pickCover,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.dourado.withValues(alpha: 0.65),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_uploading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.dourado,
                          ),
                        )
                      else
                        const Icon(
                          Icons.camera_alt_outlined,
                          size: 15,
                          color: AppTheme.dourado,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _uploading ? 'Salvando...' : 'Editar Capa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultCoverGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF240046),
            Color(0xFF10002B),
            Color(0xFF03071E),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B2CBF).withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
