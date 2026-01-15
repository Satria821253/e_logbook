import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../provider/user_provider.dart';
import '../../services/getAPi/profile_service.dart';
import '../../services/local_storage/local_profile_service.dart';
import 'edit_name_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return;

      if (!mounted) return;
      setState(() => _isLoading = true);

      // 1. Save locally first
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;
      final localPath = await LocalProfileService.saveProfilePictureLocally(
        image.path,
        userId: currentUser?.id.toString(),
        role: currentUser?.role,
      );
      
      if (localPath != null) {
        // 2. Update UI immediately with local file
        if (currentUser != null) {
          userProvider.setUser(currentUser.copyWith(profilePicture: 'file://$localPath'));
          // Force refresh to clear any cached images
          userProvider.refreshProfilePicture();
        }
        
        // 3. Try to upload to API in background
        try {
          print('📸 Starting photo upload to API...');
          final result = await ProfileService.updateProfile(photoPath: image.path);
          print('📸 Photo upload result: $result');
          
          if (result['success'] == true) {
            print('✅ Photo uploaded successfully, reloading profile...');
            // Reload from server to get API URL
            await _loadProfile();
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto profil berhasil diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            print('❌ Photo upload failed: ${result['message']}');
          }
        } catch (e) {
          print('❌ Photo upload exception: $e');
          // API failed but local save succeeded
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto tersimpan lokal, akan disinkronkan saat online'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan foto'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ProfileService.getProfile();
      if (result['success'] == true && result['user'] != null) {
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false)
              .setUser(result['user']);
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ubah Foto Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                icon: Icons.camera_alt,
                title: 'Ambil Foto',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildOptionTile(
                icon: Icons.photo_library,
                title: 'Pilih dari Galeri',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4F9C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: const Color(0xFF1B4F9C), size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required String title,
    required String value,
    String? subtitle,
    bool showCopy = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            // Title
            SizedBox(
              width: 120,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        if (showCopy)
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: subtitle));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Link disalin ke clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow icon for editable items
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.user;
                final photoUrl = user?.profilePicture;
                final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

                return GestureDetector(
                  onTap: _showImageSourcePicker,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: hasPhoto
                            ? (photoUrl.startsWith('file://')
                                ? FileImage(File(photoUrl.replaceFirst('file://', '')))
                                : NetworkImage(photoUrl)) as ImageProvider
                            : null,
                        child: !hasPhoto
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B4F9C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.user;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Nama Field
                      _buildProfileItem(
                        title: 'Nama',
                        value: user?.name ?? 'Nama Pengguna',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditNameScreen(),
                            ),
                          ).then((_) => _loadProfile());
                        },
                      ),
                      // Username Field
                      _buildProfileItem(
                        title: 'Nama Pengguna',
                        value: user?.username ?? 'username',
                        onTap: null, // Non-editable
                      ),
                      // URL Field (separate item)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          children: [
                            const SizedBox(width: 120), // Same width as title
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'elogbook.com/@${user?.username ?? 'username'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                        text: 'elogbook.com/@${user?.username ?? 'username'}',
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Link disalin ke clipboard'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.copy,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );              },
            ),
          ],
        ),
      ),
    );
  }
}
