import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/models/user_model.dart';
import 'package:sofia/services/api_client.dart';

/// Abas de conteúdo do perfil: Momentos, Galeria e Sobre.
class ProfileTabs extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onVerifyFace;

  const ProfileTabs({
    super.key,
    required this.user,
    required this.onVerifyFace,
  });

  @override
  State<ProfileTabs> createState() => _ProfileTabsState();
}

class _ProfileTabsState extends State<ProfileTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final user = widget.user;
    if (user == null || _uploadingPhoto) return;
    if (user.gallery.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A galeria permite no máximo 5 fotos.')),
      );
      return;
    }

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploadingPhoto = true);
      final file = File(picked.path);
      final success = await context.read<AuthProvider>().uploadGalleryPhoto(file);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto adicionada à galeria!'),
            backgroundColor: AppTheme.verde,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível enviar a foto ao servidor.'),
            backgroundColor: AppTheme.vermelho,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar foto: $e'),
            backgroundColor: AppTheme.vermelho,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _openPhotoDialog(String photoUrl) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 460),
                  child: _buildImageWidget(photoUrl),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(dialogCtx),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Fechar', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await context.read<AuthProvider>().removeGalleryPhoto(photoUrl);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Foto removida da galeria.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Excluir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0x33FF4444),
                      foregroundColor: const Color(0xFFFF7777),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(String source) {
    // 1. Suporte retrocompatível a base64 se ainda existir alguma antiga
    if (source.startsWith('data:image/')) {
      final comma = source.indexOf(',');
      if (comma >= 0) {
        try {
          return Image.memory(
            base64Decode(source.substring(comma + 1)),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined, color: AppTheme.cinzaMedio),
            ),
          );
        } catch (_) {}
      }
    }

    // 2. URL normal vinda do servidor
    final resolved = ApiClient.resolveUrl(source);
    if (resolved != null && resolved.isNotEmpty) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image_outlined, color: AppTheme.cinzaMedio),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.broken_image_outlined, color: AppTheme.cinzaMedio),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TabBar estético
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          decoration: BoxDecoration(
            color: const Color(0x66151A34),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF381B6D), Color(0xFF1E2856)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dourado.withValues(alpha: 0.5)),
            ),
            labelColor: AppTheme.dourado,
            unselectedLabelColor: AppTheme.cinzaMedio,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(text: 'Momentos'),
              Tab(text: 'Galeria'),
              Tab(text: 'Sobre'),
            ],
          ),
        ),

        // Conteúdo da aba selecionada
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            switch (_tabController.index) {
              case 0:
                return _buildMomentosTab();
              case 1:
                return _buildGaleriaTab();
              case 2:
              default:
                return _buildSobreTab();
            }
          },
        ),
      ],
    );
  }

  Widget _buildMomentosTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x55151A34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.dourado.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.auto_awesome_motion_outlined,
              size: 38,
              color: AppTheme.dourado,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nenhum momento publicado ainda',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Compartilhe suas fotos e reflexões com a comunidade SOFIA na aba Momentos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.cinzaMedio,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaleriaTab() {
    final gallery = widget.user?.gallery ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'FOTOS DO PERFIL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: AppTheme.cinzaMedio,
                ),
              ),
              const Spacer(),
              Text(
                '${gallery.length}/5 fotos',
                style: const TextStyle(fontSize: 11, color: AppTheme.dourado),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gallery.length + (gallery.length < 5 ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index >= gallery.length) {
                // Card de adicionar nova foto
                return InkWell(
                  onTap: _uploadingPhoto ? null : _addPhoto,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.roxo.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.dourado.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: _uploadingPhoto
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.dourado,
                              ),
                            )
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppTheme.dourado,
                                  size: 26,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Adicionar',
                                  style: TextStyle(fontSize: 11, color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              }

              final photo = gallery[index];
              return GestureDetector(
                onTap: () => _openPhotoDialog(photo),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: const Color(0xFF14182E),
                    child: _buildImageWidget(photo),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSobreTab() {
    final user = widget.user;
    final fmt = DateFormat('dd/MM/yyyy');
    final createdAtStr = user != null ? fmt.format(user.createdAt) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x66151A34),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BIO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dourado,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (user?.bio != null && user!.bio!.isNotEmpty)
                      ? user.bio!
                      : 'Nenhuma bio informada. Toque em Editar Perfil para adicionar.',
                  style: TextStyle(
                    fontSize: 13,
                    color: (user?.bio != null && user!.bio!.isNotEmpty)
                        ? Colors.white
                        : AppTheme.cinzaMedio,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tabela de Dados
          _infoTile(Icons.calendar_today_rounded, 'Membro desde', createdAtStr),
          _infoTile(Icons.wc_rounded, 'Gênero', user?.gender ?? '—'),
          _infoTile(
            Icons.cake_outlined,
            'Idade',
            user?.age != null ? '${user!.age} anos' : 'Não informada',
          ),
          _infoTile(Icons.public_rounded, 'Região', user?.region ?? 'América do Sul'),
          _infoTile(
            Icons.auto_awesome,
            'Nível de riqueza',
            user?.wealthLevel ?? user?.levelTitle ?? 'Nível ${user?.level ?? 1}',
          ),
          _infoTile(
            Icons.favorite_rounded,
            'Carisma',
            '${user?.charmLevel ?? user?.points ?? 0} pontos',
          ),
          _infoTile(
            Icons.face_retouching_natural_rounded,
            'Verificação Facial',
            'Confirmar identidade com a câmera',
            onTap: widget.onVerifyFace,
            trailingIcon: Icons.arrow_forward_ios_rounded,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    IconData? trailingIcon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0x66151A34),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppTheme.dourado, size: 20),
        title: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.cinzaMedio),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        trailing: trailingIcon != null
            ? Icon(trailingIcon, size: 14, color: AppTheme.dourado)
            : null,
        onTap: onTap,
      ),
    );
  }
}
