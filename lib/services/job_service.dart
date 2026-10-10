import '../models/models.dart';
import 'api_client.dart';

class JobService {
  Future<List<JobModel>> listJobs({String? q, String? location}) async {
    final res = await ApiClient.dio.get('/jobs', queryParameters: {
      if (q != null) 'q': q,
      if (location != null) 'location': location,
    });
    return (res.data['jobs'] as List)
        .map((e) => JobModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}