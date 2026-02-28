import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda/view/app_strings.dart';
import 'package:agenda/view/app_styles.dart';
import 'package:agenda/view/login_view.dart';
import 'package:lottie/lottie.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
  Widget build(BuildContext context) {
    final List<Map<String, String>> pages = [
      {
        'title': AppStrings.onboardingTitulo1,
        'text': AppStrings.onboardingTexto1,
        'lottie': 'https://lottie.host/56e70336-7013-4029-9138-031037567669/7j7Yj2Z2j2.json', // Relax/Spa
      },
      {
        'title': AppStrings.onboardingTitulo2,
        'text': AppStrings.onboardingTexto2,
        'lottie': 'https://assets9.lottiefiles.com/packages/lf20_s8pbrcfw.json', // Notification Bell
      },
      {
        'title': AppStrings.onboardingTitulo3,
        'text': AppStrings.onboardingTexto3,
        'lottie': 'https://assets2.lottiefiles.com/packages/lf20_49rdyysj.json', // History/List
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent, // Para ver o fundo animado
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.network(
                          pages[index]['lottie']!,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.spa, size: 100, color: AppColors.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          pages[index]['title']!,
                          style: AppStyles.title.copyWith(fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          pages[index]['text']!,
                          style: AppStyles.body.copyWith(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) => 
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primary : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.primaryButton,
                  onPressed: _finishOnboarding,
                  child: Text(_currentPage == pages.length - 1 ? AppStrings.comecarBtn : AppStrings.pularBtn),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}