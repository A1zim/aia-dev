import 'package:flutter/material.dart';
import 'package:aia_wallet/theme/styles.dart';

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
        child: _SeriousNotification(
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

class _SeriousNotification extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isDark;
  final Duration duration;
  final VoidCallback onDismiss;

  const _SeriousNotification({
    required this.message,
    required this.isError,
    required this.isDark,
    required this.duration,
    required this.onDismiss,
  });

  @override
  __SeriousNotificationState createState() => __SeriousNotificationState();
}

class __SeriousNotificationState extends State<_SeriousNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
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
            elevation: 4, // Reduced elevation for a more professional look
            borderRadius: BorderRadius.circular(8), // Smaller radius for a sharper look
            child: Container(
              width: 220, // Fixed width of 220 pixels
              padding: const EdgeInsets.all(16), // Slightly tighter padding
              height: 80, // Reduced height for a more compact look
              decoration: BoxDecoration(
                color: widget.isError
                    ? const Color(0xFFFF6666) // Red from screenshot
                    : const Color(0xFF00CC66), // Green from screenshot
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDark ? AppColors.darkShadow : AppColors.lightShadow,
                    blurRadius: 4, // Reduced blur for a sharper shadow
                    offset: const Offset(0, 2), // More subtle offset
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isError ? Icons.error : Icons.check_circle, // More professional icons
                    color: Colors.white,
                    size: 24, // Slightly smaller icon
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppTextStyles.body(context).copyWith(
                        color: Colors.white,
                        fontSize: 16, // Slightly smaller font size
                        fontWeight: FontWeight.w600, // Semi-bold for a serious tone
                        fontFamily: 'Roboto', // Professional font
                        // Removed text shadow for a cleaner look
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