import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agenda/features/auth/controller/login_controller.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/core/widgets/language_selector.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  static const String _whatsappMaskPlaceholder = '(00) 00000-0000';
  static const int _maxPhoneDigits = 11;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _whatsappFocusNode = FocusNode();
  final _controller = LoginController();
  bool _isWhatsappNumber = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refreshFormState);
    _senhaController.addListener(_refreshFormState);
    _whatsappController.addListener(_refreshFormState);
    _whatsappFocusNode.addListener(_refreshFormState);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _whatsappController.dispose();
    _whatsappFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final whatsappTextStyle = theme.textTheme.titleMedium?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final email = _emailController.text.trim();
    final phoneDigits = _countPhoneDigits(_whatsappController.text);
    final senha = _senhaController.text;
    final numeroLabel = _isWhatsappNumber
        ? localizations.whatsappLabel
        : localizations.phoneNumberLabel;
    final mostrarMascaraWhatsapp =
        _whatsappFocusNode.hasFocus || _whatsappController.text.isNotEmpty;
    final mascaraComZerosRestantes = _maskedBackgroundWithTypedPositions(
      _whatsappController.text,
    );
    final emailInvalidoDigitando = email.isNotEmpty && !_isValidEmail(email);
    final limiteCelularAtingido = phoneDigits >= _maxPhoneDigits;
    final senhaTemTamanhoValido = senha.length >= 6 && senha.length <= 20;
    final senhaTemMaiuscula = RegExp(r'[A-Z]').hasMatch(senha);
    final senhaTemMinuscula = RegExp(r'[a-z]').hasMatch(senha);
    final senhaTemNumero = RegExp(r'[0-9]').hasMatch(senha);
    final senhaTemEspecial = RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/+=~`]',
    ).hasMatch(senha);
    final senhaValida =
        senhaTemTamanhoValido &&
        senhaTemMaiuscula &&
        senhaTemMinuscula &&
        senhaTemNumero &&
        senhaTemEspecial;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.signupTitle),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: const [LanguageSelector()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 60, color: Colors.teal),
            const SizedBox(height: 20),
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: localizations.fullNameLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: localizations.emailLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            if (emailInvalidoDigitando)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localizations.signupInvalidEmailTyping,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Stack(
              children: [
                if (mostrarMascaraWhatsapp)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(48, 16, 12, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            mascaraComZerosRestantes,
                            style: whatsappTextStyle?.copyWith(
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                TextField(
                  controller: _whatsappController,
                  focusNode: _whatsappFocusNode,
                  decoration: InputDecoration(
                    labelText: numeroLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: const [_WhatsappInputFormatter()],
                  style: whatsappTextStyle,
                ),
              ],
            ),
            if (limiteCelularAtingido)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localizations.signupPhoneDigitsLimitReached,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
            CheckboxListTile(
              value: _isWhatsappNumber,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                _isWhatsappNumber
                    ? localizations.isWhatsappNumber
                    : localizations.isNotWhatsappNumber,
              ),
              onChanged: (value) {
                setState(() {
                  _isWhatsappNumber = value ?? true;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senhaController,
              decoration: InputDecoration(
                labelText: localizations.passwordLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                localizations.signupPasswordCriteriaTitle,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _PasswordRuleItem(
              text: localizations.signupPasswordRuleLength,
              ok: senhaTemTamanhoValido,
            ),
            _PasswordRuleItem(
              text: localizations.signupPasswordRuleUppercase,
              ok: senhaTemMaiuscula,
            ),
            _PasswordRuleItem(
              text: localizations.signupPasswordRuleLowercase,
              ok: senhaTemMinuscula,
            ),
            _PasswordRuleItem(
              text: localizations.signupPasswordRuleNumber,
              ok: senhaTemNumero,
            ),
            _PasswordRuleItem(
              text: localizations.signupPasswordRuleSpecial,
              ok: senhaTemEspecial,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (!_isValidEmail(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.signupInvalidEmailTyping),
                      ),
                    );
                    return;
                  }

                  if (!senhaValida) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.signupPasswordWeakMessage),
                      ),
                    );
                    return;
                  }

                  _controller.cadastrar(
                    context,
                    _nomeController.text,
                    email,
                    senha,
                    _whatsappController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                    _isWhatsappNumber,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: Text(localizations.registerButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _maskedBackgroundWithTypedPositions(String formattedValue) {
    final placeholderChars = _whatsappMaskPlaceholder.split('');
    final typedChars = formattedValue.split('');
    final limit = typedChars.length < placeholderChars.length
        ? typedChars.length
        : placeholderChars.length;

    for (var i = 0; i < limit; i++) {
      if (_isDigitChar(typedChars[i]) && placeholderChars[i] == '0') {
        placeholderChars[i] = ' ';
      }
    }

    return placeholderChars.join();
  }

  bool _isDigitChar(String value) {
    if (value.isEmpty) return false;
    final code = value.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  int _countPhoneDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '').length;
  }

  bool _isValidEmail(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
  }

  void _refreshFormState() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _PasswordRuleItem extends StatelessWidget {
  final String text;
  final bool ok;

  const _PasswordRuleItem({required this.text, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.green.shade700 : Colors.red.shade700;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}

class _WhatsappInputFormatter extends TextInputFormatter {
  const _WhatsappInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitedDigits = digitsOnly.length > 11
        ? digitsOnly.substring(0, 11)
        : digitsOnly;
    final formatted = _formatWhatsapp(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWhatsapp(String digits) {
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();

    buffer.write('(');
    if (digits.length <= 2) {
      buffer.write(digits);
      return buffer.toString();
    }

    buffer.write(digits.substring(0, 2));
    buffer.write(') ');

    if (digits.length <= 7) {
      buffer.write(digits.substring(2));
      return buffer.toString();
    }

    if (digits.length <= 10) {
      buffer.write(digits.substring(2, 6));
      buffer.write('-');
      buffer.write(digits.substring(6));
      return buffer.toString();
    }

    buffer.write(digits.substring(2, 7));
    buffer.write('-');
    buffer.write(digits.substring(7));
    return buffer.toString();
  }
}
