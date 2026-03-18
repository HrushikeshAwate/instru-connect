import 'package:flutter/material.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';

class AnimatedSplashLoader extends StatefulWidget {
  final String title;
  final String subtitle;

  const AnimatedSplashLoader({
    super.key,
    this.title = 'InstruConnect',
    this.subtitle = 'Instrumentation Department',
  });

  @override
  State<AnimatedSplashLoader> createState() => _AnimatedSplashLoaderState();
}

class _AnimatedSplashLoaderState extends State<AnimatedSplashLoader>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _textController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringFade;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.04).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 55,
      ),
    ]).animate(_pulseController);

    _logoFade = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.0, 0.4)),
    );

    _titleSlide = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
      ),
    );

    _ringScale = Tween<double>(begin: 0.8, end: 1.35).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _ringFade = Tween<double>(begin: 0.28, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _textController]),
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                UIColors.primary.withValues(alpha: 0.08),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: _ringScale.value,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: UIColors.primary.withValues(
                              alpha: _ringFade.value,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoFade.value,
                        child: Container(
                          padding: const EdgeInsets.all(26),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/logo/ic_logo.png',
                            width: 52,
                            height: 52,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.school_outlined,
                                size: 46,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Transform.translate(
                  offset: Offset(0, _titleSlide.value),
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: _subtitleFade.value,
                  child: Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      UIColors.primary.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
