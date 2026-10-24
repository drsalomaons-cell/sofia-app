import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/sunlight/theme/sofia_premium_theme.dart';
import 'package:sofia/features/sunlight/widgets/sofia_gift_overlay.dart';
import 'package:sofia/features/sunlight/widgets/rocket_launch_overlay.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_gift_panel.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_top_header.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_vip_gift_button.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/models/room_model.dart';
import 'package:sofia/models/seat_model.dart';
import 'package:sofia/providers/room_provider.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/services/ai_service.dart';
import 'package:sofia/services/media_service.dart';
import 'package:sofia/services/room_service.dart';
import 'package:sofia/services/socket_service.dart';
import 'package:sofia/widgets/room/sofia_seats_layout.dart';
import 'package:sofia/widgets/room/room_chat_panel.dart';
import 'package:sofia/features/sunlight/widgets/sunlight_room_bottom_bar.dart';
import 'package:sofia/features/rooms/screens/room_games_sheet.dart';
import 'package:sofia/widgets/room/sofia_seat_action_sheet.dart';

class RoomScreen extends StatefulWidget {
  final String? roomId;
  final String roomName;
  final String roomTheme;
  final int spectatorCount;
  final int chairCount;

  const RoomScreen({
    super.key,
    this.roomId,
    required this.roomName,
    required this.roomTheme,
    this.spectatorCount = 12,
    this.chairCount = 12,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AIService _aiService = AIService();
  final RoomService _roomService = RoomService();
  final List<ChatMessage> _messages = [];
  List<SeatModel> _seats = [];
  List<String> _participants = [];
  List<Map<String, dynamic>> _giftRanking = [];
  Map<String, dynamic>? _rocketGoal;
  bool _rocketLaunched = false;
  bool _showChat = false;
  String _roomBackgroundId = 'midnight';
  String _roomCoverStyle = 'gold';
  String? _roomId;
  String? _hostId;
  double _roomEarnings = 0;
  DateTime? _roomCreatedAt;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId;
    _messages.add(
      ChatMessage(
        text: 'Bem-vindos Ã  sala!',
        sender: 'Sistema',
        time: _now(),
        isSystem: true,
      ),
    );
    _initRoom();
  }

  LinearGradient get _roomBackgroundGradient => switch (_roomBackgroundId) {
    'violet' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF281044), Color(0xFF170D2E), Color(0xFF080A1A)],
    ),
    'ocean' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF08283A), Color(0xFF10152F), Color(0xFF080A1A)],
    ),
    _ => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF111225), Color(0xFF191A2D), Color(0xFF0B0C1F)],
    ),
  };

  String _now() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _initRoom() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final socket = context.read<SocketService>();
    if (_roomId != null) {
      await context.read<RoomProvider>().joinRoom(
        _roomId!,
        user.id,
        userName: user.name,
      );
      final room = await _roomService.getRoomById(_roomId!);
      if (room != null && mounted) {
        setState(() {
          _seats = room.seats.isNotEmpty
              ? room.seats
              : _roomService.parseSeats(room);
          _participants = room.participants;
          _hostId = room.hostId;
          _roomEarnings = room.earnings;
          _roomCreatedAt = room.createdAt;
          _roomBackgroundId = room.background;
          _roomCoverStyle = room.coverStyle;
        });
      }
      socket.joinRoom(_roomId!, user.id, user.name);
      socket.onChat((msg) {
        if (!mounted) return;
        final incoming = ChatMessage.fromMap(msg);
        final alreadyPresent = _messages.any((existing) {
          if (incoming.id.isNotEmpty && existing.id == incoming.id) return true;
          // Fallback para eventos antigos que n?o trazem id. A hora do cliente
          // ? preservada pelo socket; n?o bloqueia mensagens repetidas enviadas
          // em hor?rios diferentes.
          return existing.sender == incoming.sender &&
              existing.text == incoming.text &&
              existing.time == incoming.time;
        });
        if (!alreadyPresent) {
          setState(() => _messages.add(incoming));
        }
      });
      socket.onGift((gift) {
        if (mounted) {
          _loadRocketGoal();
          _loadGiftRanking();
        }
      });
      _loadRocketGoal();
      _loadGiftRanking();
      socket.onRoomState((data) {
        final room = data['room'];
        if (room is Map && mounted) {
          setState(() {
            _seats =
                (room['seats'] as List?)
                    ?.map(
                      (s) => SeatModel.fromJson(
                        Map<String, dynamic>.from(s as Map),
                      ),
                    )
                    .toList() ??
                _seats;
            _participants = List<String>.from(
              room['participants'] ?? _participants,
            );
          });
        }
      });
      socket.onRoomSettings((data) {
        final updatedRoom = data['room'];
        if (updatedRoom is Map && mounted) {
          final parsed = RoomModel.fromJson(
            Map<String, dynamic>.from(updatedRoom),
          );
          setState(() {
            _seats = parsed.seats;
            _participants = parsed.participants;
            _roomBackgroundId = parsed.background;
            _roomCoverStyle = parsed.coverStyle;
          });
        }
      });
      socket.onRoomChatCleared((_) {
        if (mounted) {
          setState(() => _messages.removeWhere((message) => !message.isSystem));
        }
      });
      socket.onRtcSignal((payload) {
        if (mounted) context.read<MediaService>().handleRemoteSignal(payload);
      });
    } else {
      setState(() {
        _seats = List.generate(
          widget.chairCount,
          (i) => SeatModel(
            index: i,
            userId: i == 0 ? user.id : null,
            userName: i == 0 ? user.name : null,
            role: i == 0 ? 'owner' : 'participant',
          ),
        );
        _participants = [user.id];
      });
    }

    if (!mounted) return;
    final media = context.read<MediaService>();
    media.bindRtcEmitter((type, data) {
      if (_roomId != null) socket.emitRtcSignal(_roomId!, data);
    });
    // Sala de cadeiras Ã© Ã¡udio/avatares; a cÃ¢mera pertence Ã  Live de vÃ­deo.
    final mediaReady = _roomId != null
        ? await media.autoEnableMedia(
            roomId: _roomId,
            userId: user.id,
            userName: user.name,
          )
        : false;
    if (!mediaReady &&
        _roomId != null &&
        mounted &&
        media.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(media.errorMessage!),
          duration: const Duration(seconds: 5),
          backgroundColor: AppTheme.vermelho,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    MediaService().disposeAll();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    FocusScope.of(context).unfocus();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final region = auth.user?.region ?? 'Global';
    final allowed = await _aiService.moderateContent(text, region: region);
    if (!mounted) return;
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensagem bloqueada pela moderaÃ§Ã£o'),
            backgroundColor: AppTheme.vermelho,
          ),
        );
      }
      return;
    }
    final msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      sender: auth.user?.name ?? 'VocÃª',
      time: _now(),
      isSystem: false,
    );
    setState(() => _messages.add(msg));
    if (_roomId != null) {
      context.read<SocketService>().sendChat(_roomId!, msg.toMap());
    }
    _messageController.clear();
  }

  Future<void> _takeSeat(int index) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    final seat = index < _seats.length
        ? _seats[index]
        : SeatModel(index: index);
    if (seat.isLocked && seat.userId != user.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadeira bloqueada'),
            backgroundColor: AppTheme.vermelho,
          ),
        );
      }
      return;
    }
    if (_roomId == null) {
      setState(() {
        _seats = _seats.map((s) {
          if (s.userId == user.id) return s.copyWith(clearUser: true);
          if (s.index == index)
            return s.copyWith(
              userId: user.id,
              userName: user.name,
              photoUrl: user.photoUrl,
              level: user.level,
            );
          return s;
        }).toList();
      });
      return;
    }
    final room = await _roomService.takeSeat(
      _roomId!,
      index,
      user.id,
      user.name,
    );
    if (room != null && mounted) {
      setState(() => _seats = room.seats);
    }
  }

  bool _canModerateRoom(String? userId) {
    if (userId == null) return false;
    if (userId == _hostId) return true;
    return _seats.any(
      (s) => s.userId == userId && (s.role == 'owner' || s.role == 'moderator'),
    );
  }

  Future<void> _handleSeatAction(int index, SofiaSeatAction action) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    final seat = _seatAt(index);

    switch (action) {
      case SofiaSeatAction.lock:
      case SofiaSeatAction.unlock:
        final locked = action == SofiaSeatAction.lock;
        if (_roomId != null) {
          final room = await _roomService.lockSeat(
            _roomId!,
            index,
            user.id,
            locked,
          );
          if (room != null && mounted) setState(() => _seats = room.seats);
        } else if (mounted) {
          setState(() {
            _seats = _seats
                .map((s) => s.index == index ? s.copyWith(isLocked: locked) : s)
                .toList();
          });
        }
        break;
      case SofiaSeatAction.mute:
      case SofiaSeatAction.unmute:
        if (_roomId != null) {
          await _roomService.muteSeat(
            _roomId!,
            index,
            user.id,
            action == SofiaSeatAction.mute,
          );
          final room = await _roomService.getRoomById(_roomId!);
          if (room != null && mounted) setState(() => _seats = room.seats);
        } else if (mounted) {
          setState(() {
            _seats = _seats
                .map(
                  (s) => s.index == index
                      ? s.copyWith(isMuted: action == SofiaSeatAction.mute)
                      : s,
                )
                .toList();
          });
        }
        break;
      case SofiaSeatAction.kick:
        if (seat.userId != null && _roomId != null) {
          await _roomService.banUser(_roomId!, seat.userId!, user.id);
          final room = await _roomService.getRoomById(_roomId!);
          if (room != null && mounted) setState(() => _seats = room.seats);
        }
        break;
      case SofiaSeatAction.promote:
        if (mounted) {
          setState(() {
            _seats = _seats
                .map(
                  (s) => s.index == index ? s.copyWith(role: 'moderator') : s,
                )
                .toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('UsuÃ¡rio promovido a moderador'),
              backgroundColor: AppTheme.verde,
            ),
          );
        }
        break;
      case SofiaSeatAction.invite:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Convite enviado aos seguidores'),
              backgroundColor: AppTheme.roxo,
            ),
          );
        }
        break;
    }
  }

  SeatModel _seatAt(int index) =>
      index < _seats.length ? _seats[index] : SeatModel(index: index);

  String? get _giftRecipientId {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (_hostId != null && _hostId != currentUserId) return _hostId;
    for (final seat in _seats) {
      if (seat.userId != null && seat.userId != currentUserId) {
        return seat.userId;
      }
    }
    for (final participantId in _participants) {
      if (participantId != currentUserId) return participantId;
    }
    return null;
  }

  void _onSeatLongPress(int index, SeatModel seat) {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (_canModerateRoom(userId)) {
      SofiaSeatActionSheet.show(
        context,
        seatIndex: index,
        seat: seat,
        canModerate: true,
        onAction: (a) => _handleSeatAction(index, a),
      );
    } else if (userId == seat.userId) {
      _toggleMic();
    }
  }

  Future<void> _toggleMic() async {
    final media = context.read<MediaService>();
    bool ok = true;
    if (media.isMicActive) {
      await media.stopAudioStream();
    } else {
      ok = await media.startAudioStream();
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            media.errorMessage ?? 'NÃ£o foi possÃ­vel ativar o microfone.',
          ),
          backgroundColor: AppTheme.vermelho,
        ),
      );
    }
    final user = context.read<AuthProvider>().user;
    if (_roomId != null && user != null) {
      context.read<SocketService>().emitMicToggle(
        _roomId!,
        user.id,
        media.isMicActive,
      );
    }
  }

  void _showRoomInfo() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'InformaÃ§Ãµes da sala',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const ListTile(
                leading: Icon(Icons.family_restroom),
                title: Text('FamÃ­lia'),
                subtitle: Text('InformaÃ§Ãµes e recursos de famÃ­lia'),
              ),
              const ListTile(
                leading: Icon(Icons.support_agent),
                title: Text('Suporte'),
                subtitle: Text(
                  'Use os canais oficiais do aplicativo para atendimento',
                ),
              ),
              const ListTile(
                leading: Icon(Icons.translate),
                title: Text('TraduÃ§Ã£o'),
                subtitle: Text('TraduÃ§Ã£o automÃ¡tica ainda nÃ£o conectada'),
              ),
              const ListTile(
                leading: Icon(Icons.campaign_outlined),
                title: Text('Avisos'),
                subtitle: Text('Informativos da sala'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRoomActions() async {
    final size = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        size.width - 240,
        safeTop + 54,
        8,
        size.height - safeTop - 360,
      ),
      items: const [
        PopupMenuItem(value: 'clear_room', child: Text('Limpeza de sala')),
        PopupMenuItem(value: 'clear_text', child: Text('Limpeza de texto')),
        PopupMenuItem(
          value: 'clear_charisma',
          child: Text('Limpeza de carisma'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(value: 'cover', child: Text('Mudar capa')),
        PopupMenuItem(value: 'background', child: Text('Mudar fundo')),
        PopupMenuItem(value: 'chairs', child: Text('Aumentar cadeiras')),
      ],
    );
    if (!mounted || action == null) return;
    _handleRoomMenuAction(action);
  }

  Future<void> _handleRoomMenuAction(String action) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (!_canModerateRoom(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Somente o dono ou um moderador pode usar estes controles.',
          ),
        ),
      );
      return;
    }
    if (_roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta aÃ§Ã£o exige uma sala salva no servidor.'),
        ),
      );
      return;
    }

    switch (action) {
      case 'clear_room':
      case 'clear_text':
        await _applyRoomModeration(action);
        break;
      case 'clear_charisma':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Carisma ainda nÃ£o Ã© um campo persistido no backend.',
            ),
          ),
        );
        break;
      case 'cover':
        final cover = await _chooseRoomOption('Capa da sala', const [
          {'value': 'gold', 'label': 'Dourado premium'},
          {'value': 'neon', 'label': 'Neon ciano'},
          {'value': 'violet', 'label': 'Violeta'},
        ]);
        if (cover != null) await _applyRoomModeration('cover', cover);
        break;
      case 'background':
        final background = await _chooseRoomOption('Fundo da sala', const [
          {'value': 'midnight', 'label': 'Azul meia-noite'},
          {'value': 'violet', 'label': 'Roxo profundo'},
          {'value': 'ocean', 'label': 'Oceano neon'},
        ]);
        if (background != null)
          await _applyRoomModeration('background', background);
        break;
      case 'chairs':
        final current = _seats.isNotEmpty ? _seats.length : widget.chairCount;
        final choices = [
          12,
          16,
          20,
          24,
          30,
        ].where((count) => count > current).toList();
        if (choices.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A sala jÃ¡ estÃ¡ no limite de 30 cadeiras.'),
            ),
          );
          return;
        }
        final requested = await showDialog<int>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: const Text('Aumentar cadeiras'),
            children: choices
                .map(
                  (count) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialogContext, count),
                    child: Text('$count cadeiras'),
                  ),
                )
                .toList(),
          ),
        );
        if (requested != null) await _applyRoomModeration('chairs', requested);
        break;
    }
  }

  Future<String?> _chooseRoomOption(
    String title,
    List<Map<String, String>> options,
  ) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(title),
        children: options
            .map(
              (option) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, option['value']),
                child: Text(option['label'] ?? ''),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _applyRoomModeration(String action, [dynamic value]) async {
    final roomId = _roomId;
    if (roomId == null) return;
    try {
      final room = await _roomService.moderateRoom(
        roomId,
        action: action,
        value: value,
      );
      if (room == null)
        throw Exception('O servidor nÃ£o confirmou a alteraÃ§Ã£o.');
      if (!mounted) return;
      setState(() {
        _seats = room.seats.isNotEmpty ? room.seats : _seats;
        _participants = room.participants;
        _roomBackgroundId = room.background;
        _roomCoverStyle = room.coverStyle;
        if (action == 'clear_room' || action == 'clear_text') {
          _messages.removeWhere((message) => !message.isSystem);
          _showChat = false;
        }
      });
      final message = switch (action) {
        'clear_room' => 'Sala limpa e sincronizada.',
        'clear_text' => 'Chat limpo para os participantes da sala.',
        'cover' => 'Capa da sala atualizada.',
        'background' => 'Fundo da sala atualizado.',
        'chairs' => 'Quantidade de cadeiras salva no servidor.',
        _ => 'Sala atualizada.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.verde),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NÃ£o foi possÃ­vel aplicar a alteraÃ§Ã£o: $error'),
          backgroundColor: AppTheme.vermelho,
        ),
      );
    }
  }

  Future<void> _loadRocketGoal() async {
    final roomId = _roomId;
    if (roomId == null) return;
    final goal = await _roomService.getRocketGoal(roomId);
    if (!mounted || goal == null) return;
    final current = (goal['current'] as num?)?.toInt() ?? 0;
    final target = (goal['target'] as num?)?.toInt() ?? 400000;
    final previousCurrent = (_rocketGoal?['current'] as num?)?.toInt() ?? 0;
    final reachedNow =
        target > 0 && current >= target && previousCurrent < target;
    setState(() {
      _rocketGoal = goal;
      if (reachedNow) _rocketLaunched = true;
    });
  }

  Future<void> _loadGiftRanking() async {
    final roomId = _roomId;
    if (roomId == null) return;
    final ranking = await _roomService.getGiftRanking(roomId);
    if (!mounted) return;
    setState(() => _giftRanking = ranking);
  }

  void _launchRocketAnimation() {
    if (!mounted) return;
    setState(() => _rocketLaunched = true);
  }

  Future<void> _showRocketRanking() async {
    if (_roomId != null) {
      await _loadGiftRanking();
      await _loadRocketGoal();
      if (!mounted) return;
    }
    if (!mounted) return;
    final sortedRanking = List<Map<String, dynamic>>.from(_giftRanking)
      ..sort(
        (a, b) => ((b['totalCoins'] as num?)?.toInt() ?? 0).compareTo(
          (a['totalCoins'] as num?)?.toInt() ?? 0,
        ),
      );
    final topRanking = sortedRanking.take(10).toList();
    final rocketCurrent = (_rocketGoal?['current'] as num?)?.toInt() ?? 0;
    final rocketTarget = (_rocketGoal?['target'] as num?)?.toInt() ?? 400000;
    final rocketProgress = rocketTarget > 0
        ? (rocketCurrent / rocketTarget).clamp(0.0, 1.0)
        : 0.0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ðŸš€ Ranking de contribuiÃ§Ãµes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.roomName,
                  style: const TextStyle(color: AppTheme.cinzaMedio),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'ðŸš€ Meta do foguete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('$rocketCurrent / $rocketTarget'),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: rocketProgress,
                    minHeight: 7,
                    backgroundColor: AppTheme.cinzaMedio.withValues(
                      alpha: 0.25,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.dourado,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (topRanking.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Ainda nÃ£o hÃ¡ presentes registrados nesta sala. Envie presentes para avanÃ§ar a meta do foguete e aparecer no ranking.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: topRanking.length,
                      itemBuilder: (context, index) {
                        final entry = topRanking[index];
                        final name =
                            entry['name']?.toString() ?? 'Participante';
                        final photo = entry['photoUrl']?.toString();
                        final coins =
                            (entry['totalCoins'] as num?)?.toInt() ?? 0;
                        final gifts =
                            (entry['giftCount'] as num?)?.toInt() ?? 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: photo != null && photo.isNotEmpty
                                ? NetworkImage(photo)
                                : null,
                            child: photo == null || photo.isEmpty
                                ? Text(
                                    name.isEmpty
                                        ? '?'
                                        : name.characters.first.toUpperCase(),
                                  )
                                : null,
                          ),
                          title: Text('${index + 1}. $name'),
                          subtitle: Text('$gifts presentes enviados'),
                          trailing: Text(
                            '$coins ðŸª™',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                if (topRanking.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'No topo do foguete: ${topRanking.first['name'] ?? 'Participante'}',
                      style: const TextStyle(
                        color: AppTheme.dourado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _leaveRoom() async {
    final auth = context.read<AuthProvider>();
    if (_roomId != null && auth.user != null) {
      context.read<SocketService>().leaveRoom(_roomId!, auth.user!.id);
      await context.read<RoomProvider>().leaveRoom(_roomId!, auth.user!.id);
      final participantCount = _participants.length.clamp(1, 20);
      final totalAmount = 10.0 * participantCount;
      final isHost =
          auth.user!.id == _hostId ||
          _seats.any(
            (s) =>
                s.userId == auth.user!.id &&
                (s.role == 'owner' || s.role == 'host'),
          );
      final roomGoalMet = (_roomEarnings + totalAmount) >= 500;
      final isOpeningEvent =
          _roomCreatedAt != null &&
          DateTime.now().difference(_roomCreatedAt!).inHours < 72 &&
          participantCount >= 5;
      await context.read<WalletProvider>().addEarning(
        roomId: _roomId!,
        roomName: widget.roomName,
        totalAmount: totalAmount,
        participantCount: participantCount,
        isHost: isHost,
        roomGoalMet: roomGoalMet,
        isOpeningEvent: isOpeningEvent,
      );
    }
    await context.read<MediaService>().disposeAll();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final level = user?.level ?? 1;
    final isHost = user?.id == _hostId;
    final rocketCurrent = (_rocketGoal?['current'] as num?)?.toInt() ?? 0;
    final rocketTarget = (_rocketGoal?['target'] as num?)?.toInt() ?? 400000;
    final rocketProgress = rocketTarget > 0
        ? (rocketCurrent / rocketTarget).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: SofiaPremiumTheme.darkBg,
      body: Container(
        decoration: BoxDecoration(gradient: _roomBackgroundGradient, image: const DecorationImage(image: AssetImage('assets/images/rooms/sala_principal.png'), fit: BoxFit.cover, opacity: 0.28)),
        child: SafeArea(
          bottom: false,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Column(
                children: [
                  SofiaPremiumTopHeader(
                    roomName: widget.roomName,
                    roomTheme: widget.roomTheme,
                    coverStyle: _roomCoverStyle,
                    onMenu: _showRoomActions,
                    onBack: _leaveRoom,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ID da sala: ${_roomId ?? 'local'}  â€¢  ID do proprietÃ¡rio: ${_hostId ?? 'nÃ£o disponÃ­vel'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.branco.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                    child: InkWell(
                      onTap: _showRocketRanking,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0B0C1F,
                          ).withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(
                              0xFF00DCE6,
                            ).withValues(alpha: 0.32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00F2FE,
                              ).withValues(alpha: 0.08),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.rocket_launch_rounded,
                              color: Color(0xFFFFD81D),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Meta',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.dourado,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: rocketProgress,
                                  minHeight: 4,
                                  backgroundColor: AppTheme.branco.withValues(
                                    alpha: 0.12,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF00F2FE),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$rocketCurrent / $rocketTarget',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.branco,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.dourado,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'NÃ­vel $level',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.preto,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.people_outline,
                          color: AppTheme.branco.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        Text(
                          ' ${_participants.length}',
                          style: const TextStyle(
                            color: AppTheme.branco,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.vermelho,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: AppTheme.branco,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'AO VIVO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.branco,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      // Reserva uma faixa lateral para o foguete sem cobrir as cadeiras.
                      padding: const EdgeInsets.only(right: 48),
                      child: SofiaSeatsLayout(
                        seats: _seats,
                        chairCount: _seats.isNotEmpty
                            ? _seats.length
                            : widget.chairCount,
                        currentUserId: auth.user?.id,
                        onSeatTap: (index, seat) => _takeSeat(index),
                        onSeatLongPress: _onSeatLongPress,
                      ),
                    ),
                  ),
                  Consumer<MediaService>(
                    builder: (context, mediaService, _) {
                      return SunlightRoomBottomBar(
                        micActive: mediaService.isMicActive,
                        chatOpen: _showChat,
                        onMic: _toggleMic,
                        onChat: () => setState(() => _showChat = !_showChat),
                        onGift: () => showSofiaPremiumGiftPanel(
                          context,
                          roomId: _roomId,
                          roomName: widget.roomName,
                          isHost: isHost,
                          participantCount: _participants.length,
                          recipientId: _giftRecipientId,
                        ),
                        onGames: () {
                          final currentUserId = user?.id;
                          final isSeated = _seats.any(
                            (seat) =>
                                seat.userId == currentUserId &&
                                !seat.isLocked &&
                                (seat.role == 'owner' ||
                                    seat.role == 'host' ||
                                    seat.role == 'moderator' ||
                                    seat.role == 'participant'),
                          );
                          RoomGamesSheet.show(
                            context,
                            roomId: _roomId,
                            canStartGame: isHost || isSeated,
                          );
                        },
                        onEnvelope: _showRoomInfo,
                      );
                    },
                  ),
                ],
              ),
              if (_showChat)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 78,
                  child: RoomChatPanel(
                    height: (MediaQuery.sizeOf(context).height * 0.34).clamp(
                      210.0,
                      300.0,
                    ),
                    messages: _messages
                        .map(
                          (m) => RoomChatMessage(
                            text: m.text,
                            sender: m.sender,
                            isSystem: m.isSystem,
                          ),
                        )
                        .toList(),
                    controller: _messageController,
                    onSend: _sendMessage,
                  ),
                ),
              if (!_showChat)
                Positioned(
                  right: 12,
                  bottom: 142,
                  child: FloatingActionButton.small(
                    heroTag: 'sofia-room-gifts',
                    backgroundColor: SofiaPremiumTheme.gold,
                    foregroundColor: SofiaPremiumTheme.darkBg,
                    tooltip: 'Abrir presentes',
                    onPressed: () => showSofiaPremiumGiftPanel(
                      context,
                      roomId: _roomId,
                      roomName: widget.roomName,
                      isHost: isHost,
                      participantCount: _participants.length,
                      recipientId: _giftRecipientId,
                    ),
                    child: const Icon(Icons.card_giftcard),
                  ),
                ),
              const SofiaGiftOverlay(),
              if (!_showChat)
                SofiaPremiumVipGiftButton(
                  roomId: _roomId,
                  roomName: widget.roomName,
                  isHost: isHost,
                  participantCount: _participants.length,
                  onRocketTap: _launchRocketAnimation,
                  topContributorName: _giftRanking.isNotEmpty
                      ? _giftRanking.first['name']?.toString()
                      : null,
                  topContributorPhotoUrl: _giftRanking.isNotEmpty
                      ? _giftRanking.first['photoUrl']?.toString()
                      : null,
                ),
              if (_rocketLaunched)
                RocketLaunchOverlay(
                  onFinished: () {
                    if (mounted) setState(() => _rocketLaunched = false);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final String sender;
  final String time;
  final bool isSystem;

  ChatMessage({
    this.id = '',
    required this.text,
    required this.sender,
    required this.time,
    this.isSystem = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'sender': sender,
    'time': time,
    'isSystem': isSystem,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
    id: m['id']?.toString() ?? '',
    text: m['text']?.toString() ?? '',
    sender: m['sender']?.toString() ?? '',
    time: m['time']?.toString() ?? '',
    isSystem: m['isSystem'] == true,
  );
}

