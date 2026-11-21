import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/audio_service.dart';
import '../../data/services/settings_service.dart';

/// Tap target with a soft "squish", haptic tick and tap sound.
/// Exposed to accessibility services as a button.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.pressedScale = 0.96,
    this.feedback = true,
    this.borderRadius,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double pressedScale;
  final bool feedback;
  final BorderRadius? borderRadius;
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  void _tap() {
    if (widget.onTap == null) return;
    if (widget.feedback) {
      if (Get.isRegistered<SettingsService>()) {
        Get.find<SettingsService>().tick();
      }
      if (Get.isRegistered<AudioService>()) {
        Get.find<AudioService>().play(Sfx.tap);
      }
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _tap(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: enabled ? _tap : null,
          child: AnimatedScale(
            scale: _down ? widget.pressedScale : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.45,
              duration: const Duration(milliseconds: 150),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
