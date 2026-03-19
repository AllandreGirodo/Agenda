import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/core/utils/app_styles.dart';
import 'package:agenda/features/auth/view/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Set<PointerDeviceKind> _dragDevices = {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };

  String get _instagramAdminUrl {
    try {
      return (dotenv.env['INSTAGRAM_ADMIN'] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  Future<void> _abrirInstagramAdmin() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final link = _instagramAdminUrl;

    if (link.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.onboardingInstagramNaoDisponivel)),
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.onboardingInstagramNaoDisponivel)),
      );
      return;
    }

    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.onboardingInstagramNaoAbriu)),
      );
    }
  }

  Widget _buildImagemCircularComBorda(
    String imagePath, {
    Alignment alignment = Alignment.center,
    double size = 210,
    bool comAurora = false,
  }) {
    final image = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: alignment,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  size: 56,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),
      ),
    );

    if (!comAurora) {
      return image;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: AuroraBorderPainter(imageSize: size),
          size: Size(size + 60, size + 60),
        ),
        image,
      ],
    );
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_OnboardingPageData> pages = [
      _OnboardingPageData(
        title: AppStrings.onboardingTitulo1,
        text: AppStrings.onboardingTexto1,
        imagePath: 'assets/Logo.jpg',
      ),
      _OnboardingPageData(
        title: AppStrings.onboardingTitulo2,
        text: AppStrings.onboardingTexto2,
        imagePath: 'assets/Aparelho.jfif',
        imageAlignment: Alignment.topCenter,
        exibirLinkInstagram: true,
      ),
      _OnboardingPageData(
        title: AppStrings.onboardingTitulo3,
        text: AppStrings.onboardingTexto3,
        imagePath: 'assets/Representando.jfif',
        imageAlignment: Alignment.topCenter,
        imageSize: 260,
        comAurora: true,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(dragDevices: _dragDevices),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final isLastPage = index == pages.length - 1;
                    final page = Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildImagemCircularComBorda(
                            pages[index].imagePath,
                            alignment: pages[index].imageAlignment,
                            size: pages[index].imageSize,
                            comAurora: pages[index].comAurora,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            pages[index].title,
                            style: AppStyles.title.copyWith(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            pages[index].text,
                            style: AppStyles.body.copyWith(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          if (pages[index].exibirLinkInstagram) ...[
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: _abrirInstagramAdmin,
                              icon: const Icon(Icons.open_in_new),
                              label: Text(AppStrings.onboardingInstagramBtn),
                            ),
                          ],
                        ],
                      ),
                    );
                    
                    if (isLastPage) {
                      return GestureDetector(
                        onTap: _finishOnboarding,
                        child: page,
                      );
                    }
                    
                    return page;
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  AppStrings.onboardingDicaArraste(_currentPage, pages.length),
                  key: ValueKey<int>(_currentPage),
                  style: AppStyles.body.copyWith(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.primaryButton,
                  onPressed: _finishOnboarding,
                  child: Text(
                    _currentPage == pages.length - 1
                        ? AppStrings.comecarBtn
                        : AppStrings.pularBtn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuroraBorderPainter extends CustomPainter {
  final double imageSize;

  AuroraBorderPainter({required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.teal.withValues(alpha: 0.15),
          Colors.cyan.withValues(alpha: 0.15),
          Colors.purple.shade200.withValues(alpha: 0.15),
          Colors.teal.withValues(alpha: 0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.33, 0.66, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (imageSize / 2) + 25;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(AuroraBorderPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize;
  }
}

class _OnboardingPageData {
  final String title;
  final String text;
  final String imagePath;
  final Alignment imageAlignment;
  final double imageSize;
  final bool exibirLinkInstagram;
  final bool comAurora;

  const _OnboardingPageData({
    required this.title,
    required this.text,
    required this.imagePath,
    this.imageAlignment = Alignment.center,
    this.imageSize = 210,
    this.exibirLinkInstagram = false,
    this.comAurora = false,
  });
}
