import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/features/profile/widgets/edit_profile_dialog.dart';
import 'package:sofia/features/profile/widgets/frame_selector_sheet.dart';
import 'package:sofia/features/profile/widgets/profile_cover.dart';
import 'package:sofia/features/profile/widgets/profile_header.dart';
import 'package:sofia/features/profile/widgets/profile_shortcuts.dart';
import 'package:sofia/features/profile/widgets/profile_stats_bar.dart';
import 'package:sofia/features/profile/widgets/profile_tabs.dart';
import 'package:sofia/routes/app_routes.dart';
import 'package:sofia/services/face_recognition_service.dart';

/// Tela principal do Perfil do usuário SOFIA.
class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final bool showAppBar;

  const ProfileScreen({
    super.key,
    required this.onLogout,
    this.showAppBar = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _verifyFace() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificação facial disponível no aplicativo mobile')),
      );
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => _FaceCaptureScreen(camera: frontCamera),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir a câmera frontal: $e'),
            backgroundColor: AppTheme.vermelho,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFF080A1A),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Meu Perfil'),
              elevation: 0,
              backgroundColor: const Color(0xFF080A1A),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                ),
              ],
            )
          : null,
      body: RefreshIndicator(
        color: AppTheme.dourado,
        onRefresh: () => context.read<AuthProvider>().restoreSession(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 1. Capa no topo com botão editar capa
              ProfileCover(onLogout: widget.onLogout),

              // 2. Avatar com FrameAvatar sobreposto à capa, nome, ID, badges
              ProfileHeader(
                onFrameTap: () => FrameSelectorSheet.show(context),
              ),

              // 3. Contadores (seguidores, seguindo, visitas) e botão editar perfil
              ProfileStatsBar(
                user: user,
                isSelf: true,
                onEditProfile: () {
                  if (user != null) {
                    EditProfileDialog.show(context, user);
                  }
                },
              ),

              const SizedBox(height: 16),

              // 4. Atalhos de seção (Carteira com saldos, Charme, Molduras, Configurações, Sobre nós)
              const ProfileShortcuts(),

              const SizedBox(height: 8),

              // 5. Abas com conteúdo real: Momentos, Galeria sem base64, Sobre
              ProfileTabs(
                user: user,
                onVerifyFace: _verifyFace,
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tela de captura de câmera para verificação biométrica.
class _FaceCaptureScreen extends StatefulWidget {
  final CameraDescription camera;

  const _FaceCaptureScreen({required this.camera});

  @override
  State<_FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<_FaceCaptureScreen> {
  CameraController? _controller;
  bool _verified = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _verify() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _checking) return;

    setState(() => _checking = true);
    try {
      final picture = await controller.takePicture();
      final faceService = FaceRecognitionService();
      final detected = await faceService.detectFaceFromFile(picture.path);

      if (!mounted) return;
      setState(() {
        _verified = detected;
        _checking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            faceService.errorMessage ??
                (detected ? 'Rosto verificado com sucesso!' : 'Rosto não identificado.'),
          ),
          backgroundColor: detected ? AppTheme.verde : AppTheme.vermelho,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao capturar rosto: $e'),
          backgroundColor: AppTheme.vermelho,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificação Facial')),
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: AppTheme.dourado))
          : Column(
              children: [
                Expanded(child: CameraPreview(_controller!)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _checking ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dourado,
                      foregroundColor: AppTheme.preto,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _checking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(_verified ? 'Verificado ✓' : 'Verificar rosto'),
                  ),
                ),
              ],
            ),
    );
  }
}
