import '../models/contribuidor_projeto.dart';
import 'base_api_service.dart';

class ContribuidoresProjetoService extends BaseApiService {
  static final ContribuidoresProjetoService instance = ContribuidoresProjetoService._();
  
  ContribuidoresProjetoService._() : super('/contribuidores-projeto');

  Future<List<ContribuidorProjeto>> listarContribuidoresProjeto() async {
    return super.getAll((json) => ContribuidorProjeto.fromJson(json));
  }

  Future<ContribuidorProjeto> adicionarContribuidorProjeto(Map<String, dynamic> data) async {
    return super.create(data, (json) => ContribuidorProjeto.fromJson(json));
  }

  Future<void> removerVinculo(int projetoId, int contribuidorId) async {
    await super.deleteByPath('/$projetoId/$contribuidorId');
  }
}