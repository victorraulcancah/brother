import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_message.dart';
import '../widgets/responsive_center.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// La preferencia va en SharedPreferences (no es sensible) y las credenciales
  /// en el almacenamiento seguro del sistema: Keychain en iOS, Keystore en
  /// Android. En texto plano quedarían legibles en un backup del dispositivo.
  static const _recordarKey = 'login_recordar';
  static const _correoKey = 'login_correo';
  static const _passKey = 'login_password';

  static const _seguro = FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _recordar = false;

  @override
  void initState() {
    super.initState();
    _cargarCredenciales();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _cargarCredenciales() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.getBool(_recordarKey).isTrue) return;

    String? correo;
    String? clave;
    try {
      correo = await _seguro.read(key: _correoKey);
      clave = await _seguro.read(key: _passKey);
    } catch (_) {
      // Sin almacenamiento seguro disponible se entra a mano.
      return;
    }
    if (!mounted || correo == null || correo.isEmpty) return;

    setState(() {
      _recordar = true;
      _emailController.text = correo!;
      _passwordController.text = clave ?? '';
    });
  }

  Future<void> _guardarCredenciales(String correo, String clave) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recordarKey, _recordar);

    try {
      if (_recordar) {
        await _seguro.write(key: _correoKey, value: correo);
        await _seguro.write(key: _passKey, value: clave);
      } else {
        await _seguro.delete(key: _correoKey);
        await _seguro.delete(key: _passKey);
      }
    } catch (_) {
      // Si el dispositivo no lo soporta, no se guarda nada.
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final correo = _emailController.text.trim();
    final clave = _passwordController.text;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(correo, clave);

    if (!success) return;
    await _guardarCredenciales(correo, clave);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final logoHeight = context.responsive<double>(
      mobile: 88,
      smallPhone: 68,
      tablet: 104,
    );

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppLogo(height: logoHeight),
                SizedBox(height: context.isSmallPhone ? 16 : 24),
                Text('Iniciar sesión', style: textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Accede a tu cuenta',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 32),

                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppMessage(text: auth.error!),
                    );
                  },
                ),

                AppTextField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingrese su correo';
                    }
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese su contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                InkWell(
                  onTap: () => setState(() => _recordar = !_recordar),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _recordar,
                          onChanged: (v) =>
                              setState(() => _recordar = v ?? false),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 4),
                        Text('Recordar mis credenciales', style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Consumer<AuthProvider>(
                  builder: (context, auth, _) => PrimaryButton(
                    label: 'Iniciar sesión',
                    loading: auth.isLoading,
                    onPressed: _login,
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _BoolOrFalse on bool? {
  bool get isTrue => this ?? false;
}
