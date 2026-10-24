import 'package:flutter/material.dart';

const contentPages = <String, String>{
  'about': 'Giới thiệu',
  'rules': 'Quy định',
  'guide': 'Hướng dẫn sử dụng',
  'contact': 'Liên hệ',
  'support': 'Hướng dẫn báo sự cố',
};

IconData contentIcon(String slug) {
  switch (slug) {
    case 'rules':
      return Icons.gavel_outlined;
    case 'guide':
      return Icons.help_outline_rounded;
    case 'contact':
      return Icons.support_agent_outlined;
    case 'support':
      return Icons.report_problem_outlined;
    default:
      return Icons.menu_book_outlined;
  }
}

class SystemContent {
  const SystemContent({
    required this.slug,
    required this.title,
    required this.body,
    required this.published,
    required this.hasDraft,
    required this.version,
    this.publishedAt,
    this.updatedAt,
  });
  final String slug, title, body;
  final bool published, hasDraft;
  final int version;
  final DateTime? publishedAt, updatedAt;
  String get statusLabel {
    if (!published) {
      return 'Chưa xuất bản';
    }
    if (hasDraft) {
      return 'Có thay đổi nháp';
    }
    return 'Đã xuất bản';
  }

  factory SystemContent.fromJson(Map<String, dynamic> json) => SystemContent(
    slug: json['slug'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    published: json['published'] == true,
    hasDraft: json['hasDraft'] == true,
    version: (json['version'] as num).toInt(),
    publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
  );
}

class PublishedContent {
  const PublishedContent({
    required this.slug,
    required this.title,
    required this.body,
    this.publishedAt,
  });
  final String slug, title, body;
  final DateTime? publishedAt;
  factory PublishedContent.fromJson(Map<String, dynamic> json) =>
      PublishedContent(
        slug: json['slug'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      );
}
