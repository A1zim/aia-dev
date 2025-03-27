import 'package:flutter/material.dart';
import 'package:personal_finance/theme/styles.dart';

class NotificationService {
  static OverlayEntry? _overlayEntry;

  static void showNotification(
      BuildContext context, {
        required String message,
        bool isError = false,
        Duration duration = const Duration(seconds: 3),
        String? actionLabel, // Optional action label
        VoidCallback? onAction, // Optional action callback
      }) {
    // Remove any existing notification
    _overlayEntry?.remove();
    _overlayEntry = null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0, // Position at the top
        left: 16.0,
        right: 16.0,
        child: _AnimatedNotification(
          message: message,
          isError: isError,
          isDark: isDark,
          onDismiss: () {
            _overlayEntry?.remove();
            _overlayEntry = null;
          },
          duration: duration,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }
}

class _AnimatedNotification extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isDark;
  final VoidCallback onDismiss;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AnimatedNotification({
    required this.message,
    required this.isError,
    required this.isDark,
    required this.onDismiss,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });

  @override
  __AnimatedNotificationState createState() => __AnimatedNotificationState();
}

class __AnimatedNotificationState extends State<_AnimatedNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    // Auto-dismiss after the specified duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isError
                    ? [Colors.redAccent, Colors.red]
                    : [Colors.green, Colors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.isDark ? AppColors.darkShadow : AppColors.lightShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  widget.isError ? Icons.error : Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppTextStyles.body(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.actionLabel != null && widget.onAction != null)
                  TextButton(
                    onPressed: () {
                      widget.onAction!();
                      _controller.reverse().then((_) {
                        widget.onDismiss();
                      });
                    },
                    child: Text(
                      widget.actionLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.reverse().then((_) {
                      widget.onDismiss();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}