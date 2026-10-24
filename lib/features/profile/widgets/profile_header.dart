import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/widgets/frame_avatar.dart';

/// Cabeçalho do perfil com Avatar sobreposto à capa, nome, ID, nível e selos.
class ProfileHeader extends StatefulWidget {
  final VoidCallback? onFrameTap;

  const ProfileHeader({super.key, this.onFrameTap});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  bool _uploadingAvatar = false;

  String _publicIdFor(String internalId) {
    if (internalId.isEmpty) return '000000000';
    final digest = sha256.convert(utf8.encode(internalId)).toString();
    final numeric = int.parse(digest.substring(0, 12), radix: 16) % 1000000000;
    return numeric.toString().padLeft(9, '0');
  }

  String _tenureMedalFor(DateTime? createdAt) {
    if (createdAt == null) return '🌱 Novo';
    final days = DateTime.now().difference(createdAt).inDays;
    if (days >= 365) return '🏆 Veterano 1 ano';
    if (days >= 180) return '⭐ 6 meses';
    if (days >= 30) return '🎖️ 30 dias';
    return '🌱 Novo membro';
  }

  Future<void> _copyId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID copiado para a área de transferência!'),
          backgroundColor: AppTheme.verde,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
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
              leading: const Icon(Icons.camera_front_outlined, color: AppTheme.dourado),
              title: const Text('Tirar foto com câmera frontal', style: TextStyle(color: Colors.white)),
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
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 88,
        maxWidth: 1000,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploadingAvatar = true);
      final file = File(picked.path);
      final success = await context.read<AuthProvider>().uploadAvatar(file);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil atualizada no servidor!'),
            backgroundColor: AppTheme.verde,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao enviar foto ao servidor.'),
            backgroundColor: AppTheme.vermelho,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar foto: $e'),
            backgroundColor: AppTheme.vermelho,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final displayName = user?.name ?? 'Visitante';
    final nickname = (user != null && user.email.isNotEmpty)
        ? '@${user.email.split('@').first}'
        : '@usuario';
    final publicId = user != null ? _publicIdFor(user.id) : '000000000';

    return Transform.translate(
      offset: const Offset(0, -56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // 1. Avatar com FrameAvatar sobreposto à capa
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                FrameAvatar(
                  frameId: user?.effectiveFrameId,
                  gender: user?.gender,
                  photoUrl: user?.photoUrl,
                  name: displayName,
                  size: FrameAvatarSize.large,
                  showPlaque: true,
                  onTap: widget.onFrameTap,
                ),

                // Botão de alterar foto do perfil
                Positioned(
                  bottom: 12,
                  right: 4,
                  child: GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.dourado,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF080A1A), width: 2),
                      ),
                      child: _uploadingAvatar
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.black,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Nome de exibição com selo oficial/verificado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user?.isAdmin == true || user?.isRegionalAdmin == true) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF31D7FF),
                    size: 20,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 3),

            // 3. @handle e ID com clique para copiar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    color: AppTheme.cinzaMedio,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _copyId(publicId),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ID: $publicId',
                          style: const TextStyle(
                            color: AppTheme.dourado,
                            letterSpacing: 0.8,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 11,
                          color: AppTheme.dourado,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 4. Badges em destaque: Nível, VIP, Sexo, Idade, Medalha
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _badgeChip(
                  label: 'Lv. ${user?.level ?? 1}',
                  color: const Color(0xFFFFD76A),
                  icon: Icons.flash_on_rounded,
                ),
                if (user?.vipTag != null && user!.vipTag!.isNotEmpty)
                  _badgeChip(
                    label: user.vipTag!,
                    color: const Color(0xFFFF76C8),
                    icon: Icons.diamond_rounded,
                  ),
                _badgeChip(
                  label: user?.gender ?? '—',
                  color: const Color(0xFF31D7FF),
                  icon: Icons.person_outline_rounded,
                ),
                if (user?.age != null)
                  _badgeChip(
                    label: '${user!.age} anos',
                    color: const Color(0xFFB98AFF),
                    icon: Icons.cake_outlined,
                  ),
                _badgeChip(
                  label: _tenureMedalFor(user?.createdAt),
                  color: const Color(0xFF61E6B5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeChip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
