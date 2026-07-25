import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fabrica_software_app/services/api_config.dart';

class ApiService {
  
  // ===========================================================================
  //                              HELPERS
  // ===========================================================================

  // Converte IDs que vêm como String ("8") do Postgres para Int (8)
  static int _parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Salva o token (Chame isso no Login se não estiver usando o AuthService para isso)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Monta o Header com o Token de Autenticação correto
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    // ATENÇÃO: A chave deve ser a mesma usada no seu login ('auth_token')
    final String? token = prefs.getString('auth_token'); 
    
    if (token == null) {
      print("ALERTA: Token de autenticação não encontrado no SharedPreferences.");
    }

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper Genérico para GET
  static Future<List<dynamic>> _get(String endpoint) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro GET ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha na conexão ($endpoint): $e');
    }
  }

  // ===========================================================================
  //                              MÉTODOS DE IA
  // ===========================================================================

  static Future<List<dynamic>> gerarRequisitosBackend(String escopo, String nomeProjeto) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ai/gerar-requisitos');
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          "escopo": escopo, 
          "nomeProjeto": nomeProjeto
        }),
      );

      if (response.statusCode == 200) {
        // Decodifica UTF8 para suportar acentos corretamente
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Erro na IA (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha de conexão com IA: $e');
    }
  }

  // Retorna Map com { "orcamento_estimado": double, "complexidade": string }
  static Future<Map<String, dynamic>> estimarOrcamentoBackend(Map<String, dynamic> dadosProjeto) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ai/estimar-orcamento');
    final headers = await _getHeaders();
    
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(dadosProjeto),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro na IA de Orçamento (${response.statusCode})');
      }
    } catch (e) {
      print("Erro IA Orçamento: $e");
      throw Exception('Falha ao conectar com serviço de Orçamento');
    }
  }

  // ===========================================================================
  //                          SALVAR PROJETO COMPLETO
  // ===========================================================================

  static Future<void> criarProjetoCompleto(Map<String, dynamic> dtoData) async {
    final headers = await _getHeaders();

    // 1. Criar Projeto Pai na tabela 'projetos'
    final uriProjeto = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.projetos}');
    
    // Use os valores passados em dtoData quando disponíveis. Mantém compatibilidade
    // com chaves antigas (`tipo`) caso o caller ainda as envie.
    final projetoPayload = {
      "nome_projeto": dtoData['nome_projeto'],
      "descricao": dtoData['descricao'],
      "modelo_projeto": dtoData['modelo_projeto'],
      // aceita 'tipo_projeto' ou 'tipo'
      "tipo_projeto": dtoData['tipo_projeto'] ?? dtoData['tipo'],
      "escopo": dtoData['escopo'],                 
      "complexidade": dtoData['complexidade'],     
      "cliente_id": dtoData['cliente_id'],
      "metodologia": dtoData['metodologia'],
      "orcamento_estimado": dtoData['orcamento_estimado'],
      "data_inicio": dtoData['data_inicio'],
      "data_final_previsto": dtoData['data_final_previsto'],
      // Usa o ID do criador enviado ou fallback para responsavel ou 0
      "criado_por_id": dtoData['criado_por_id'] ?? dtoData['responsavel_id'] ?? 0,
      // Usa o ID do responsavel enviado ou fallback para criador
      "responsavel_id": dtoData['responsavel_id'] ?? dtoData['criado_por_id'] ?? 0
    };

    print("Enviando Projeto Payload: $projetoPayload");

    final respProj = await http.post(uriProjeto, headers: headers, body: jsonEncode(projetoPayload));

    if (respProj.statusCode != 201 && respProj.statusCode != 200) {
      throw Exception('Falha ao criar projeto: ${respProj.body}');
    }

    final projetoCriado = jsonDecode(respProj.body);
    final int projetoId = _parseId(projetoCriado['id']); // Converte ID string para int
    
    print("Projeto criado com sucesso. ID: $projetoId. Iniciando vínculos...");

    // 2. Vínculos Sequenciais (Pivot Tables)

    // a) Tecnologias
    if (dtoData['tecnologias'] != null) {
      for (var techId in (dtoData['tecnologias'] as List)) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tecnologiasProjeto}'),
          headers: headers,
          body: jsonEncode({
            "projeto_id": projetoId,
            "tecnologia_id": _parseId(techId),
            "data_aprovacao": DateTime.now().toIso8601String(),
            // tenta usar quem criou o projeto como aprovador, se fornecido
            "aprovado_por_id": dtoData['criado_por_id'] ?? dtoData['responsavel_id'] ?? 0
          })
        );
      }
    }

    // b) Equipe (Contribuidores)
    if (dtoData['equipe'] != null) {
      for (var membro in (dtoData['equipe'] as List)) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.contribuidoresProjeto}'),
          headers: headers,
          body: jsonEncode({
            "projeto_id": projetoId,
            "contribuidor_id": _parseId(membro['id']),
            "data_inicio": dtoData['data_inicio'],
            "data_fim": dtoData['data_final_previsto']
          })
        );
      }
    }

    // c) Recursos
    if (dtoData['recursos'] != null) {
      for (var recId in (dtoData['recursos'] as List)) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.recursosProjeto}'),
          headers: headers,
          body: jsonEncode({
            "projeto_id": projetoId,
            "recurso_id": _parseId(recId),
            "custo_hora": 0.0,
            "data_alocacao": dtoData['data_inicio'],
            "data_desalocacao": dtoData['data_final_previsto']
          })
        );
      }
    }

    // d) Requisitos (Criação + Vínculo)
    if (dtoData['requisitos'] != null) {
      for (var req in (dtoData['requisitos'] as List)) {
        // Passo d1: Criar o requisito na tabela 'requisitos'
        final respReq = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.requisitos}'), 
          headers: headers,
          body: jsonEncode({
            "tipo": req['tipo'],
            "descricao": "${req['titulo']}: ${req['descricao']}",
            "observacoes": "Gerado via App Mobile"
          })
        );

        if (respReq.statusCode == 200 || respReq.statusCode == 201) {
          final reqCriado = jsonDecode(respReq.body);
          final reqId = _parseId(reqCriado['id']);

          // Passo d2: Vincular na tabela 'requisitos_projeto'
            await http.post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.requisitosProjeto}'),
            headers: headers,
            body: jsonEncode({
              "projeto_id": projetoId,
              "requisito_id": reqId,
              "prioridade": req['prioridade']?.toString().toLowerCase() ?? 'media',
              "codigo_requisito": req['codigo'] ?? "REQ-${DateTime.now().millisecondsSinceEpoch}",
              "criado_por_id": dtoData['criado_por_id'] ?? dtoData['responsavel_id'] ?? 0
            })
          );
        }
      }
    }
  }

  // ===========================================================================
  //                          GETTERS (DADOS DO BANCO)
  // ===========================================================================
  
  static Future<List<dynamic>> getClientes() async => _get(ApiConfig.clientes);
  static Future<List<dynamic>> getTecnologias() async => _get(ApiConfig.tecnologias);
  static Future<List<dynamic>> getContribuidores() async => _get(ApiConfig.contribuidores);
  static Future<List<dynamic>> getRecursos() async => _get(ApiConfig.recursos);

  // Novo método para buscar os IDs das tecnologias do projeto
  static Future<List<int>> getTecnologiasDoProjeto(int projetoId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/tecnologias-projeto/projeto/$projetoId');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Retorna apenas uma lista de IDs (ex: [1, 5, 9])
        return data.map<int>((item) => item['tecnologia_id'] as int).toList();
      }
      return [];
    } catch (e) {
      print("Erro ao buscar tecnologias do projeto: $e");
      return [];
    }
  }
}
