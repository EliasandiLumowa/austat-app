import 'indicator_model.dart';
import '../services/api_service.dart';

class DocumentModel {
  final int id;
  final String uuid;
  final String title;
  final String slug;
  final String type; // 'publication' or 'brs'
  final int year;
  final int? indicatorId;
  final IndicatorModel? indicator;
  final String? description;
  final String? fileName;
  final String? fileSizeFormatted;
  final String? coverUrl;
  final String? mp3Url;
  final String? flacUrl;
  final int audioDuration;
  final String audioDurationFormatted;
  final int downloadCount;
  final int playCount;
  final String status;
  final String? createdAt;
  final String? extractedText;

  const DocumentModel({
    required this.id,
    required this.uuid,
    required this.title,
    required this.slug,
    required this.type,
    required this.year,
    this.indicatorId,
    this.indicator,
    this.description,
    this.fileName,
    this.fileSizeFormatted,
    this.coverUrl,
    this.mp3Url,
    this.flacUrl,
    this.audioDuration = 0,
    this.audioDurationFormatted = '00:00',
    this.downloadCount = 0,
    this.playCount = 0,
    this.status = 'completed',
    this.createdAt,
    this.extractedText,
  });

  bool get isPublication => type.toLowerCase() == 'publication';
  bool get isBrs => type.toLowerCase() == 'brs';
  bool get hasAudio => mp3Url != null && mp3Url!.isNotEmpty;

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    IndicatorModel? indicatorModel;
    if (json['indicator'] is Map<String, dynamic>) {
      indicatorModel = IndicatorModel.fromJson(json['indicator']);
    } else if (json['indicator_name'] != null) {
      indicatorModel = IndicatorModel(
        id: json['indicator_id'] ?? 0,
        name: json['indicator_name'] ?? '',
        slug: '',
      );
    }

    final durationSec = json['audio_duration'] is int
        ? json['audio_duration']
        : int.tryParse(json['audio_duration']?.toString() ?? '0') ?? 0;

    String durationStr = json['audio_duration_formatted'] ?? '';
    if (durationStr.isEmpty && durationSec > 0) {
      final min = durationSec ~/ 60;
      final sec = durationSec % 60;
      durationStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    } else if (durationStr.isEmpty) {
      durationStr = '00:00';
    }

    return DocumentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      uuid: json['uuid']?.toString() ?? '${json['id']}',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      type: json['type'] ?? 'publication',
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? '2025') ?? 2025,
      indicatorId: json['indicator_id'] is int
          ? json['indicator_id']
          : int.tryParse(json['indicator_id']?.toString() ?? ''),
      indicator: indicatorModel,
      description: json['description'],
      fileName: json['file_name'],
      fileSizeFormatted: json['file_size_formatted'] ?? '2.4 MB',
      coverUrl: ApiService.normalizeUrl(json['cover_url'] ?? json['cover_path']),
      mp3Url: ApiService.normalizeUrl(json['mp3_url'] ?? json['mp3_path']),
      flacUrl: ApiService.normalizeUrl(json['flac_url'] ?? json['flac_path']),
      audioDuration: durationSec,
      audioDurationFormatted: durationStr,
      downloadCount: json['download_count'] is int
          ? json['download_count']
          : int.tryParse(json['download_count']?.toString() ?? '0') ?? 0,
      playCount: json['play_count'] is int
          ? json['play_count']
          : int.tryParse(json['play_count']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'completed',
      createdAt: json['created_at']?.toString(),
      extractedText: json['extracted_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'slug': slug,
      'type': type,
      'year': year,
      'indicator_id': indicatorId,
      'indicator': indicator?.toJson(),
      'description': description,
      'file_name': fileName,
      'file_size_formatted': fileSizeFormatted,
      'cover_url': coverUrl,
      'mp3_url': mp3Url,
      'flac_url': flacUrl,
      'audio_duration': audioDuration,
      'audio_duration_formatted': audioDurationFormatted,
      'download_count': downloadCount,
      'play_count': playCount,
      'status': status,
      'created_at': createdAt,
      'extracted_text': extractedText,
    };
  }
}
