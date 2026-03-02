import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final String url;
  final String? heroTag; // Garanta que este parâmetro existe

  const FullScreenImageView({super.key, required this.url, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = InteractiveViewer(
      child: Image.network(
        url,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: heroTag != null
            ? Hero(
                tag: heroTag!,
                child: imageWidget,
              )
            : imageWidget,
      ),
    );
  }
}