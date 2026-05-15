import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Contraseña real; el [TextEditingController.text] expuesto es solo bullets.
class ObscuredPasswordEditingController extends TextEditingController {
  static const String _bullet = '•';

  String _secret = '';

  String get secret => _secret;

  @override
  String get text => _secret;

  @override
  set text(String value) {
    _secret = value;
    super.value = TextEditingValue(
      text: _bullet * _secret.length,
      selection: TextSelection.collapsed(offset: _secret.length),
    );
  }

  void applySecret(String secret, {required int selectionOffset}) {
    _secret = secret;
    final masked = _bullet * _secret.length;
    super.value = TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(
        offset: selectionOffset.clamp(0, masked.length),
      ),
    );
  }
}

class _ImmediatePasswordMaskFormatter extends TextInputFormatter {
  _ImmediatePasswordMaskFormatter(this._controller);

  final ObscuredPasswordEditingController _controller;
  static const String _bullet = '•';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final secret = _controller.secret;
    final oldMasked = _bullet * secret.length;

    if (newValue.text == oldMasked && newValue.selection == oldValue.selection) {
      return newValue;
    }

    final newText = newValue.text;
    final sel = newValue.selection;

    if (newText.length < oldMasked.length) {
      final removed = oldMasked.length - newText.length;
      final start = sel.baseOffset.clamp(0, secret.length);
      final end = (start + removed).clamp(0, secret.length);
      final updated = secret.substring(0, start) + secret.substring(end);
      _controller.applySecret(updated, selectionOffset: start);
      return _controller.value;
    }

    if (newText.length > oldMasked.length) {
      final added = newText.length - oldMasked.length;
      final insertAt = (sel.baseOffset - added).clamp(0, secret.length);
      final chunk = newText.substring(insertAt, insertAt + added);
      final plain = chunk.replaceAll(_bullet, '');
      final updated =
          secret.substring(0, insertAt) + plain + secret.substring(insertAt);
      _controller.applySecret(
        updated,
        selectionOffset: insertAt + plain.length,
      );
      return _controller.value;
    }

    // Mismo largo: sustitución (p. ej. selección + escribir).
    if (newText != oldMasked) {
      final plain = newText.replaceAll(_bullet, '');
      _controller.applySecret(plain, selectionOffset: plain.length);
      return _controller.value;
    }

    return oldValue;
  }
}

/// Campo de contraseña: el texto visible nunca muestra caracteres en claro.
class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    this.labelText = 'Contraseña',
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints = const [AutofillHints.password],
    this.enabled = true,
  });

  final ObscuredPasswordEditingController controller;
  final String labelText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: false,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: TextInputType.text,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      inputFormatters: [_ImmediatePasswordMaskFormatter(controller)],
      decoration: InputDecoration(labelText: labelText),
      onSubmitted: onSubmitted,
    );
  }
}
