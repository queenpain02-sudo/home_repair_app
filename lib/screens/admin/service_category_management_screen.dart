import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/service_category_model.dart';
import '../../services/service_category_service.dart';

class ServiceCategoryManagementScreen extends StatefulWidget {
  const ServiceCategoryManagementScreen({super.key});

  @override
  State<ServiceCategoryManagementScreen> createState() =>
      _ServiceCategoryManagementScreenState();
}

class _ServiceCategoryManagementScreenState
    extends State<ServiceCategoryManagementScreen> {
  final ServiceCategoryService _categoryService = ServiceCategoryService();

  Future<void> _showCategoryDialog({ServiceCategoryModel? category}) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: category?.name ?? '');

    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );

    final iconController = TextEditingController(
      text: category?.icon ?? 'category',
    );

    final sortOrderController = TextEditingController(
      text: category?.sortOrder.toString() ?? '0',
    );

    bool isActive = category?.isActive ?? true;
    String imageUrl = category?.imageUrl ?? '';
    File? selectedImageFile; // 🌟 ဖုန်းမှ ရွေးချယ်ထားသော ပုံဖိုင်

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 🖼️ Gallery မှ ပုံရွေးချယ်သည့် Function
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 70,
              );

              if (pickedFile != null) {
                setDialogState(() {
                  selectedImageFile = File(pickedFile.path);
                  imageUrl = pickedFile.path; // သို့မဟုတ် Storage တင်မည့် path
                });
              }
            }

            Future<void> save() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                final icon = iconController.text.trim();

                final sortOrder =
                    int.tryParse(sortOrderController.text.trim()) ?? 0;

                if (category == null) {
                  await _categoryService.addCategory(
                    name: name,
                    description: description,
                    icon: icon,
                    imageUrl: imageUrl,
                    isActive: isActive,
                    sortOrder: sortOrder,
                  );
                } else {
                  await _categoryService.updateCategory(
                    categoryId: category.id,
                    name: name,
                    description: description,
                    icon: icon,
                    imageUrl: imageUrl,
                    isActive: isActive,
                    sortOrder: sortOrder,
                  );
                }

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      category == null
                          ? 'Category added successfully.'
                          : 'Category updated successfully.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  saving = false;
                });

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save category: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                category == null
                    ? 'Add Service Category'
                    : 'Edit Service Category',
              ),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🌟 ပုံပေါ်လာရန် နှင့် နှိပ်၍ ပုံပြောင်းရန် UI
                        GestureDetector(
                          onTap: saving ? null : pickImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: selectedImageFile != null
                                    ? FileImage(selectedImageFile!)
                                    : (imageUrl.isNotEmpty && !imageUrl.startsWith('http') == false
                                        ? NetworkImage(imageUrl) as ImageProvider
                                        : null),
                                child: (selectedImageFile == null &&
                                        imageUrl.isEmpty)
                                    ? const Icon(
                                        Icons.add_a_photo,
                                        size: 30,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to pick category image',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Category Name',
                            hintText: 'Example: Electrical',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter category name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Describe this service category',
                            prefixIcon: Icon(Icons.description_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: iconController,
                          decoration: const InputDecoration(
                            labelText: 'Icon Name',
                            hintText: 'Example: electrical_services',
                            prefixIcon: Icon(Icons.insert_emoticon_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: sortOrderController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sort Order',
                            hintText: 'Example: 1',
                            prefixIcon: Icon(Icons.sort),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter sort order';
                            }

                            if (int.tryParse(value.trim()) == null) {
                              return 'Please enter a valid number';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active'),
                          subtitle: const Text(
                            'Customers can see this category',
                          ),
                          value: isActive,
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    isActive = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(category == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    iconController.dispose();
    sortOrderController.dispose();
  }

  Future<void> _toggleStatus(ServiceCategoryModel category) async {
    try {
      await _categoryService.toggleCategoryStatus(
        categoryId: category.id,
        isActive: !category.isActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category.isActive
                ? '${category.name} deactivated.'
                : '${category.name} activated.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCategory(ServiceCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _categoryService.deleteCategory(category.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCategoryIcon(
    BuildContext context,
    ServiceCategoryModel category,
  ) {
    // 🌟 ပုံရှိလျှင် ပုံပြသပေးပြီး၊ မရှိလျှင် icon ကို ပြသမည်
    if (category.imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: category.imageUrl.startsWith('http')
            ? NetworkImage(category.imageUrl) as ImageProvider
            : FileImage(File(category.imageUrl)),
      );
    }

    final iconName = category.icon.toLowerCase();
    IconData icon;

    switch (iconName) {
      case 'electrical_services':
        icon = Icons.electrical_services;
        break;
      case 'plumbing':
        icon = Icons.plumbing;
        break;
      case 'ac_unit':
        icon = Icons.ac_unit;
        break;
      case 'home_repair_service':
        icon = Icons.home_repair_service;
        break;
      case 'format_paint':
        icon = Icons.format_paint;
        break;
      case 'construction':
        icon = Icons.construction;
        break;
      case 'devices':
        icon = Icons.devices;
        break;
      case 'category':
      default:
        icon = Icons.category_outlined;
    }

    return CircleAvatar(radius: 28, child: Icon(icon, size: 28));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Categories'),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCategoryDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),

      body: StreamBuilder<List<ServiceCategoryModel>>(
        stream: _categoryService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load service categories.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 80),
                    SizedBox(height: 20),
                    Text(
                      'No Service Categories',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap "Add Category" to create your first service category.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: categories.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 10);
            },
            itemBuilder: (context, index) {
              final category = categories[index];

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  leading: _buildCategoryIcon(context, category),

                  title: Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: category.isActive
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: category.isActive
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Order: ${category.sortOrder}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showCategoryDialog(category: category);
                          break;

                        case 'toggle':
                          _toggleStatus(category);
                          break;

                        case 'delete':
                          _deleteCategory(category);
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                category.isActive
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                category.isActive ? 'Deactivate' : 'Activate',
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}