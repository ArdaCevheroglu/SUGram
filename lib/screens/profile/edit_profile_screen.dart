import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../view_models/user_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _departmentController;
  late TextEditingController _yearController;
  File? _profileImageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _usernameController = TextEditingController(text: widget.user.username);
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _bioController = TextEditingController(text: widget.user.bio);
    _departmentController = TextEditingController(text: widget.user.department);
    _yearController = TextEditingController(
      text: widget.user.year > 0 ? widget.user.year.toString() : '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Create updated user model
      final updatedUser = widget.user.copyWith(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        department: _departmentController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
      );

      final success = await userViewModel.updateUserProfile(
        updatedUser,
        profileImage: _profileImageFile,
      );

      if (success) {
        // Update the auth user if this is the current user
        if (authViewModel.currentUser?.id == widget.user.id) {
          await authViewModel.refreshUserData();
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userViewModel.error ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2.0,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile image
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50.0,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImageFile != null
                          ? FileImage(_profileImageFile!) as ImageProvider
                          : widget.user.profileImageUrl.isNotEmpty
                              ? NetworkImage(widget.user.profileImageUrl)
                              : null,
                      child: _profileImageFile == null &&
                              widget.user.profileImageUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50.0,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Username field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: Validators.validateUsername,
              ),
              const SizedBox(height: 16.0),
              
              // Full name field
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: Validators.validateFullName,
              ),
              const SizedBox(height: 16.0),
              
              // Bio field
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              
              // Department field
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Year field
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  hintText: '1-6',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Optional field
                  }
                  
                  final year = int.tryParse(value);
                  if (year == null) {
                    return 'Please enter a valid year';
                  }
                  
                  if (year < 1 || year > 6) {
                    return 'Year should be between 1 and 6';
                  }
                  
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}