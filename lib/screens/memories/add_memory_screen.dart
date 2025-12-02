import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_colors.dart';
import '../../data/models/memory.dart';
import '../../providers/app_provider.dart';

class AddMemoryScreen extends StatefulWidget {
  final Memory? existingMemory;

  const AddMemoryScreen({super.key, this.existingMemory});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _personController = TextEditingController();
  final _memoryWordController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int _selectedYear = DateTime.now().year;
  String _selectedCategory = 'Special';
  File? _selectedImage;
  bool _isSaving = false;

  final List<String> _categories = ['Special', 'Routines', 'People', 'Places'];
  final List<int> _years = List.generate(100, (i) => DateTime.now().year - i);

  @override
  void initState() {
    super.initState();
    if (widget.existingMemory != null) {
      _nameController.text = widget.existingMemory!.name;
      _personController.text = widget.existingMemory!.personName;
      _memoryWordController.text = widget.existingMemory!.memoryWord;
      _descriptionController.text = widget.existingMemory!.description ?? '';
      _selectedYear = widget.existingMemory!.year;
      _selectedCategory = widget.existingMemory!.category;
      if (widget.existingMemory!.imagePath != null) {
        _selectedImage = File(widget.existingMemory!.imagePath!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _personController.dispose();
    _memoryWordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    }
  }

  Future<void> _saveMemory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final appProvider = context.read<AppProvider>();
      
      final memory = Memory(
        id: widget.existingMemory?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        year: _selectedYear,
        personName: _personController.text.trim(),
        memoryWord: _memoryWordController.text.trim(),
        imagePath: _selectedImage?.path,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        category: _selectedCategory,
        createdAt: widget.existingMemory?.createdAt ?? DateTime.now(),
        recallCount: widget.existingMemory?.recallCount ?? 0,
        lastRecalledAt: widget.existingMemory?.lastRecalledAt,
      );

      if (widget.existingMemory != null) {
        await appProvider.memoryRepository.updateMemory(memory);
      } else {
        await appProvider.memoryRepository.addMemory(memory);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingMemory != null
                ? 'Memory updated successfully!'
                : 'Memory saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving memory: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImagePicker(),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Memory Name',
                          hint: 'e.g., Birthday Party 2020',
                          icon: Icons.title_rounded,
                          validator: (v) => v?.isEmpty ?? true ? 'Please enter a name' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildYearPicker(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _personController,
                          label: 'Person',
                          hint: 'Who is in this memory?',
                          icon: Icons.person_rounded,
                          validator: (v) => v?.isEmpty ?? true ? 'Please enter a person' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _memoryWordController,
                          label: 'Memory Word',
                          hint: 'A key word to remember (e.g., "cake", "beach")',
                          icon: Icons.key_rounded,
                          validator: (v) => v?.isEmpty ?? true ? 'Please enter a memory word' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryPicker(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description (Optional)',
                          hint: 'Tell me more about this memory...',
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.existingMemory != null ? 'Edit Memory' : 'Create Memory',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _selectedImage == null ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(24),
          image: _selectedImage != null
              ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
              : null,
          boxShadow: AppColors.cardShadow,
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap to add photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildYearPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.tealGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Text(
            'Year',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundTop,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<int>(
              value: _selectedYear,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
              items: _years.map((year) => DropdownMenuItem(
                value: year,
                child: Text(
                  year.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              )).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedYear = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              final gradients = {
                'Special': AppColors.warmGradient,
                'Routines': AppColors.tealGradient,
                'People': AppColors.purpleGradient,
                'Places': AppColors.primaryGradient,
              };
              
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? gradients[category] : null,
                    color: isSelected ? null : AppColors.backgroundTop,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveMemory,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                widget.existingMemory != null ? 'Update Memory' : 'Save Memory',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }
}


