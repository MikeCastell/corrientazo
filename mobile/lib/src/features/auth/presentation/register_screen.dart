import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_controller.dart';
import '../../../core/branding/corrientazo_brand.dart';
import '../../../core/design/tokens/app_surface_style.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/networking/api_exception.dart';
import '../../../core/ui/password_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+57');
  final _password = TextEditingController();
  String _role = 'CUSTOMER';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            phone: _phone.text.trim(),
            password: _password.text,
            name: _name.text.trim(),
            role: _role,
          );
      if (!mounted) return;
      // Role-based redirect will take the user to the right shell.
      context.go(const SplashRoute().location);
    } catch (e) {
      String msg;
      if (e is ApiErrorResponseException) {
        msg = '${e.message} (${e.code})';
      } else if (e is NetworkException) {
        msg = 'No pudimos conectar con el servidor. ${e.message}';
      } else if (e is ApiException) {
        msg = e.message;
      } else {
        msg = 'Ocurrió un error inesperado. Intenta de nuevo.';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const CorrientazoWordmark(fontSize: 20),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AppSurfaceBackground(
              brightness: Theme.of(context).brightness,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const CorrientazoLogoMark(height: 72),
                  const SizedBox(height: 8),
                  const CorrientazoTagline(fontSize: 11),
                  const SizedBox(height: 8),
                  Text(
                    'Crear cuenta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 12),
                  PasswordTextField(
                    controller: _password,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_loading) _submit();
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: const [
                      DropdownMenuItem(value: 'CUSTOMER', child: Text('Cliente')),
                      DropdownMenuItem(value: 'COOK', child: Text('Cocinero')),
                    ],
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _role = v ?? 'CUSTOMER'),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Creando…' : 'Crear cuenta'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go(const LoginRoute().location),
                    child: const Text('Ya tengo cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
