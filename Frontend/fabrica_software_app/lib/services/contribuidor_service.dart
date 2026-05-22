import '../models/contribuidor.dart';
import 'base_api_service.dart';

class ContribuidorService extends BaseApiService {
  ContribuidorService() : super('/contribuidores');

  Future<List<Contribuidor>> getContribuidores() async {
    return getAll<Contribuidor>(Contribuidor.fromJson);
  }

  Future<Contribuidor> getContribuidor(int id) async {
    return getById<Contribuidor>(id, Contribuidor.fromJson);
  }

  Future<Contribuidor> createContribuidor(Contribuidor contribuidor) async {
    // CORREÇÃO: toJson() com J maiúsculo
    return create<Contribuidor>(contribuidor.toJson(), Contribuidor.fromJson);
  }

  Future<Contribuidor> updateContribuidor(Contribuidor contribuidor) async {
    // CORREÇÃO: toJson() com J maiúsculo
    return update<Contribuidor>(contribuidor.id ?? 0, contribuidor.toJson(), Contribuidor.fromJson);
  }

  Future<void> deleteContribuidor(int id) async {
    return delete(id);
  }
}