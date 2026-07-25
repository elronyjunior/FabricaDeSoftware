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

  // Chamar a IA para gerar e salvar.
  // O backend processa em segundo plano (job assíncrono) para não manter uma
  // única requisição HTTP presa por vários minutos; aqui fazemos polling do
  // status até o documento ficar pronto.
  Future<void> gerarDocumentoIA({
    required int projetoId,
    required String tipo,
    required String titulo,
    required String descricao,
    void Function(String stage)? onStatusUpdate,
  }) async {
    final token = await AuthService.instance.token;
    final headers = ApiConfig.getAuthHeaders(token);

    final startUrl = Uri.parse('${ApiConfig.baseUrl}/ai/gerar-documento');
    final startResponse = await http.post(
      startUrl,
      headers: headers,
      body: jsonEncode({
        "projetoId": projetoId,
        "tipoDocumento": tipo,
        "tituloDocumento": titulo,
        "descricaoExtra": descricao,
      }),
    );

    if (startResponse.statusCode != 202) {
      final erro = jsonDecode(startResponse.body);
      throw Exception(erro['error'] ?? erro['message'] ?? 'Erro ao iniciar geração do documento');
    }

    final jobId = jsonDecode(startResponse.body)['jobId'];
    final statusUrl = Uri.parse('${ApiConfig.baseUrl}/ai/gerar-documento/status/$jobId');

    const pollInterval = Duration(seconds: 2);
    final deadline = DateTime.now().add(const Duration(minutes: 10));

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);

      final statusResponse = await http.get(statusUrl, headers: headers);

      if (statusResponse.statusCode == 404) {
        throw Exception('Job de geração não encontrado ou expirado');
      }
      if (statusResponse.statusCode != 200) {
        throw Exception('Erro ao consultar status da geração do documento');
      }

      final job = jsonDecode(statusResponse.body);
      final status = job['status'];

      if (status == 'done') {
        return;
      } else if (status == 'error') {
        throw Exception(job['error'] ?? 'Erro ao gerar documento');
      } else if (job['stage'] != null) {
        onStatusUpdate?.call(job['stage']);
      }
    }

    throw Exception('Tempo limite excedido aguardando a geração do documento');
  }

  // Busca o conteúdo estruturado (JSON) de um documento, para o editor
  // in-app. Retorna null para documentos legados (sem conteúdo editável).
  Future<Map<String, dynamic>?> getConteudoDocumento(int documentoId) async {
    final token = await AuthService.instance.token;
    final url = Uri.parse('${ApiConfig.baseUrl}/documentos/$documentoId/conteudo');

    final response = await http.get(url, headers: ApiConfig.getAuthHeaders(token));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar conteúdo do documento');
    }

    final corpo = jsonDecode(utf8.decode(response.bodyBytes));
    return corpo['conteudo_json'] as Map<String, dynamic>?;
  }

  // Salva o conteúdo editado de volta no backend.
  Future<void> salvarConteudoDocumento(int documentoId, Map<String, dynamic> conteudoJson) async {
    final token = await AuthService.instance.token;
    final url = Uri.parse('${ApiConfig.baseUrl}/documentos/$documentoId/conteudo');

    final response = await http.put(
      url,
      headers: ApiConfig.getAuthHeaders(token),
      body: jsonEncode({'conteudo_json': conteudoJson}),
    );

    if (response.statusCode != 200) {
      final erro = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(erro['message'] ?? 'Erro ao salvar documento');
    }
  }

  // Pede pra IA reescrever só as seções indicadas por "caminhos" (índices
  // por nível dentro de secoes/subsecoes), usando o resto do documento como
  // contexto. Mesmo padrão de job assíncrono + polling do gerarDocumentoIA -
  // o retorno traz só as seções reescritas, não o documento inteiro.
  Future<Map<String, dynamic>> retrabalharSecoesComIA({
    required Map<String, dynamic> documento,
    required List<List<int>> caminhos,
    required String instrucao,
    void Function(String stage)? onStatusUpdate,
  }) async {
    final token = await AuthService.instance.token;
    final headers = ApiConfig.getAuthHeaders(token);

    final startUrl = Uri.parse('${ApiConfig.baseUrl}/ai/retrabalhar-secoes');
    final startResponse = await http.post(
      startUrl,
      headers: headers,
      body: jsonEncode({'documento': documento, 'caminhos': caminhos, 'instrucao': instrucao}),
    );

    if (startResponse.statusCode != 202) {
      final erro = jsonDecode(utf8.decode(startResponse.bodyBytes));
      throw Exception(erro['error'] ?? erro['message'] ?? 'Erro ao iniciar retrabalho com IA');
    }

    final jobId = jsonDecode(startResponse.body)['jobId'];
    final statusUrl = Uri.parse('${ApiConfig.baseUrl}/ai/retrabalhar-secoes/status/$jobId');

    const pollInterval = Duration(seconds: 2);
    final deadline = DateTime.now().add(const Duration(minutes: 5));

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);

      final statusResponse = await http.get(statusUrl, headers: headers);

      if (statusResponse.statusCode == 404) {
        throw Exception('Job de retrabalho não encontrado ou expirado');
      }
      if (statusResponse.statusCode != 200) {
        throw Exception('Erro ao consultar status do retrabalho');
      }

      final job = jsonDecode(utf8.decode(statusResponse.bodyBytes));
      final status = job['status'];

      if (status == 'done') {
        return job['result'] as Map<String, dynamic>;
      } else if (status == 'error') {
        throw Exception(job['error'] ?? 'Erro ao retrabalhar seções com IA');
      } else if (job['stage'] != null) {
        onStatusUpdate?.call(job['stage']);
      }
    }

    throw Exception('Tempo limite excedido aguardando o retrabalho com IA');
  }
}