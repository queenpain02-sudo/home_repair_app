import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_category_model.dart';

class ServiceCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categories {
    return _firestore.collection('service_categories');
  }

  // =========================
  // Get all categories
  // =========================
  Stream<List<ServiceCategoryModel>> getCategories() {
    return _categories.orderBy('sortOrder').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceCategoryModel.fromFirestore(doc))
          .toList();
    });
  }

  // =========================
  // Get active categories
  // =========================
  Stream<List<ServiceCategoryModel>> getActiveCategories() {
    return _categories
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ServiceCategoryModel.fromFirestore(doc))
              .toList();
        });
  }

  // =========================
  // Add category
  // =========================
  Future<void> addCategory({
    required String name,
    required String description,
    required String icon,
    required String imageUrl,
    required bool isActive,
    required int sortOrder,
  }) async {
    await _categories.add({
      'name': name.trim(),
      'description': description.trim(),
      'icon': icon.trim(),
      'imageUrl': imageUrl.trim(),
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // Update category
  // =========================
  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required String description,
    required String icon,
    required String imageUrl,
    required bool isActive,
    required int sortOrder,
  }) async {
    await _categories.doc(categoryId).update({
      'name': name.trim(),
      'description': description.trim(),
      'icon': icon.trim(),
      'imageUrl': imageUrl.trim(),
      'isActive': isActive,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // Toggle active / inactive
  // =========================
  Future<void> toggleCategoryStatus({
    required String categoryId,
    required bool isActive,
  }) async {
    await _categories.doc(categoryId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // Delete category
  // =========================
  Future<void> deleteCategory(String categoryId) async {
    await _categories.doc(categoryId).delete();
  }
}
