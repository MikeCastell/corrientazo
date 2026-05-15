import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/corrientazo_brand.dart';
import '../../../core/design/tokens/app_surface_style.dart';
import '../../../core/env/app_env.dart';
import '../../../core/networking/api_client.dart';
import '../application/auth_controller.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/networking/api_exception.dart';
import '../../../core/ui/password_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController(text: '+57');
  final _password = ObscuredPasswordEditingController();
  bool _loading = false;
  String? _error;
  bool _diagLoading = false;
  String? _diag;

  @override
  void dispose() {
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
          .login(phone: _phone.text.trim(), password: _password.text);
      if (!mounted) return;
      // Role-based redirect will take the user to the right shell.
      context.go(const SplashRoute().location);
    } catch (e) {
      String msg;
      if (e is UnauthorizedException) {
        msg = 'Tu sesión expiró o credenciales inválidas.';
      } else if (e is ApiErrorResponseException) {
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

  Future<void> _probe() async {
    setState(() {
      _diagLoading = true;
      _diag = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getJson<Map<String, dynamic>>(
        '/healthz',
        decode: (json) => (json as Map).cast<String, dynamic>(),
      );
      setState(() => _diag = 'OK /healthz: $data');
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      setState(() => _diag = 'FALLÓ /healthz: $msg');
    } finally {
      if (mounted) setState(() => _diagLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  const CorrientazoLogoMark(height: 88),
                  const SizedBox(height: 10),
                  const CorrientazoTagline(fontSize: 12),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conexión (alpha)',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'API_BASE_URL: ${AppEnv.apiBaseUrl}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _diagLoading ? null : _probe,
                            child: Text(
                              _diagLoading ? 'Probando…' : 'Probar conexión',
                            ),
                          ),
                        ),
                        if (_diag != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _diag!,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 12),
                  PasswordTextField(
                    controller: _password,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_loading) _submit();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Entrando…' : 'Entrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        context.go(const RegisterRoute().location),
                    child: const Text('Crear cuenta'),
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
