import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/theme/skins.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/painters.dart';
import '../../../core/widgets/pressable.dart';
import '../controllers/themes_controller.dart';

class ThemesView extends GetView<ThemesController> {
  const ThemesView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final current = c.settings.skin;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: Get.back<void>,
                    semanticLabel: 'back'.tr,
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    header: true,
                    child: Text('themes'.tr, style: context.text.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                height: 210,
                decoration: BoxDecoration(
                  color: current.background,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: current.line),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: current.surface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: ExcludeSemantics(
                        child: MiniBoard(
                          spec: c.preview,
                          size: 128,
                          cellColor: current.cell,
                          tileColor: current.tileFor,
                          glyphColor: current.glyph,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${current.nameKey.tr} · ${current.noteKey.tr}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: current.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 128,
                ),
                itemCount: c.skins.length,
                itemBuilder: (_, i) {
                  final s = c.skins[i];
                  return EnterAnimation.staggered(
                    index: i,
                    child: _SkinCard(
                      skin: s,
                      selected: s.id == current.id,
                      unlocked: c.isUnlocked(s),
                      onTap: () => c.select(s),
                    ),
                  );
                },
              ),
              if (c.showUnlockBanner) ...[
                const SizedBox(height: 14),
                AppCard(
                  onTap: c.openStore,
                  semanticLabel: 'unlock_all_themes'.tr,
                  color: p.contrastSurface,
                  borderColor: p.contrastSurface,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: GridView.count(
                            crossAxisCount: 2,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (final col in [
                                Skins.forest.tileUp,
                                Skins.neon.tileUp,
                                Skins.neon.tileRight,
                                Skins.forest.tileRight,
                              ])
                                ColoredBox(color: col),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'unlock_all_themes'.tr,
                              style: TextStyle(
                                color: p.onContrast,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'theme_pack_or_plus'.tr,
                              style: TextStyle(
                                color: p.onContrastMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.onContrast),
                    ],
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.selected,
    required this.unlocked,
    required this.onTap,
  });

  final Skin skin;
  final bool selected;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final status = !unlocked
        ? skin.noteKey.tr
        : (selected ? 'in_use'.tr : 'tap_to_use'.tr);
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '${skin.nameKey.tr}, $status',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? p.primary : p.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Opacity(
                opacity: unlocked ? 1 : 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: skin.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final col in skin.swatches)
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            color: col,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skin.nameKey.tr,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        status,
                        style: context.text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: p.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: p.onPrimary,
                    ),
                  )
                else if (!unlocked)
                  Icon(Icons.lock_rounded, size: 18, color: p.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
