import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_gift_panel.dart';
import 'package:sofia/providers/room_provider.dart';
import 'package:sofia/services/socket_service.dart';
import 'package:sofia/widgets/room/room_chat_panel.dart';
import 'package:sofia/services/media_service.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// Live de vídeo separada da sala de cadeiras/voz.
class VideoLiveRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String roomTheme;

  const VideoLiveRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.roomTheme,
  });

  @override
  State<VideoLiveRoomScreen> createState() => _VideoLiveRoomScreenState();
}

class _VideoLiveRoomScreenState extends State<VideoLiveRoomScreen> {
  Widget? _localView;
  int? _localViewId;
  final Map<String, Widget> _remoteViews = {};
  final Map<String, int> _remoteViewIds = {};
  bool _starting = true;
  bool _connected = false;
  bool _leaving = false;
  String? _error;
  bool _showChat = false;
  final TextEditingController _chatController = TextEditingController();
  final List<RoomChatMessage> _chatMessages = [];
  final Set<String> _chatMessageIds = {};
  SocketService? _chatSocket;
  String? _chatUserId;

  ZegoExpressEngine get _engine => ZegoExpressEngine.instance;
  MediaService get _media => context.read<MediaService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinVideoChat();
      _startVideoLive();
    });
  }

  void _joinVideoChat() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final socket = context.read<SocketService>();
    _chatSocket = socket;
    _chatUserId = user.id;
    socket.joinRoom(widget.roomId, user.id, user.name);
    socket.onChat((data) {
      if (!mounted) return;
      final id = data['id']?.toString() ?? '';
      if (id.isNotEmpty && !_chatMessageIds.add(id)) return;
      final text = data['text']?.toString() ?? '';
      if (text.isEmpty) return;
      setState(() {
        _chatMessages.add(
          RoomChatMessage(
            text: text,
            sender: data['sender']?.toString() ?? 'Usuário',
            isSystem: data['isSystem'] == true,
          ),
        );
      });
    });
  }

  Future<void> _sendVideoChat() async {
    final text = _chatController.text.trim();
    FocusScope.of(context).unfocus();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();
    final message = {
      'id': id,
      'text': text,
      'sender': user.name,
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'isSystem': false,
    };
    _chatMessageIds.add(id);
    setState(() {
      _chatMessages.add(RoomChatMessage(text: text, sender: user.name));
    });
    _chatController.clear();
    _chatSocket?.sendChat(widget.roomId, message);
  }

  void _openVideoGiftPanel() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final rooms = context.read<RoomProvider>();
    var participantCount = 1;
    var isHost = false;
    String? recipientId;
    for (final room in rooms.rooms) {
      if (room.id != widget.roomId) continue;
      participantCount = room.currentUsers;
      isHost = room.hostId == user.id;
      recipientId = room.participants.cast<String?>().firstWhere(
        (id) => id != null && id != user.id,
        orElse: () => room.hostId,
      );
      break;
    }
    if (recipientId == null || recipientId == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguarde outro participante para enviar presentes.'),
        ),
      );
      return;
    }
    showSofiaPremiumGiftPanel(
      context,
      roomId: widget.roomId,
      roomName: widget.roomName,
      isHost: isHost,
      participantCount: participantCount,
      recipientId: recipientId,
    );
  }

  Future<void> _startVideoLive() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = 'Faça login para iniciar a transmissão.';
        });
      }
      return;
    }

    try {
      if (!await _media.requestPermissions()) {
        throw Exception(
          _media.errorMessage ??
              'Permissões de câmera e microfone necessárias.',
        );
      }
      final tokenOk = await _media.zego.fetchRoomToken(
        userId: user.id,
        roomId: widget.roomId,
      );
      if (!tokenOk) {
        throw Exception('Não foi possível obter o token de vídeo ZEGO.');
      }
      final joined = await _media.zego.joinAudioRoom(
        userId: user.id,
        userName: user.name,
        roomId: widget.roomId,
      );
      if (!joined) {
        throw Exception(
          'ZEGO não está configurado para transmitir vídeo nesta sala.',
        );
      }

      await _engine.enableCamera(true);
      await _engine.muteMicrophone(false);
      final localWidget = await _engine.createCanvasView((viewId) {
        _localViewId = viewId;
        unawaited(_engine.startPreview(canvas: ZegoCanvas(viewId)));
      });
      if (!mounted || localWidget == null) {
        throw Exception('Não foi possível criar a prévia de vídeo.');
      }
      setState(() => _localView = localWidget);

      ZegoExpressEngine.onRoomStreamUpdate =
          (updatedRoomId, updateType, streams, extendedData) {
            if (updatedRoomId != widget.roomId) return;
            for (final stream in streams) {
              if (updateType == ZegoUpdateType.Add) {
                unawaited(_addRemoteStream(stream.streamID));
              } else {
                unawaited(_removeRemoteStream(stream.streamID));
              }
            }
          };

      await _engine.startPublishingStream('${widget.roomId}_${user.id}_video');
      if (!mounted) return;
      setState(() {
        _connected = true;
        _starting = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _connected = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _addRemoteStream(String streamId) async {
    if (_remoteViews.containsKey(streamId) || !mounted) return;
    int? viewId;
    final view = await _engine.createCanvasView((id) {
      viewId = id;
      unawaited(_engine.startPlayingStream(streamId, canvas: ZegoCanvas(id)));
    });
    if (!mounted || view == null || viewId == null) {
      if (viewId != null) await _engine.destroyCanvasView(viewId!);
      return;
    }
    setState(() {
      _remoteViews[streamId] = view;
      _remoteViewIds[streamId] = viewId!;
    });
  }

  Future<void> _removeRemoteStream(String streamId) async {
    await _engine.stopPlayingStream(streamId);
    final viewId = _remoteViewIds.remove(streamId);
    if (viewId != null) await _engine.destroyCanvasView(viewId);
    if (mounted) setState(() => _remoteViews.remove(streamId));
  }

  Future<void> _leaveVideo() async {
    if (_leaving) return;
    _leaving = true;
    try {
      await _engine.stopPublishingStream();
      await _engine.stopPreview();
      for (final streamId in _remoteViews.keys.toList()) {
        await _engine.stopPlayingStream(streamId);
      }
      for (final viewId in _remoteViewIds.values.toList()) {
        await _engine.destroyCanvasView(viewId);
      }
      _remoteViews.clear();
      _remoteViewIds.clear();
      if (_localViewId != null) {
        await _engine.destroyCanvasView(_localViewId!);
        _localViewId = null;
      }
      await _media.zego.leaveAudioRoom();
    } catch (_) {
      // O encerramento visual continua mesmo se o SDK já tiver desconectado.
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    final socket = _chatSocket;
    final userId = _chatUserId;
    if (socket != null && userId != null) {
      socket.leaveRoom(widget.roomId, userId);
    }
    unawaited(_leaveVideo());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1024),
        title: Text(widget.roomName),
        leading: IconButton(
          tooltip: 'Sair da live',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            final navigator = Navigator.of(context);
            await _leaveVideo();
            if (mounted) navigator.pop();
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF251044), Color(0xFF10152F), Color(0xFF080A1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: Color(0xFF31D7FF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.roomTheme,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Icon(
                      _connected ? Icons.circle : Icons.circle_outlined,
                      color: _connected ? Colors.greenAccent : Colors.amber,
                      size: 10,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _connected ? 'AO VIVO' : 'CONECTANDO',
                      style: const TextStyle(
                        color: Color(0xFFFFD76A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF11152A),
                        border: Border.all(color: const Color(0x5531D7FF)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_starting)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFD76A),
                              ),
                            )
                          else
                            _localView ??
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.videocam_off_rounded,
                                          size: 52,
                                          color: Color(0xFFFFD76A),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _error ?? 'Vídeo indisponível.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _starting = true;
                                              _error = null;
                                            });
                                            _startVideoLive();
                                          },
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                          ),
                                          label: const Text('Tentar novamente'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Column(
                              children: [
                                FloatingActionButton.small(
                                  heroTag: 'sofia-video-chat-toggle',
                                  tooltip: 'Chat da live',
                                  backgroundColor: const Color(0xFF171D3B),
                                  foregroundColor: const Color(0xFF31D7FF),
                                  onPressed: () =>
                                      setState(() => _showChat = !_showChat),
                                  child: const Icon(Icons.chat_bubble_rounded),
                                ),
                                const SizedBox(height: 10),
                                FloatingActionButton.small(
                                  heroTag: 'sofia-video-gift-toggle',
                                  tooltip: 'Enviar presente',
                                  backgroundColor: const Color(0xFFFFD76A),
                                  foregroundColor: const Color(0xFF10152F),
                                  onPressed: _openVideoGiftPanel,
                                  child: const Icon(
                                    Icons.card_giftcard_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showChat)
                            Positioned(
                              left: 8,
                              right: 8,
                              bottom: 8,
                              child: RoomChatPanel(
                                height: 190,
                                messages: _chatMessages,
                                controller: _chatController,
                                onSend: _sendVideoChat,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_remoteViews.isNotEmpty)
                SizedBox(
                  height: 118,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _remoteViews.values
                        .map(
                          (view) => Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 10),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x5531D7FF),
                              ),
                            ),
                            child: view,
                          ),
                        )
                        .toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await _leaveVideo();
                      if (mounted) navigator.pop();
                    },
                    icon: const Icon(Icons.call_end_rounded),
                    label: const Text('Encerrar live de vídeo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.vermelho,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
