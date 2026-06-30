import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../Api_teste/api_test_screen.dart';
import 'dart:ui';

class FormularioLogin extends StatefulWidget {
  const FormularioLogin({super.key});

  @override
  State<FormularioLogin> createState() => _FormularioLoginState();
}

class _FormularioLoginState extends State<FormularioLogin> {
  final _emailController = TextEditingController(text: '');
  final _senhaController = TextEditingController(text: '');
  bool _isLoading = false;

   @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column( 
      mainAxisSize: MainAxisSize.min, 
      crossAxisAlignment: CrossAxisAlignment.stretch, 
      
      children: <Widget>[
        Image.asset('assets/image/tegra_logo.png',width:35,height:35,),
        
        const SizedBox(height: 16), 
        
        Text(
          'Entre na sua conta',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), 
        ),
        
        const SizedBox(height: 32),
        
        Text(
          'Email*',
          style: TextStyle(fontWeight: FontWeight.bold), 
        ),
        const SizedBox(height: 8), 

        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'usuario@tegra.com.br',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Senha*',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _senhaController,
          obscureText: true, 
          decoration: InputDecoration(
            hintText: '********',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Align( 
          alignment: Alignment.centerRight,
          child: MouseRegion( 
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () { print('Esqueci a senha'); },
              child: Text(
                'Esqueci a senha',
                style: TextStyle(color: Color.fromARGB(255, 83, 10, 255)), 
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            final email = _emailController.text.trim();
            final senha = _senhaController.text;
            if (email.isEmpty || senha.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preencha email e senha')),
              );
              return;
            }

            setState(() => _isLoading = true);

            try {
                final auth = context.read<AuthProvider>();
                final success = await auth.login(email, senha);

                if (!mounted) return;

                if (success) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ApiTestScreen()),
                  );
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(auth.error ?? 'Falha no login')),
                    );
                  }
                }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro no login: ${e.toString()}')),
                );
              }
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 38, 57, 177),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder( 
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Entrar', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: <Widget>[
            Text('Não tem uma conta? '),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child:GestureDetector(
                onTap: () { Navigator.pushNamed(context,'/Cadastro');},
                child:Text(
                  'Cadastrar-se',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 83, 10, 255), 
                    fontWeight: FontWeight.bold,
                  )
                )
              ), 
            ), 
          ]
        )
      ],
    );
  }
}