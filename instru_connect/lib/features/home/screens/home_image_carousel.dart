// features/home/screens/home_image_carousel.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:instru_connect/config/theme/ui_colors.dart';

class HomeImageCarousel extends StatefulWidget {
  const HomeImageCarousel({super.key});

  @override
  State<HomeImageCarousel> createState() => _HomeImageCarouselState();
}

class _HomeImageCarouselState extends State<HomeImageCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  Timer? _timer;

  final List<String> images = const [
    'https://www.coeptech.ac.in/wp-content/uploads/2024/06/Dept-Photo-1024x683.jpeg',
    'https://www.coeptech.ac.in/wp-content/uploads/elementor/thumbs/COEP-Website-Pic-1-r4qfk1ygvn7y9y1tf4vppvonlurjzsbf6jrltou9w8.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _currentPage = (_currentPage + 1) % images.length;
      if (_controller.hasClients) {
        _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_controller.position.haveDimensions) {
                    scale = (_controller.page! - index).abs();
                    scale = (1 - scale * 0.12).clamp(0.88, 1.0);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.40 : 0.20,
                        ),
                        blurRadius: 26,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Theme.of(context).cardColor,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: UIColors.primary.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Theme.of(context).cardColor,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  size: 40,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Unable to load image',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Multi-layer cinematic gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                UIColors.deepTeal.withValues(alpha: 0.25),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),

                        // Subtle color wash
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Premium indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            final bool active = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 7,
              width: active ? 24 : 8,
              decoration: BoxDecoration(
                gradient: active ? UIColors.primaryGradient : null,
                color: active
                    ? null
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }
}
