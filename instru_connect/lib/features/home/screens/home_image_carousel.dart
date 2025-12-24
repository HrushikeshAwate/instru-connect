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
    'https://theharekrishnamovement.org/wp-content/uploads/2013/05/sri-sri-radha-madhava.jpg',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTsrb8AIbMVFCV6rg547azt2EHoU71VDskPNg&s',
    'https://i.pinimg.com/736x/1c/e6/ff/1ce6ff2a121125b2f24c02ced048dc76.jpg',
    'https://live.staticflickr.com/5523/11432062175_f6e1c87a6c.jpg',
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
