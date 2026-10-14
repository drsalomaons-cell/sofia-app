import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/routes/app_routes.dart';
import 'package:sofia/services/face_recognition_service.dart';
import 'package:sofia/widgets/sofia_user_badge.dart';
import 'package:camera/camera.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedPhoto());
  }

  Future<void> _loadSavedPhoto() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('sofia_profile_photo_$userId');
    if (saved != null && await File(saved).exists() && mounted) {
      setState(() => _localPhotoPath = saved);
    }
  }

  Future<void> _saveProfilePhoto(String sourcePath) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final extension = sourcePath.contains('.')
        ? sourcePath.split('.').last.toLowerCase()
        : 'jpg';
    final destination = '${directory.path}/sofia_profile_${_publicIdFor(userId)}.$extension';
    final savedFile = await File(sourcePath).copy(destination);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sofia_profile_photo_$userId', savedFile.path);
    if (mounted) setState(() => _localPhotoPath = savedFile.path);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID copiado!'), backgroundColor: AppTheme.verde));
    }
  }

  Future<void> _pickPhoto() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleção de foto disponível no app mobile')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(sheetContext);
                _chooseGalleryPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_front_outlined),
              title: const Text('Tirar foto com câmera frontal'),
              onTap: () {
                Navigator.pop(sheetContext);
                _captureProfilePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseGalleryPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (picked != null && mounted) {
        await _saveProfilePhoto(picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir a galeria: $e')),
        );
      }
    }
  }

  Future<void> _captureProfilePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 88,
      );
      if (picked != null && mounted) {
        await _saveProfilePhoto(picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir a câmera frontal: $e')),
        );
      }
    }
  }

  Future<void> _verifyFace() async {
    if (kIsWeb) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => _FaceCaptureScreen(camera: frontCamera)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir a câmera frontal: $e')),
        );
      }
    }
  }

  String _publicIdFor(String internalId) {
    final digest = sha256.convert(utf8.encode(internalId)).toString();
    final numeric = int.parse(digest.substring(0, 12), radix: 16) % 1000000000;
    return numeric.toString().padLeft(9, '0');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final wallet = context.watch<WalletProvider>();
    final displayName = user?.name ?? 'Visitante';
    final nickname = user != null ? '@${user.email.split('@').first}' : '@usuario';
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.pushNamed(context, AppRoutes.settings)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: user?.frame != null ? AppTheme.dourado : Colors.transparent, width: 3),
                      ),
                    ),
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.roxo,
                      backgroundImage: _localPhotoPath != null
                          ? FileImage(File(_localPhotoPath!))
                          : (user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null) as ImageProvider?,
                      child: _localPhotoPath == null && user?.photoUrl == null
                          ? const Icon(Icons.person, size: 45, color: AppTheme.dourado)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppTheme.dourado, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.preto),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (user != null)
                  SofiaUserBadge(level: user.level, levelTitle: user.levelTitle, vipTag: user.vipTag ?? wallet.vipTag, frame: user.frame ?? wallet.frame, size: 56),
                const SizedBox(height: 8),
                Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(nickname, style: const TextStyle(color: AppTheme.cinzaMedio)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: user != null ? () => _copyId(_publicIdFor(user.id)) : null,
                  child: Text('ID: ${user == null ? '---' : _publicIdFor(user.id)}', style: const TextStyle(color: AppTheme.dourado, letterSpacing: 1, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _balanceCard('Diamantes', '${wallet.diamonds.toStringAsFixed(0)}', AppTheme.dourado)),
              const SizedBox(width: 12),
              Expanded(child: _balanceCard('Moedas', '${wallet.coins.toStringAsFixed(0)}', AppTheme.amarelo, bordered: false)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('DADOS DO PERFIL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cinzaMedio, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _infoTile(Icons.calendar_today, 'Cadastro', user != null ? fmt.format(user.createdAt) : '—'),
          _infoTile(Icons.wc, 'Sexo', user?.gender ?? '—'),
          _infoTile(Icons.military_tech, 'Medalha de tempo', _tenureMedalFor(user?.createdAt)),
          _infoTile(Icons.diamond_outlined, 'VIP', wallet.vipTag ?? user?.vipTag ?? 'Standard'),
          _infoTile(Icons.workspace_premium, 'Nobreza / Nível', user?.levelTitle ?? wallet.levelTitle ?? 'Nível ${user?.level ?? 1}'),
          _infoTile(Icons.filter_frames, 'Moldura', user?.frame ?? wallet.frame ?? 'bronze'),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.dourado),
            title: const Text('Carteira'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline, color: AppTheme.dourado),
            title: const Text('Meus Indicados'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.referrals),
          ),
          ListTile(
            leading: const Icon(Icons.face_retouching_natural, color: AppTheme.dourado),
            title: const Text('Verificação facial'),
            subtitle: const Text('Confirme sua identidade'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _verifyFace,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: widget.onLogout, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.vermelho), child: const Text('SAIR')),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.roxo.withValues(alpha: 0.25),
      child: ListTile(dense: true, leading: Icon(icon, color: AppTheme.dourado, size: 20), title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.cinzaMedio)), subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
    );
  }

  Widget _balanceCard(String label, String value, Color color, {bool bordered = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.roxo.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: bordered ? Border.all(color: color.withValues(alpha: 0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FaceCaptureScreen extends StatefulWidget {
  final CameraDescription camera;
  const _FaceCaptureScreen({required this.camera});

  @override
  State<_FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<_FaceCaptureScreen> {
  CameraController? _controller;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _controller = CameraController(widget.camera, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _verify() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final picture = await controller.takePicture();
      final faceService = FaceRecognitionService();
      final detected = await faceService.detectFaceFromFile(picture.path);
      if (!mounted) return;
      setState(() => _verified = detected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(faceService.errorMessage ?? 'Não foi possível verificar o rosto.'),
          backgroundColor: detected ? AppTheme.verde : AppTheme.vermelho,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao capturar rosto: $e'), backgroundColor: AppTheme.vermelho),
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
      appBar: AppBar(title: const Text('Verificação facial')),
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: CameraPreview(_controller!)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dourado, foregroundColor: AppTheme.preto, minimumSize: const Size(double.infinity, 48)),
                    child: Text(_verified ? 'Verificado ✓' : 'Verificar rosto'),
                  ),
                ),
              ],
            ),
    );
  }
}
