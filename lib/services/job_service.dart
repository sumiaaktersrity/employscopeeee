import 'models.dart';
import 'api_client.dart';

class JobService {
  Future<List<JobModel>> listJobs({String? q, String? location}) async {
    final res = await ApiClient.dio.get('/api/jobs', queryParameters: {
      if (q != null) 'q': q,
      if (location != null) 'location': location,
    });
    return (res.data['jobs'] as List)
        .map((e) => JobModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Week 10: the user's targeted (bookmarked) jobs.
  Future<List<JobModel>> listSaved() async {
    final res = await ApiClient.dio.get('/api/jobs/saved');
    return (res.data['jobs'] as List)
        .map((e) => JobModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveJob(int id) => ApiClient.dio.post('/api/jobs/$id/save');

  Future<void> unsaveJob(int id) => ApiClient.dio.delete('/api/jobs/$id/save');

  /// Week 11: your CV skills vs one job + learning tips.
  Future<SkillGap> skillGap(int id) async {
    final res = await ApiClient.dio.get('/api/jobs/$id/skill-gap');
    return SkillGap.fromJson(Map<String, dynamic>.from(res.data));
  }
}