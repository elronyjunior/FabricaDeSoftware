import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fabrica_software_app/config/api_config.dart'; // Ajuste o import do seu ApiConfig
import 'package:fabrica_software_app/services/auth_service.dart'; // Ajuste para pegar seu token

class DocumentoService {
  
  // Listar documentos do projeto
  Future<List<dynamic>> getDocumentosDoProjeto(int projetoId) async {
    final token = await AuthService.instance.token; // Pega token salvo
    final url = Uri.parse('${ApiConfig.baseUrl}/documentos/projeto/$projetoId');
    
    final response = await http.get(url, headers: ApiConfig.getAuthHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar documentos');
    }
  }

  // Chamar a IA para gerar e salvar
  Future<void> gerarDocumentoIA({
    required int projetoId,
    required String tipo,
    required String titulo,
    required String descricao,
  }) async {
    final token = await AuthService.instance.token;
    final url = Uri.parse('${ApiConfig.baseUrl}/ai/gerar-documento');

    final response = await http.post(
      url,
      headers: ApiConfig.getAuthHeaders(token),
      body: jsonEncode({
        "projetoId": projetoId,
        "tipoDocumento": tipo,
        "tituloDocumento": titulo,
        "descricaoExtra": descricao,
      }),
    );

    if (response.statusCode != 200) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['error'] ?? 'Erro ao gerar documento');
    }
  }
}