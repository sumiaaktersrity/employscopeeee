import '../widgets/cv_analysis_results.dart';
import '../widgets/matched_jobs_section.dart';

class CvRecord {
  final int id;
  final String fileName;
  const CvRecord({required this.id, required this.fileName});

  factory CvRecord.fromJson(Map<String, dynamic> j) => CvRecord(
        id: (j['id'] as num).toInt(),
        fileName: (j['fileName'] ?? 'CV').toString(),
      );
}

class CvAnalysis {
  final int score;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> suggestedSkills;
  final List<String> suggestions;

  const CvAnalysis({
    required this.score,
    required this.matchedSkills,
    required this.missingSkills,
    required this.suggestedSkills,
    required this.suggestions,
  });

  static List<String> _list(dynamic v) =>
      (v as List? ?? const []).map((e) => e.toString()).toList();

  factory CvAnalysis.fromJson(Map<String, dynamic> j) => CvAnalysis(
        score: (j['score'] as num? ?? 0).toInt(),
        matchedSkills: _list(j['matchedSkills']),
        missingSkills: _list(j['missingSkills']),
        suggestedSkills: _list(j['suggestedSkills']),
        suggestions: _list(j['suggestions']),
      );

  /// Feeds the existing CVAnalysisResults widget unchanged.
  List<SkillTag> get skillTags => [
        ...matchedSkills.take(8).map((s) => SkillTag(s, SkillTagType.matched)),
        ...missingSkills.map((s) => SkillTag(s, SkillTagType.missing)),
        ...suggestedSkills.map((s) => SkillTag(s, SkillTagType.suggested)),
      ];
}

class JobModel {
  final int id;
  final String title;
  final String company;
  final String location;
  final int? matchPercent;

  const JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    this.matchPercent,
  });

  factory JobModel.fromJson(Map<String, dynamic> j) => JobModel(
        id: (j['id'] as num).toInt(),
        title: (j['title'] ?? '').toString(),
        company: (j['company'] ?? '').toString(),
        location: (j['location'] ?? '').toString(),
        matchPercent: (j['matchPercent'] as num?)?.toInt(),
      );

  /// Feeds the existing MatchedJobsSection widget unchanged.
  JobListing toListing({bool isSaved = false}) => JobListing(
        id: id,
        isSaved: isSaved,
        title: title,
        company: company,
        location: location,
        matchPercent: matchPercent ?? 0,
        showMatch: matchPercent != null,
      );
}

/// Result of analyze / latest calls.
class AnalysisBundle {
  final CvAnalysis analysis;
  final List<JobModel> matchedJobs;
  const AnalysisBundle(this.analysis, this.matchedJobs);
}

/// Week 11: one recommended skill with a short "how to start" tip.
class SkillRecommendation {
  final String skill;
  final String tip;
  final bool required;
  const SkillRecommendation(
      {required this.skill, required this.tip, required this.required});

  factory SkillRecommendation.fromJson(Map<String, dynamic> j) =>
      SkillRecommendation(
        skill: (j['skill'] ?? '').toString(),
        tip: (j['tip'] ?? '').toString(),
        required: j['required'] != false,
      );
}

/// Week 11: result of comparing the CV with one targeted job.
class SkillGap {
  final int matchPercent;
  final int totalSkills;
  final List<String> matchedSkills;
  final List<String> missingRequired;
  final List<String> missingOptional;
  final List<SkillRecommendation> recommendations;
  final bool aiGenerated;

  const SkillGap({
    required this.matchPercent,
    required this.totalSkills,
    required this.matchedSkills,
    required this.missingRequired,
    required this.missingOptional,
    required this.recommendations,
    required this.aiGenerated,
  });

  static List<String> _list(dynamic v) =>
      (v as List? ?? const []).map((e) => e.toString()).toList();

  factory SkillGap.fromJson(Map<String, dynamic> j) => SkillGap(
        matchPercent: (j['matchPercent'] as num? ?? 0).toInt(),
        totalSkills: (j['totalSkills'] as num? ?? 0).toInt(),
        matchedSkills: _list(j['matchedSkills']),
        missingRequired: _list(j['missingRequired']),
        missingOptional: _list(j['missingOptional']),
        recommendations: (j['recommendations'] as List? ?? const [])
            .map((e) =>
                SkillRecommendation.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        aiGenerated: j['aiGenerated'] == true,
      );
}