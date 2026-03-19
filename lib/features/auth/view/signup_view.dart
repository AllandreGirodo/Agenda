import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agenda/features/auth/controller/login_controller.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/core/widgets/language_selector.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/core/utils/validadores.dart';
import 'package:agenda/core/utils/international_phone_input_formatter.dart';
import 'package:agenda/main.dart';
import 'package:agenda/view/termos_uso_view.dart';

class SignUpView extends StatefulWidget {
  final String ddiPadrao;
  final int maxPhoneDigits;

  const SignUpView({
    super.key,
    this.ddiPadrao = InternationalPhoneInputFormatter.defaultDdi,
    this.maxPhoneDigits = InternationalPhoneInputFormatter.defaultMaxLocalDigits,
  });

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _whatsappFocusNode = FocusNode();
  final _senhaFocusNode = FocusNode();
  final _controller = LoginController();
  bool _isWhatsappNumber = true;
  bool _lgpdConsentido = false;
  bool _senhaVisivel = false;
  bool _phoneHasInvalidInput = false;
  bool _limiteCelularAtingidoAnterior = false;
  bool _mostrarAvisoLimiteCelular = false;
  bool _avisoLimiteCelularVisivel = false;
  bool _avisoTermosVisivel = true;
  Timer? _timerFadeLimiteCelular;
  Timer? _timerOcultarLimiteCelular;
  Timer? _timerFadeAvisoTermos;

  String get _ddiPadrao {
    return InternationalPhoneInputFormatter.normalizeDdi(widget.ddiPadrao);
  }

  int get _maxPhoneDigits {
    return InternationalPhoneInputFormatter.normalizeMaxLocalDigits(
      widget.maxPhoneDigits,
      fallback: InternationalPhoneInputFormatter.defaultMaxLocalDigits,
    );
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refreshFormState);
    _senhaController.addListener(_refreshFormState);
    _whatsappController.addListener(_refreshFormState);
    _whatsappFocusNode.addListener(_refreshFormState);
    _senhaFocusNode.addListener(_refreshFormState);
  }

  @override
  void dispose() {
    _timerFadeLimiteCelular?.cancel();
    _timerOcultarLimiteCelular?.cancel();
    _timerFadeAvisoTermos?.cancel();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _whatsappController.dispose();
    _whatsappFocusNode.dispose();
    _senhaFocusNode.dispose();
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
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final phoneDigits = _countPhoneDigits(_whatsappController.text);
    final senha = _senhaController.text;
    final nomeValido = nome.isNotEmpty;
    final emailValido = email.isNotEmpty && Validadores.isEmailValido(email);
    final numeroLabel = _isWhatsappNumber
        ? localizations.whatsappLabel
        : localizations.phoneNumberLabel;
    final emailInvalidoDigitando = email.isNotEmpty && !Validadores.isEmailValido(email);
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
    final podeCadastrar = senhaValida;
    final currentLocale = Localizations.localeOf(context);
    final placeholderTelefone =
      _ddiPadrao == InternationalPhoneInputFormatter.defaultDdi
      ? '(16) 99999-9999'
      : '999 999 999';
    final emojiDdi =
      _ddiPadrao == InternationalPhoneInputFormatter.defaultDdi
      ? '🇧🇷'
      : '🌍';

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
            const Icon(Icons.person_add, size: 30, color: Colors.teal),
            const SizedBox(height: 20),
            TextField(
              controller: _nomeController,
              maxLength: 70,
              inputFormatters: [LengthLimitingTextInputFormatter(70)],
              decoration: InputDecoration(
                labelText: localizations.fullNameLabel,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  nomeValido ? Icons.person : Icons.person_outline,
                  color: nomeValido
                      ? Colors.green.shade600
                      : Colors.grey.shade400,
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              maxLength: 50,
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
              decoration: InputDecoration(
                labelText: localizations.emailLabel,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  emailValido ? Icons.mark_email_read_outlined : Icons.email_outlined,
                  color: emailValido
                      ? Colors.green.shade600
                      : Colors.grey.shade400,
                ),
                counterText: '',
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
            TextField(
              controller: _whatsappController,
              focusNode: _whatsappFocusNode,
              decoration: InputDecoration(
                labelText: numeroLabel,
                hintText: placeholderTelefone,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  _isWhatsappNumber ? Icons.perm_phone_msg : Icons.phone,
                  color: _isWhatsappNumber
                      ? (limiteCelularAtingido
                          ? Colors.green.shade600
                          : Colors.grey.shade400)
                      : null,
                ),
                prefix: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emojiDdi, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '+$_ddiPadrao',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                InternationalPhoneInputFormatter(
                  ddi: _ddiPadrao,
                  maxLocalDigits: _maxPhoneDigits,
                  onInvalidInputChanged: (hasInvalidInput) {
                    if (_phoneHasInvalidInput != hasInvalidInput) {
                      setState(() {
                        _phoneHasInvalidInput = hasInvalidInput;
                      });
                    }
                  },
                ),
              ],
              style: whatsappTextStyle,
            ),
            if (_phoneHasInvalidInput)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localizations.signupPhoneOnlyDigitsMessage,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
            if (!_phoneHasInvalidInput &&
                !limiteCelularAtingido &&
                phoneDigits > 0 &&
                phoneDigits < 10)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localizations.signupPhoneMinDigitsMessage,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
            if (_mostrarAvisoLimiteCelular)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    opacity: _avisoLimiteCelularVisivel ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      localizations.signupPhoneDigitsLimitReached,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
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
              focusNode: _senhaFocusNode,
              maxLength: 20,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              decoration: InputDecoration(
                labelText: localizations.passwordLabel,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  senhaValida ? Icons.lock_open_outlined : Icons.lock_outline,
                  color: senhaValida
                      ? Colors.green.shade600
                      : Colors.grey.shade400,
                ),
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _senhaVisivel = !_senhaVisivel;
                    });
                  },
                ),
              ),
              obscureText: !_senhaVisivel,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _senhaFocusNode.hasFocus || senha.isNotEmpty
                    ? 1.0
                    : 0.0,
                duration: const Duration(milliseconds: 220),
                child: _senhaFocusNode.hasFocus || senha.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: senhaValida
                              ? Row(
                                  key: const ValueKey('senha_valida_feedback'),
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        localizations
                                            .signupPasswordReadyMessage,
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  key: const ValueKey('senha_regras_feedback'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizations.signupPasswordCriteriaTitle,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.75),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _PasswordRuleItem(
                                      text: localizations
                                          .signupPasswordRuleLength,
                                      ok: senhaTemTamanhoValido,
                                    ),
                                    _PasswordRuleItem(
                                      text: localizations
                                          .signupPasswordRuleUppercase,
                                      ok: senhaTemMaiuscula,
                                    ),
                                    _PasswordRuleItem(
                                      text: localizations
                                          .signupPasswordRuleLowercase,
                                      ok: senhaTemMinuscula,
                                    ),
                                    _PasswordRuleItem(
                                      text: localizations
                                          .signupPasswordRuleNumber,
                                      ok: senhaTemNumero,
                                    ),
                                    _PasswordRuleItem(
                                      text:
                                          '${localizations.signupPasswordRuleSpecial}  ex: ! @ # \$ % & *',
                                      ok: senhaTemEspecial,
                                    ),
                                  ],
                                ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final aceitouTermos = await _abrirTermosEPrivacidade();
                  if (!mounted || !aceitouTermos) return;
                  _atualizarConsentimentoLgpd(true);
                },
                icon: const Icon(Icons.description_outlined),
                label: Text(localizations.signupTermsReadButton),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            CheckboxListTile(
              value: _lgpdConsentido,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                localizations.signupLgpdConsentLabel,
                style: const TextStyle(fontSize: 10),
              ),
              onChanged: (value) async {
                if (!(value ?? false)) {
                  _atualizarConsentimentoLgpd(false);
                  return;
                }

                final aceitouTermos = await _abrirTermosEPrivacidade();
                if (!mounted) return;
                _atualizarConsentimentoLgpd(aceitouTermos);
              },
            ),
            const SizedBox(height: 24),
            // Seletor de idioma no final
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.language, size: 18, color: Colors.teal),
                const SizedBox(width: 6),
                Text(
                  AppStrings.labelIdioma,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _LanguageFlagButton(
                  flag: '🇧🇷',
                  label: 'PT',
                  locale: const Locale('pt', 'BR'),
                  small: true,
                ),
                const SizedBox(width: 6),
                _LanguageFlagButton(
                  flag: '🇺🇸',
                  label: 'EN',
                  locale: const Locale('en', 'US'),
                  small: true,
                ),
                const SizedBox(width: 6),
                _LanguageFlagButton(
                  flag: '🇪🇸',
                  label: 'ES',
                  locale: const Locale('es', 'ES'),
                  small: true,
                ),
                const SizedBox(width: 6),
                _LanguageFlagButton(
                  flag: '🇫🇷',
                  label: 'FR',
                  locale: const Locale('fr', 'FR'),
                  small: true,
                ),
                const SizedBox(width: 6),
                _LanguageFlagButton(
                  flag: '🇯🇵',
                  label: 'JP',
                  locale: const Locale('ja', 'JP'),
                  small: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: AnimatedOpacity(
                opacity: _avisoTermosVisivel ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _lgpdConsentido
                      ? localizations.signupLgpdConsentAcceptedMessage
                      : localizations.signupLgpdConsentPendingMessage,
                  style: TextStyle(
                    color: _lgpdConsentido
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: podeCadastrar
                    ? () async {
                        final nome = _nomeController.text.trim();
                        final emailValido = Validadores.isEmailValido(email);
                        final motivos = <String>[];

                        if (nome.isEmpty) {
                          motivos.add('nome_obrigatorio');
                        }
                        if (!emailValido) {
                          motivos.add('email_invalido_regex');
                        }
                        if (_phoneHasInvalidInput) {
                          motivos.add('telefone_caracter_invalido');
                        }
                        if (phoneDigits < 10) {
                          motivos.add('telefone_minimo_digitos');
                        }
                        if (!senhaValida) {
                          motivos.add('senha_fraca');
                        }
                        if (!_lgpdConsentido) {
                          motivos.add('lgpd_nao_consentido');
                        }

                        if (motivos.isNotEmpty) {
                          await _controller.auditarTentativaCredencial(
                            origem: 'cadastro_formulario',
                            emailDigitado: email,
                            senhaInformada: senha,
                            inconformidade: true,
                            lgpdConsentido: _lgpdConsentido,
                            motivos: motivos,
                            nomeClienteDigitado: nome,
                            emailValido: emailValido,
                            senhaForte: senhaValida,
                          );

                          if (!mounted) return;

                          final mensagem = nome.isEmpty
                              ? localizations.signupNameRequiredMessage
                              : !emailValido
                              ? localizations.signupInvalidEmailTyping
                              : _phoneHasInvalidInput
                              ? localizations.signupPhoneOnlyDigitsMessage
                              : phoneDigits < 10
                              ? localizations.signupPhoneMinDigitsSubmitMessage(
                                  numeroLabel,
                                )
                              : !senhaValida
                              ? localizations.signupPasswordWeakMessage
                              : localizations.signupLgpdConsentError;

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(mensagem)));
                          return;
                        }

                        await _controller.cadastrar(
                          context,
                          nome,
                          email,
                          senha,
                          InternationalPhoneInputFormatter.localDigits(
                            _whatsappController.text,
                            ddi: _ddiPadrao,
                            maxLocalDigits: _maxPhoneDigits,
                          ),
                          _isWhatsappNumber,
                          _lgpdConsentido,
                          currentLocale.languageCode,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.white70,
                ),
                child: Text(localizations.registerButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countPhoneDigits(String value) {
    return InternationalPhoneInputFormatter.localDigits(
      value,
      ddi: _ddiPadrao,
      maxLocalDigits: _maxPhoneDigits,
    ).length;
  }

  Future<bool> _abrirTermosEPrivacidade() async {
    final aceitouTermos = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const TermosUsoView()));

    return aceitouTermos ?? false;
  }

  void _refreshFormState() {
    final limiteCelularAtingidoAgora =
        _countPhoneDigits(_whatsappController.text) >= _maxPhoneDigits;

    if (limiteCelularAtingidoAgora && !_limiteCelularAtingidoAnterior) {
      _exibirAvisoLimiteCelularComFade();
    }

    if (!limiteCelularAtingidoAgora && _mostrarAvisoLimiteCelular) {
      _timerFadeLimiteCelular?.cancel();
      _timerOcultarLimiteCelular?.cancel();
      _mostrarAvisoLimiteCelular = false;
      _avisoLimiteCelularVisivel = false;
    }

    _limiteCelularAtingidoAnterior = limiteCelularAtingidoAgora;

    if (mounted) {
      setState(() {});
    }
  }

  void _exibirAvisoLimiteCelularComFade() {
    _timerFadeLimiteCelular?.cancel();
    _timerOcultarLimiteCelular?.cancel();

    _mostrarAvisoLimiteCelular = true;
    _avisoLimiteCelularVisivel = true;

    _timerFadeLimiteCelular = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() {
        _avisoLimiteCelularVisivel = false;
      });

      _timerOcultarLimiteCelular = Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _mostrarAvisoLimiteCelular = false;
        });
      });
    });
  }

  void _atualizarConsentimentoLgpd(bool consentiu) {
    if (!mounted) return;
    setState(() {
      _lgpdConsentido = consentiu;
    });

    _animarAvisoTermosComFade();
  }

  void _animarAvisoTermosComFade() {
    _timerFadeAvisoTermos?.cancel();
    if (!mounted) return;

    setState(() {
      _avisoTermosVisivel = false;
    });

    _timerFadeAvisoTermos = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        _avisoTermosVisivel = true;
      });
    });
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

class _LanguageFlagButton extends StatelessWidget {
  final String flag;
  final String label;
  final Locale locale;
  final bool small;

  const _LanguageFlagButton({
    required this.flag,
    required this.label,
    required this.locale,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isSelected = currentLocale.languageCode == locale.languageCode;

    if (small) {
      return InkWell(
        onTap: () {
          MyApp.setLocale(context, locale);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.teal : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: isSelected ? Colors.teal.shade50 : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.teal : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        MyApp.setLocale(context, locale);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.teal.shade50 : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.teal : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
