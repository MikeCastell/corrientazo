import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/env/app_env.dart';
import '../../../core/networking/api_client.dart';
import '../application/auth_controller.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/networking/api_exception.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController(text: '+57');
  final _password = TextEditingController();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conexión (alpha)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.75),
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
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? 'Entrando…' : 'Entrar'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(const RegisterRoute().location),
                child: const Text('Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
