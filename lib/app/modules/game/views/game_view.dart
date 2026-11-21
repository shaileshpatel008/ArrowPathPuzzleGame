import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/pressable.dart';
import '../controllers/game_controller.dart';
import '../models/board_arrow.dart';
import 'board_view.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: c.exitToLevels,
                    semanticLabel: 'back'.tr,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            c.title,
                            style: displayStyle(20, color: p.ink),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.subtitle,
                          style: context.text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.pause_rounded,
                    onTap: c.pause,
                    semanticLabel: 'pause'.tr,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Hearts + progress
              Row(
                children: [
                  Obx(() => _Hearts(left: c.hearts.value)),
                  const Spacer(),
                  SizedBox(
                    width: 170,
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'cleared'.tr,
                                style: context.text.labelMedium?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${c.cleared} / ${c.total}',
                                style: context.text.labelMedium?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          AppProgressBar(
                            value: c.total == 0 ? 0 : c.cleared / c.total,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: BoardView(controller: c)),
              const SizedBox(height: 14),
              Obx(() => _MessagePill(message: c.message.value)),
              const SizedBox(height: 14),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _ToolButton(
                        icon: Icons.undo_rounded,
                        label: 'undo'.tr,
                        onTap: c.undo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolButton(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'hint'.tr,
                        onTap: c.useHint,
                        badge: c.wallet.hints.value > 0
                            ? '${c.wallet.hints.value}'
                            : '+',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolButton(
                        icon: Icons.gps_fixed_rounded,
                        label: 'aim'.tr,
                        onTap: c.toggleAim,
                        active: c.aim.value,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolButton(
                        icon: Icons.restart_alt_rounded,
                        label: 'restart'.tr,
                        onTap: c.restart,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hearts extends StatelessWidget {
  const _Hearts({required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      label: 'hearts_left'.trParams({'n': '$left'}),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, a) => ScaleTransition(
                  scale: Tween<double>(begin: 1.6, end: 1).animate(
                    CurvedAnimation(parent: a, curve: Curves.elasticOut),
                  ),
                  child: FadeTransition(opacity: a, child: child),
                ),
                child: Icon(
                  i < left
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(i < left),
                  size: 26,
                  color: i < left ? p.danger : p.line,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessagePill extends StatelessWidget {
  const _MessagePill({required this.message});

  final GameMessage message;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final (Color bg, Color fg) = switch (message.tone) {
      MsgTone.info => (p.primarySoft, p.primaryText),
      MsgTone.good => (p.successSoft, p.successText),
      MsgTone.bad => (p.dangerSoft, p.dangerText),
      MsgTone.warn => (p.warnSoft, p.warnText),
    };
    final pill = AnimatedContainer(
      key: ValueKey(message.text),
      duration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(minHeight: 46),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.text,
        textAlign: TextAlign.center,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
    return Semantics(
      liveRegion: true,
      child: context.reduceMotion
          ? pill
          : pill
                .animate(key: ValueKey(message.text))
                .fadeIn(duration: 180.ms)
                .slideY(begin: 0.15, end: 0, duration: 220.ms),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final fg = active ? p.onContrast : p.ink;
    return Pressable(
      onTap: onTap,
      semanticLabel: badge == null ? label : '$label, $badge',
      selected: active,
      pressedScale: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 74,
        decoration: BoxDecoration(
          color: active ? p.contrastSurface : p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? p.contrastSurface : p.line),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 24, color: fg),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 7,
                right: 9,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Container(
                    key: ValueKey(badge),
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: p.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
