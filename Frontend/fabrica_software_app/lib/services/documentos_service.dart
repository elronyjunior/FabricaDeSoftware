import '../models/documento.dart';
import 'base_api_service.dart';
import 'package:http/http.dart' as http;

class DocumentosService extends BaseApiService {
  static final DocumentosService instance = DocumentosService._();
  
  DocumentosService._() : super('/documentos');

  Future<List<Documento>> listarDocumentos() async {
    return super.getAll((json) => Documento.fromJson(json));
  }

  Future<Documento> buscarDocumento(int id) async {
    return super.getById(id, (json) => Documento.fromJson(json));
  }

  Future<Documento> criarDocumento(Map<String, dynamic> data) async {
    return super.create(data, (json) => Documento.fromJson(json));
  }

  Future<Documento> atualizarDocumento(int id, Map<String, dynamic> data) async {
    return super.update(id, data, (json) => Documento.fromJson(json));
  }

  Future<void> excluirDocumento(int id) async {
    return super.delete(id);
  }

  // Métodos específicos para documentos
  Future<List<Documento>> listarPorProjeto(int projetoId) async {
    return super.getAll(
      (json) => Documento.fromJson(json),
      path: '/projeto/$projetoId'
    );
  }

  Future<String> gerarUrlDownload(int id) async {
    final response = await http.get(
      buildUri('/download/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final json = await handleResponse(response, (json) => json as Map<String, dynamic>);
      return json['url'] as String;
    } else {
      throw ApiException('Erro ao gerar URL de download');
    }
  }

  Future<void> uploadDocumento(int projetoId, String nome, List<int> bytes) async {
    final uri = buildUri('/upload/$projetoId');
    final request = http.MultipartRequest('POST', uri);
    
    final headers = await getHeaders();
    request.headers.addAll(headers);

    request.files.add(
      http.MultipartFile.fromBytes(
        'arquivo',
        bytes,
        filename: nome,
      ),
    );

    final response = await request.send();
    // ignore: unused_local_variable
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw ApiException('Erro ao fazer upload do documento');
    }
  }
}