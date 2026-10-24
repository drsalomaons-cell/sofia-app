import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/routes/app_routes.dart';

const _gold = Color(0xFFFFD76A);
const _goldDeep = Color(0xFFFFB300);

class LoginScreen extends StatefulWidget {
  final bool initialEmailMode;
  final bool initialCreate;
  const LoginScreen({
    super.key,
    this.initialEmailMode = false,
    this.initialCreate = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _emailMode = widget.initialEmailMode;
  late bool _create = widget.initialCreate;
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _comingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Login com $provider ainda não está configurado neste build. Use "Prefiro usar e-mail" por enquanto.',
        ),
        backgroundColor: const Color(0xFF2A1458),
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool ok;
    if (_create) {
      final local = email.split('@').first;
      final name = local.isEmpty
          ? 'Usuário SOFIA'
          : '${local[0].toUpperCase()}${local.substring(1)}';
      ok = await auth.register(
        name: name,
        email: email,
        phone: '',
        password: password,
        gender: 'Outro',
        interestedIn: 'Todos',
        region: 'Brasil',
      );
    } else {
      ok = await auth.login(email, password);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ??
                (_create ? 'Erro ao criar conta' : 'Erro ao fazer login'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _logo() => Column(
    children: [
      Container(
        width: 92,
        height: 92,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE7A1), _goldDeep],
          ),
          boxShadow: [
            BoxShadow(color: Color(0x88FFB300), blurRadius: 28, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.auto_awesome, color: Color(0xFF101629), size: 46),
      ),
      const SizedBox(height: 18),
      const Text(
        'SOFIA',
        style: TextStyle(
          color: _gold,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Salas de voz, lives e jogos',
        style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1),
      ),
    ],
  );

  Widget _bigButton({
    required String label,
    required Widget leading,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _socialButtons() => Column(
    key: const ValueKey('social'),
    children: [
      _bigButton(
        label: 'Continuar com Google',
        leading: const Text(
          'G',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFFEA4335),
          ),
        ),
        bg: Colors.white,
        fg: const Color(0xFF1F1F1F),
        onTap: () => _comingSoon('Google'),
      ),
      const SizedBox(height: 14),
      _bigButton(
        label: 'Continuar com Facebook',
        leading: const Icon(Icons.facebook, size: 26),
        bg: const Color(0xFF1877F2),
        fg: Colors.white,
        onTap: () => _comingSoon('Facebook'),
      ),
      const SizedBox(height: 14),
      _bigButton(
        label: 'Continuar com Telefone',
        leading: const Icon(Icons.sms_rounded, size: 22),
        bg: _gold,
        fg: const Color(0xFF101629),
        onTap: () => _comingSoon('Telefone (SMS)'),
      ),
      const SizedBox(height: 18),
      const Text(
        'Ao continuar, você concorda com os Termos de Uso e a Política de Privacidade.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white38, fontSize: 11),
      ),
    ],
  );

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: _gold),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      );

  Widget _emailForm() => Form(
    key: _formKey,
    child: Column(
      key: const ValueKey('email'),
      children: [
        Text(
          _create ? 'Criar conta com e-mail' : 'Entrar com e-mail',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration('E-mail', Icons.email_outlined),
          validator: (v) {
            final value = (v ?? '').trim();
            if (value.isEmpty) return 'Digite seu e-mail';
            if (!value.contains('@')) return 'E-mail inválido';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscure,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration(
            'Senha',
            Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white54,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            final value = v ?? '';
            if (value.isEmpty) return 'Digite sua senha';
            if (_create && value.length < 6) return 'Mínimo de 6 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xFF101629),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(
                    _create ? 'CRIAR CONTA' : 'ENTRAR',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _create = !_create),
          child: Text(
            _create ? 'Já tenho conta' : 'Criar conta com e-mail',
            style: const TextStyle(color: _gold, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1458), Color(0xFF141A3D), Color(0xFF070918)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logo(),
                  const SizedBox(height: 36),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _emailMode ? _emailForm() : _socialButtons(),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _emailMode = !_emailMode),
                    child: Text(
                      _emailMode ? 'Voltar às outras opções' : 'Prefiro usar e-mail',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}