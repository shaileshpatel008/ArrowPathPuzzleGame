import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/pressable.dart';
import '../../daily/views/daily_view.dart';
import '../../home/views/home_view.dart';
import '../../levels/views/levels_view.dart';
import '../../settings/views/settings_view.dart';
import '../controllers/shell_controller.dart';

class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.tab.value;
      return PopScope(
        canPop: tab == ShellTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.handleBack();
        },
        child: Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.012),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(tab),
              child: switch (tab) {
                ShellTab.home => const HomeView(),
                ShellTab.levels => const LevelsView(),
                ShellTab.daily => const DailyView(),
                ShellTab.settings => const SettingsView(),
              },
            ),
          ),
          bottomNavigationBar: _NavBar(
            current: tab,
            onSelect: controller.select,
          ),
        ),
      );
    });
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.current, required this.onSelect});

  final ShellTab current;
  final ValueChanged<ShellTab> onSelect;

  static const _items = [
    (ShellTab.home, Icons.home_rounded, 'tab_home'),
    (ShellTab.levels, Icons.grid_view_rounded, 'tab_levels'),
    (ShellTab.daily, Icons.calendar_month_rounded, 'tab_daily'),
    (ShellTab.settings, Icons.tune_rounded, 'tab_settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final (tab, icon, label) in _items)
                Expanded(
                  child: Pressable(
                    onTap: () {
                      if (tab != current) {
                        HapticFeedback.selectionClick();
                        onSelect(tab);
                      }
                    },
                    feedback: false,
                    semanticLabel: label.tr,
                    selected: tab == current,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          width: tab == current ? 58 : 40,
                          height: 30,
                          decoration: BoxDecoration(
                            color: tab == current
                                ? p.primarySoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            icon,
                            size: 22,
                            color: tab == current ? p.primaryText : p.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: tab == current
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: tab == current ? p.primaryText : p.muted,
                          ),
                        ),
                      ],
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
