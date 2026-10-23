import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCategoryModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.imageUrl,
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceCategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ServiceCategoryModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      icon: data['icon']?.toString() ?? 'category',
      imageUrl: data['imageUrl']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] is int
          ? data['sortOrder'] as int
          : int.tryParse(data['sortOrder']?.toString() ?? '') ?? 0,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}
