import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/core/frames/frame_catalog.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/widgets/frame_avatar.dart';

/// Modal interativo para visualização e equipagem de molduras do catálogo único.
class FrameSelectorSheet extends StatefulWidget {
  const FrameSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const FrameSelectorSheet(),
    );
  }

  @override
  State<FrameSelectorSheet> createState() => _FrameSelectorSheetState();
}

class _FrameSelectorSheetState extends State<FrameSelectorSheet> {
  late String _selectedFrameId;
  FrameType? _filterType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<AuthProvider>().user?.effectiveFrameId ?? 'host_a';
    _selectedFrameId = FrameCatalog.normalizeFrameId(current);
  }

  Future<void> _equipFrame() async {
    setState(() => _saving = true);
    final success = await context.read<AuthProvider>().equipFrame(_selectedFrameId);
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moldura equipada com sucesso!'),
          backgroundColor: AppTheme.verde,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao equipar moldura no servidor.'),
          backgroundColor: AppTheme.vermelho,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final equippedId = FrameCatalog.normalizeFrameId(user?.effectiveFrameId);
    final selectedItem = FrameCatalog.findById(_selectedFrameId) ?? FrameCatalog.hostA;

    final filteredList = _filterType == null
        ? FrameCatalog.allFrames
        : FrameCatalog.allFrames.where((f) => f.type == _filterType).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Barra superior de arraste
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Título e botão fechar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
              child: Row(
                children: [
                  const Text(
                    'CATÁLOGO DE MOLDURAS',
                    style: TextStyle(
                      color: AppTheme.dourado,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 1. Pré-visualização ao vivo do avatar com a moldura selecionada
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x77201948), Color(0x77101328)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedItem.rarity.color.withValues(alpha: 0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selectedItem.rarity.color.withValues(alpha: 0.18),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  FrameAvatar(
                    frameId: _selectedFrameId,
                    gender: user?.gender,
                    photoUrl: user?.photoUrl,
                    name: user?.name,
                    size: FrameAvatarSize.medium,
                    showPlaque: true,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${selectedItem.displayName} ${selectedItem.style.code}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: selectedItem.rarity.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedItem.rarity.color.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                selectedItem.rarity.label,
                                style: TextStyle(
                                  color: selectedItem.rarity.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedItem.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.cinzaMedio,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_selectedFrameId == equippedId)
                          const Text(
                            '✓ EQUIPADA ATUALMENTE',
                            style: TextStyle(
                              color: AppTheme.verde,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Filtros por Tipo de Moldura
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterChip(label: 'Todas', isSelected: _filterType == null, onTap: () => setState(() => _filterType = null)),
                  for (final type in FrameType.values)
                    _filterChip(
                      label: type.defaultTitle,
                      isSelected: _filterType == type,
                      onTap: () => setState(() => _filterType = type),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. Grade com os itens do catálogo
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  final isSelected = item.id == _selectedFrameId;
                  final isEquipped = item.id == equippedId;

                  return InkWell(
                    onTap: () => setState(() => _selectedFrameId = item.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x66151A34),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.dourado
                              : (isEquipped
                                  ? AppTheme.verde.withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.1)),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.dourado.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FrameAvatar(
                            frameId: item.id,
                            gender: user?.gender,
                            photoUrl: user?.photoUrl,
                            size: FrameAvatarSize.small,
                            customDiameter: 40,
                            showPlaque: false,
                            animate: isSelected,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.displayName} ${item.style.code}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isEquipped
                                ? 'Equipada'
                                : item.rarity.label,
                            style: TextStyle(
                              color: isEquipped
                                  ? AppTheme.verde
                                  : item.rarity.color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Botão de Equipar Moldura
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E20),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_saving || _selectedFrameId == equippedId)
                      ? null
                      : _equipFrame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dourado,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          _selectedFrameId == equippedId
                              ? 'MOLDURA JÁ EQUIPADA'
                              : 'EQUIPAR MOLDURA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.dourado,
        backgroundColor: const Color(0x66181D3C),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.dourado : Colors.white12,
          ),
        ),
      ),
    );
  }
}
