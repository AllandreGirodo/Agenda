import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final String url;
  const FullScreenImageView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(child: Image.network(url)),
      ),
    );
  }
}