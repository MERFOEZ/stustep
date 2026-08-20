import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// معرض صور السكن مع مؤشّرات الصفحات.
///
/// فُصل عن شاشة التفاصيل لإبقائها تحت سقف الثلاثمئة سطر المتفق عليه في
/// مستند التحليل، ولأن المعرض وحدة بصرية مستقلة قد تُعاد في شاشة تعديل
/// الإعلان لاحقاً.
class HousingGallery extends StatefulWidget {
  final List<String> images;
  final double height;

  const HousingGallery({
    super.key,
    required this.images,
    this.height = 240,
  });

  @override
  State<HousingGallery> createState() => _HousingGalleryState();
}

class _HousingGalleryState extends State<HousingGallery> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return _buildPlaceholder(context);

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: widget.images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, _) =>
                  Container(color: Colors.grey.withValues(alpha: 0.15)),
              errorWidget: (_, _, _) => Container(
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Icon(Icons.broken_image_outlined, size: 40),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: _buildIndicators(),
            ),
        ],
      ),
    );
  }

  /// حالة السكن بلا صور — أيقونة بلون الهوية بدل مساحة فارغة مربكة.
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
      child: Icon(
        Icons.home_work_outlined,
        size: 64,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.images.length, (index) {
        final isActive = index == _current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
