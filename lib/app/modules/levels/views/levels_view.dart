import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/game/level_catalog.dart';
import '../controllers/levels_controller.dart';

class LevelsView extends GetView<LevelsController> {
  const LevelsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Obx(() {
              final c = controller;
              final ch = c.chapter;
              final unlocked = c.chapterUnlocked(ch);
              // Touch reactive state so the grid refreshes after each clear.
              c.progress.highestCleared.value;
              c.progress.stars.length;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'tab_levels'.tr,
                                style: context.text.headlineSmall,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'cleared_of'.trParams({
                                'n': '${c.progress.highestCleared.value}',
                                'total': '${LevelCatalog.totalLevels}',
                              }),
                              style: context.text.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                        itemCount: c.chapters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final item = c.chapters[i];
                          final on = i == c.selected.value;
                          final locked = !c.chapterUnlocked(item);
                          return Pressable(
                            onTap: () => c.selectChapter(i),
                            selected: on,
                            semanticLabel:
                                '${'chapter_n'.trParams({'n': '${item.number}'})} ${item.titleKey.tr}',
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: on ? p.contrastSurface : p.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: on ? p.contrastSurface : p.line,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (locked) ...[
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 14,
                                      color: on ? p.onContrast : p.muted,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    '${item.number} · ${item.titleKey.tr}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: on ? p.onContrast : p.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: EnterAnimation(
                        key: ValueKey('ch${ch.number}'),
                        child: _ChapterCard(
                          chapter: ch,
                          stars: c.chapterStars(ch),
                          unlocked: unlocked,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                      itemCount: ch.levelCount,
                      itemBuilder: (_, i) {
                        final level = ch.firstLevel + i;
                        return EnterAnimation.staggered(
                          key: ValueKey('l$level'),
                          index: i % 24,
                          step: const Duration(milliseconds: 22),
                          scale: true,
                          child: _LevelTile(
                            level: level,
                            state: c.stateOf(level),
                            stars: c.progress.starsFor(level),
                            onTap: () => c.open(level),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
          if (controller.showBanner) const AdBanner(),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.stars,
    required this.unlocked,
  });

  final Chapter chapter;
  final int stars;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          IconBadge(
            icon: unlocked ? Icons.open_with_rounded : Icons.lock_rounded,
            color: unlocked ? p.primaryText : p.muted,
            background: unlocked ? p.primarySoft : p.cell,
            size: 58,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'chapter_boards'.trParams({
                    'n': '${chapter.number}',
                    'size': '${chapter.size}',
                  }).toUpperCase(),
                  style: context.text.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(chapter.titleKey.tr, style: context.text.titleLarge),
                const SizedBox(height: 2),
                Text(
                  unlocked ? chapter.subtitleKey.tr : 'chapter_locked_sub'.tr,
                  style: context.text.bodyMedium?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 18, color: p.star),
                  const SizedBox(width: 2),
                  Text('$stars', style: displayStyle(20, color: p.ink)),
                ],
              ),
              Text(
                '/ ${chapter.levelCount * 3}',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.state,
    required this.stars,
    required this.onTap,
  });

  final int level;
  final LevelState state;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final current = state == LevelState.current;
    final locked = state == LevelState.locked;
    final label = switch (state) {
      LevelState.done => 'level_a11y_done'.trParams({
        'n': '$level',
        's': '$stars',
      }),
      LevelState.current => 'level_a11y_next'.trParams({'n': '$level'}),
      LevelState.locked => 'level_a11y_locked'.trParams({'n': '$level'}),
    };
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.92,
      child: Container(
        decoration: BoxDecoration(
          color: current ? p.primary : (locked ? p.cell : p.surface),
          borderRadius: BorderRadius.circular(20),
          border: current || locked ? null : Border.all(color: p.line),
          boxShadow: current
              ? [
                  BoxShadow(
                    color: p.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$level',
              style: displayStyle(
                locked ? 18 : 22,
                color: current ? p.onPrimary : (locked ? p.muted : p.ink),
                weight: locked ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (locked)
              Icon(Icons.lock_rounded, size: 14, color: p.muted)
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 13,
                      color: i < stars
                          ? p.star
                          : (current
                                ? p.onPrimary.withValues(alpha: 0.55)
                                : p.line),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
