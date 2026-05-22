import '../models/recurso.dart';
import 'base_api_service.dart';

class RecursosService extends BaseApiService {
  // Singleton
  static final RecursosService instance = RecursosService._();

  // Define '/recursos' como endpoint base deste serviço
  RecursosService._() : super('/recursos');

  // Listar todos os recursos (Rota: /api/recursos)
  Future<List<Recurso>> listarRecursos() async {
    return getAll<Recurso>(Recurso.fromJson);
  }

  // Listar recursos de um projeto específico
  // Rota Backend: /api/recursos-projeto/projeto/:id
  // Como o endpoint base é '/recursos', usamos '/..' para voltar um nível e acessar a outra rota
  Future<List<Recurso>> listarRecursosPorProjeto(int projetoId) async {
    return getAll<Recurso>(
      Recurso.fromJson,
      path: '/../recursos-projeto/projeto/$projetoId',
    );
  }

  // Buscar um recurso por ID
  Future<Recurso> buscarRecurso(int id) async {
    return getById<Recurso>(id, Recurso.fromJson);
  }

  // Criar novo recurso
  Future<Recurso> criarRecurso(Map<String, dynamic> data) async {
    return create<Recurso>(data, Recurso.fromJson);
  }

  // Atualizar recurso existente
  Future<Recurso> atualizarRecurso(int id, Map<String, dynamic> data) async {
    return update<Recurso>(id, data, Recurso.fromJson);
  }

  // Excluir recurso
  Future<void> excluirRecurso(int id) async {
    return delete(id);
  }
}