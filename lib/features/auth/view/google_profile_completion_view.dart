import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/core/utils/international_phone_input_formatter.dart';
import 'package:agenda/core/widgets/language_selector.dart';
import 'package:agenda/view/termos_uso_view.dart';

typedef CompletarCadastroGoogleSalvar = Future<bool> Function(
  BuildContext context,
  String nome,
  String whatsapp,
  bool numeroEhWhatsapp,
  String? locale,
);

class GoogleProfileCompletionView extends StatefulWidget {
  final String nomeInicial;
  final String email;
  final String whatsappInicial;
  final bool numeroEhWhatsappInicial;
  final CompletarCadastroGoogleSalvar onSalvar;
  final String ddiPadrao;
  final int maxPhoneDigits;

  const GoogleProfileCompletionView({
    super.key,
    required this.nomeInicial,
    required this.email,
    required this.whatsappInicial,
    required this.numeroEhWhatsappInicial,
    required this.onSalvar,
    this.ddiPadrao = InternationalPhoneInputFormatter.defaultDdi,
    this.maxPhoneDigits = InternationalPhoneInputFormatter.defaultMaxLocalDigits,
  });

  @override
  State<GoogleProfileCompletionView> createState() =>
      _GoogleProfileCompletionViewState();
}

class _GoogleProfileCompletionViewState extends State<GoogleProfileCompletionView> {
  final _nomeController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _isWhatsappNumber = true;
  bool _lgpdConsentido = false;
  bool _isSaving = false;
  bool _phoneHasInvalidInput = false;

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

    _nomeController.text = widget.nomeInicial.trim();
    final whatsappLocal = InternationalPhoneInputFormatter.localDigits(
      widget.whatsappInicial,
      ddi: _ddiPadrao,
      maxLocalDigits: _maxPhoneDigits,
    );
    _whatsappController.text = InternationalPhoneInputFormatter.formatLocal(
      whatsappLocal,
      ddi: _ddiPadrao,
      maxLocalDigits: _maxPhoneDigits,
    );
    _isWhatsappNumber = widget.numeroEhWhatsappInicial;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _whatsappController.dispose();
    super.dispose();
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

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    final telefone = InternationalPhoneInputFormatter.localDigits(
      _whatsappController.text,
      ddi: _ddiPadrao,
      maxLocalDigits: _maxPhoneDigits,
    );

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.googleCadastroNomeObrigatorio)),
      );
      return;
    }

    if (_phoneHasInvalidInput || telefone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.googleCadastroTelefoneInvalido)),
      );
      return;
    }

    if (!_lgpdConsentido) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.googleCadastroLgpdObrigatorio)),
      );
      return;
    }

    setState(() => _isSaving = true);
    final locale = Localizations.localeOf(context).languageCode;

    try {
      await widget.onSalvar(
        context,
        nome,
        telefone,
        _isWhatsappNumber,
        locale,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneDigits = _countPhoneDigits(_whatsappController.text);
    final limiteCelularAtingido = phoneDigits >= _maxPhoneDigits;
    final placeholderTelefone =
        _ddiPadrao == InternationalPhoneInputFormatter.defaultDdi
        ? '(16) 99999-9999'
        : '999 999 999';
    final codigoDdi =
      _ddiPadrao == InternationalPhoneInputFormatter.defaultDdi ? 'BR' : 'INTL';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.googleCadastroComplementarTitulo),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: const [LanguageSelector()],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.person_add_alt_1, size: 44, color: Colors.teal),
            const SizedBox(height: 16),
            Text(
              AppStrings.googleCadastroComplementarDescricao,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nomeController,
              maxLength: 70,
              inputFormatters: [LengthLimitingTextInputFormatter(70)],
              decoration: InputDecoration(
                labelText: AppStrings.fullNameLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.email,
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                labelText: AppStrings.emailLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _whatsappController,
              decoration: InputDecoration(
                labelText: AppStrings.whatsappLabel,
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
                      Text(codigoDdi, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '+$_ddiPadrao',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.75),
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
            ),
            if (_phoneHasInvalidInput || (phoneDigits > 0 && phoneDigits < 10))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.googleCadastroTelefoneInvalido,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
            CheckboxListTile(
              value: _isWhatsappNumber,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(AppStrings.googleCadastroNumeroEhWhatsapp),
              onChanged: (value) {
                setState(() {
                  _isWhatsappNumber = value ?? true;
                });
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final aceitouTermos = await _abrirTermosEPrivacidade();
                  if (!mounted || !aceitouTermos) return;
                  setState(() => _lgpdConsentido = true);
                },
                icon: const Icon(Icons.description_outlined),
                label: Text(AppStrings.googleCadastroLerTermos),
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
                AppStrings.termosUsoAceite,
                style: const TextStyle(fontSize: 13),
              ),
              onChanged: (value) async {
                if (!(value ?? false)) {
                  setState(() => _lgpdConsentido = false);
                  return;
                }

                final aceitouTermos = await _abrirTermosEPrivacidade();
                if (!mounted) return;
                setState(() => _lgpdConsentido = aceitouTermos);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(AppStrings.salvarContinuar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
