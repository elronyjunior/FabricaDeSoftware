import 'package:fabrica_software_app/screens/Cadastro/Styles/style_cadastro.dart';
import 'package:fabrica_software_app/screens/Gerenciar_Projetos/Gerenciar_projetos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmSenhaController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmSenhaController.dispose();
    super.dispose();
  }

  void _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.loginWithGoogle();

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GerenciarProjetos()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Falha no login com Google')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no login com Google: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 95, 115, 231),
      
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            margin: const EdgeInsets.all(16.0),
            
            // 1. DECORAÇÃO DO CARD PRINCIPAL (Apenas Sombra e Borda)
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20.0,
                  spreadRadius: 1.0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  
                  // --- PARTE DE CIMA (BRANCA) ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 10), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset('assets/image/tegra_logo.png', width: 120, 
                          fit: BoxFit.contain,),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Crie sua conta',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 32),

                        // CAMPOS
                        const Text('Nome completo*', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            hintText: 'Digite seu nome completo',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('Telefone*', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _telefoneController,
                          decoration: InputDecoration(
                            hintText: '(15) 99999-9999',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('Email*', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'seu@email.com',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('Senha*', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _senhaController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '********',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('Confirme a senha*', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmSenhaController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '********',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          ),
                        ),
                        
                        const SizedBox(height: 24), // Espaço antes do corte
                      ],
                    ),
                  ),

                  // --- PARTE DE BAIXO (RODAPÉ / CONTAINER EXTRA) ---
                  Container(
                    padding: const EdgeInsets.all(32),
                    width: double.infinity, // Ocupa toda a largura
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          spreadRadius: 10, 
                          blurRadius: 10, 
                          offset: const Offset(0, 10), 
                        ),
                      ],
                      color: Colors.white, // Cinza bem claro (Efeito de Corte)
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        // BOTÃO CADASTRAR
                        ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                             // ... (Sua lógica de cadastro aqui é a mesma) ...
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 38, 57, 177),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Cadastrar-se', style: TextStyle(fontSize: 18)),
                        ),

                        const SizedBox(height: 16),

                        // LINK LOGIN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text('já tem uma conta? '),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Fazer login',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 83, 10, 255),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // OU
                        Row(
                          children: [
                            Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('OU', style: TextStyle(color: Colors.grey[600])),
                            ),
                            Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // BOTÃO GOOGLE
                        ElevatedButton.icon(
                          icon: SvgPicture.asset('assets/SVG/Google_logo.svg', width: 24),
                          label: const Text(
                            'Entrar com Google',
                            style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: StyleCadastro.btnGoogle
                          ),
                      ],
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