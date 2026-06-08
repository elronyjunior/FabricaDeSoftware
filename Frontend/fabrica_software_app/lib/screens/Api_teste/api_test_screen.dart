import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/base_api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _endpointController = TextEditingController();
  final _bodyController = TextEditingController();
  
  String? _selectedMethod = 'GET';
  String _response = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'admin@example.com'; // valor para teste
    _senhaController.text = '123456'; // valor para teste
    _endpointController.text = '/usuarios'; // endpoint inicial
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _emailController.text,
        _senhaController.text,
      );

      setState(() {
        _response = success 
          ? 'Login realizado com sucesso!'
          : 'Falha no login: credenciais inválidas';
      });
    } catch (e) {
      setState(() => _response = 'Erro no login: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeRequest() async {
    if (!context.read<AuthProvider>().isAuthenticated!) {
      setState(() => _response = 'Faça login primeiro!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = BaseApiService(_endpointController.text);
      final response = await _executeRequest(service);
      
      setState(() {
        _response = '''
Status: ${response.statusCode}

Headers: 
${response.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Body:
${_prettyPrintJson(response.body)}
''';
      });
    } catch (e) {
      setState(() => _response = 'Erro na requisição: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<dynamic> _executeRequest(BaseApiService service) async {
    final path = _endpointController.text.startsWith('/') ? '' : '/';
    
    switch (_selectedMethod) {
      case 'GET':
        return service.get(path);
      case 'POST':
        final body = _bodyController.text.isNotEmpty 
          ? jsonDecode(_bodyController.text) 
          : {};
        return service.post(path, body);
      case 'PUT':
        final body = _bodyController.text.isNotEmpty 
          ? jsonDecode(_bodyController.text) 
          : {};
        return service.put(path, body);
      case 'DELETE':
        return service.deleteByPath(path);
      default:
        throw Exception('Método não suportado');
    }
  }

  String _prettyPrintJson(String input) {
    try {
      final object = jsonDecode(input);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(object);
    } catch (e) {
      return input;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Playground'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _senhaController,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _endpointController,
                            decoration: const InputDecoration(
                              labelText: 'Endpoint',
                              border: OutlineInputBorder(),
                              hintText: '/usuarios, /projetos, etc',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _selectedMethod,
                          items: ['GET', 'POST', 'PUT', 'DELETE']
                              .map((method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(method),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedMethod = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedMethod == 'POST' || _selectedMethod == 'PUT')
                      TextField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          labelText: 'Body (JSON)',
                          border: OutlineInputBorder(),
                          hintText: '{"chave": "valor"}',
                        ),
                        maxLines: 5,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _makeRequest,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Enviar Request'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Response',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        _response,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _endpointController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}