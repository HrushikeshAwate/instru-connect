import 'package:flutter/material.dart';

class HomeImageCarousel extends StatefulWidget {
  const HomeImageCarousel({super.key});

  @override
  State<HomeImageCarousel> createState() => _HomeImageCarouselState();
}

class _HomeImageCarouselState extends State<HomeImageCarousel> {
  final PageController _controller =
      PageController(viewportFraction: 0.92);

  final List<String> images = const [
    'https://www.coeptech.ac.in/wp-content/uploads/2024/06/Dept-Photo-1024x683.jpeg',
    'https://www.coeptech.ac.in/wp-content/uploads/elementor/thumbs/COEP-Website-Pic-1-r4qfk1ygvn7y9y1tf4vppvonlurjzsbf6jrltou9w8.jpg'
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220, // compact, non-dominating
      child: PageView.builder(
        controller: _controller,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,

                // 🔒 NO BACKGROUND, NO PLACEHOLDER
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox.shrink();
                },

                // Optional: fail silently if image breaks
                errorBuilder: (_, __, ___) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
