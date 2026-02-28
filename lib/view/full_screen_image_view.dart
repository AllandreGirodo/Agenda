import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final String url;
  final String? heroTag;

  const FullScreenImageView({super.key, required this.url, this.heroTag});

  @override
  Widget build(BuildContext context) {
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
                child: InteractiveViewer(
                  child: Image.network(url),
                ),
              )
            : InteractiveViewer(
                child: Image.network(url),
              ),
      ),
    );
  }
}