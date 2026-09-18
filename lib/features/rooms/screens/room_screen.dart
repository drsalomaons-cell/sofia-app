import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/sunlight/theme/sofia_premium_theme.dart';
import 'package:sofia/features/sunlight/widgets/sofia_gift_overlay.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_gift_panel.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_top_header.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_vip_gift_button.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
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
import 'package:sofia/widgets/room/sofia_seat_action_sheet.dart';
import 'package:camera/camera.dart';

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
  bool _showChat = false;
  String? _roomId;
  String? _hostId;
  double _roomEarnings = 0;
  DateTime? _roomCreatedAt;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId;
    _messages.add(ChatMessage(text: 'Bem-vindos à sala!', sender: 'Sistema', time: _now(), isSystem: true));
    _initRoom();
  }

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
      await context.read<RoomProvider>().joinRoom(_roomId!, user.id, userName: user.name);
      final room = await _roomService.getRoomById(_roomId!);
      if (room != null && mounted) {
        setState(() {
          _seats = room.seats.isNotEmpty ? room.seats : _roomService.parseSeats(room);
          _participants = room.participants;
          _hostId = room.hostId;
          _roomEarnings = room.earnings;
          _roomCreatedAt = room.createdAt;
        });
      }
      socket.joinRoom(_roomId!, user.id, user.name);
      socket.onChat((msg) {
        if (mounted) setState(() => _messages.add(ChatMessage.fromMap(msg)));
      });
      socket.onRoomState((data) {
        final room = data['room'];
        if (room is Map && mounted) {
          setState(() {
            _seats = (room['seats'] as List?)
                    ?.map((s) => SeatModel.fromJson(Map<String, dynamic>.from(s as Map)))
                    .toList() ??
                _seats;
            _participants = List<String>.from(room['participants'] ?? _participants);
          });
        }
      });
      socket.onRtcSignal((payload) {
        if (mounted) context.read<MediaService>().handleRemoteSignal(payload);
      });
    } else {
      setState(() {
        _seats = List.generate(widget.chairCount, (i) => SeatModel(index: i, userId: i == 0 ? user.id : null, userName: i == 0 ? user.name : null, role: i == 0 ? 'owner' : 'participant'));
        _participants = [user.id];
      });
    }

    if (!mounted) return;
    final media = context.read<MediaService>();
    media.bindRtcEmitter((type, data) {
      if (_roomId != null) socket.emitRtcSignal(_roomId!, data);
    });
    if (_roomId != null) {
      await media.autoEnableMedia(roomId: _roomId, userId: user.id);
    } else {
      await media.autoEnableMedia();
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
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final region = auth.user?.region ?? 'Global';
    final allowed = await _aiService.moderateContent(text, region: region);
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensagem bloqueada pela moderação'), backgroundColor: AppTheme.vermelho),
        );
      }
      return;
    }
    final msg = ChatMessage(text: text, sender: auth.user?.name ?? 'Você', time: _now(), isSystem: false);
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
    final seat = index < _seats.length ? _seats[index] : SeatModel(index: index);
    if (seat.isLocked && seat.userId != user.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadeira bloqueada'), backgroundColor: AppTheme.vermelho),
        );
      }
      return;
    }
    if (_roomId == null) {
      setState(() {
        _seats = _seats.map((s) {
          if (s.userId == user.id) return s.copyWith(clearUser: true);
          if (s.index == index) return s.copyWith(userId: user.id, userName: user.name);
          return s;
        }).toList();
      });
      return;
    }
    final room = await _roomService.takeSeat(_roomId!, index, user.id, user.name);
    if (room != null && mounted) {
      setState(() => _seats = room.seats);
    }
  }

  bool _canModerateRoom(String? userId) {
    if (userId == null) return false;
    if (userId == _hostId) return true;
    return _seats.any((s) => s.userId == userId && (s.role == 'owner' || s.role == 'moderator'));
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
          final room = await _roomService.lockSeat(_roomId!, index, user.id, locked);
          if (room != null && mounted) setState(() => _seats = room.seats);
        } else if (mounted) {
          setState(() {
            _seats = _seats.map((s) => s.index == index ? s.copyWith(isLocked: locked) : s).toList();
          });
        }
        break;
      case SofiaSeatAction.mute:
      case SofiaSeatAction.unmute:
        if (_roomId != null) {
          await _roomService.muteSeat(_roomId!, index, user.id, action == SofiaSeatAction.mute);
          final room = await _roomService.getRoomById(_roomId!);
          if (room != null && mounted) setState(() => _seats = room.seats);
        } else if (mounted) {
          setState(() {
            _seats = _seats.map((s) => s.index == index ? s.copyWith(isMuted: action == SofiaSeatAction.mute) : s).toList();
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
            _seats = _seats.map((s) => s.index == index ? s.copyWith(role: 'moderator') : s).toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário promovido a moderador'), backgroundColor: AppTheme.verde),
          );
        }
        break;
      case SofiaSeatAction.invite:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Convite enviado aos seguidores'), backgroundColor: AppTheme.roxo),
          );
        }
        break;
    }
  }

  SeatModel _seatAt(int index) => index < _seats.length ? _seats[index] : SeatModel(index: index);

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
    if (media.isMicActive) {
      await media.stopAudioStream();
    } else {
      await media.startAudioStream();
    }
    final user = context.read<AuthProvider>().user;
    if (_roomId != null && user != null) {
      context.read<SocketService>().emitMicToggle(_roomId!, user.id, media.isMicActive);
    }
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Participantes (${_participants.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._participants.map((id) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(id == context.read<AuthProvider>().user?.id ? 'Você' : 'Usuário $id'),
              )),
        ],
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
      final isHost = auth.user!.id == _hostId ||
          _seats.any((s) => s.userId == auth.user!.id && (s.role == 'owner' || s.role == 'host'));
      final roomGoalMet = (_roomEarnings + totalAmount) >= 500;
      final isOpeningEvent = _roomCreatedAt != null &&
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

    return Scaffold(
      backgroundColor: SofiaPremiumTheme.darkBg,
      body: Container(
        decoration: const BoxDecoration(gradient: SofiaPremiumTheme.roomBackground),
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
                    onMenu: _showParticipants,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.dourado, borderRadius: BorderRadius.circular(10)),
                          child: Text('Nível $level', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.preto)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people_outline, color: AppTheme.branco.withValues(alpha: 0.8), size: 18),
                        Text(' ${_participants.length}', style: const TextStyle(color: AppTheme.branco, fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.vermelho, borderRadius: BorderRadius.circular(8)),
                          child: const Row(children: [Icon(Icons.circle, size: 6, color: AppTheme.branco), SizedBox(width: 4), Text('AO VIVO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.branco))]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer<MediaService>(
                      builder: (context, mediaService, _) {
                        return Column(
                          children: [
                            if (mediaService.isCameraActive && mediaService.cameraController != null)
                              SizedBox(
                                height: 64,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CameraPreview(mediaService.cameraController!),
                                ),
                              ),
                            Expanded(
                              child: SofiaSeatsLayout(
                                seats: _seats,
                                chairCount: _seats.isNotEmpty ? _seats.length : widget.chairCount,
                                currentUserId: auth.user?.id,
                                onSeatTap: (index, seat) => _takeSeat(index),
                                onSeatLongPress: _onSeatLongPress,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_showChat)
                    RoomChatPanel(
                      messages: _messages.map((m) => RoomChatMessage(text: m.text, sender: m.sender, isSystem: m.isSystem)).toList(),
                      controller: _messageController,
                      onSend: _sendMessage,
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
                        ),
                        onLeave: _leaveRoom,
                      );
                    },
                  ),
                ],
              ),
              const SofiaGiftOverlay(),
              SofiaPremiumVipGiftButton(
                roomId: _roomId,
                roomName: widget.roomName,
                isHost: isHost,
                participantCount: _participants.length,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final String sender;
  final String time;
  final bool isSystem;

  ChatMessage({required this.text, required this.sender, required this.time, this.isSystem = false});

  Map<String, dynamic> toMap() => {'text': text, 'sender': sender, 'time': time, 'isSystem': isSystem};

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        text: m['text']?.toString() ?? '',
        sender: m['sender']?.toString() ?? '',
        time: m['time']?.toString() ?? '',
        isSystem: m['isSystem'] == true,
      );
}
