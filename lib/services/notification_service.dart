import 'package:flutter/material.dart';
import 'package:personal_finance/theme/styles.dart';

class NotificationService {
  static OverlayEntry? _overlayEntry;

  static void showNotification(
      BuildContext context, {
        required String message,
        bool isError = false,
        Duration duration = const Duration(seconds: 2),
      }) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0,
        left: 16.0,
        right: 16.0,
        child: _CuteAnimatedNotification(
          message: message,
          isError: isError,
          isDark: isDark,
          duration: duration,
          onDismiss: () {
            _overlayEntry?.remove();
            _overlayEntry = null;
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }
}

class _CuteAnimatedNotification extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isDark;
  final Duration duration;
  final VoidCallback onDismiss;

  const _CuteAnimatedNotification({
    required this.message,
    required this.isError,
    required this.isDark,
    required this.duration,
    required this.onDismiss,
  });

  @override
  __CuteAnimatedNotificationState createState() => __CuteAnimatedNotificationState();
}

class __CuteAnimatedNotificationState extends State<_CuteAnimatedNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: _dismiss,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 100,
              decoration: BoxDecoration(
                color: widget.isError
                    ? Colors.redAccent // Solid red for errors
                    : const Color(0xFF009E60), // Shamrock green for success
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDark ? AppColors.darkShadow : AppColors.lightShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isError ? Icons.favorite_border : Icons.check,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppTextStyles.body(context).copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Comic Sans MS',
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}