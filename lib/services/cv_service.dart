import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'models.dart';
import 'api_client.dart';

class CvService {
  final Dio _dio = ApiClient.dio;

  static List<JobModel> _jobs(dynamic v) => (v as List? ?? const [])
      .map((e) => JobModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  static AnalysisBundle? _bundle(Map data) {
    if (data['analysis'] == null) return null;
    return AnalysisBundle(
      CvAnalysis.fromJson(Map<String, dynamic>.from(data['analysis'])),
      _jobs(data['matchedJobs']),
    );
  }

  Future<CvRecord> upload(PlatformFile file) async {
    final bytes = await file.readAsBytes();
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    final res = await _dio.post('/api/cv/upload', data: form);
    return CvRecord.fromJson(Map<String, dynamic>.from(res.data['cv']));
  }

  Future<AnalysisBundle> analyze(int cvId) async {
    final res = await _dio.post('/api/cv/$cvId/analyze');
    return _bundle(res.data)!;
  }

  /// Latest CV + saved analysis (analysis is null if never analyzed).
  Future<({CvRecord? cv, AnalysisBundle? bundle})> latest() async {
    final res = await _dio.get('/api/cv/latest');
    final data = res.data as Map;
    if (data['cv'] == null) return (cv: null, bundle: null);
    return (
      cv: CvRecord.fromJson(Map<String, dynamic>.from(data['cv'])),
      bundle: _bundle(data),
    );
  }
}