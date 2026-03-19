import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:punji/theme/app_ui_style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _picker = ImagePicker();

  bool _isLoading = false;
  String? _photoUrl;
  XFile? _pickedImage;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    final fallbackName =
        (user.userMetadata?['fullName'] ??
                user.userMetadata?['full_name'] ??
                user.email?.split('@').first ??
                'User')
            .toString();

    setState(() {
      _nameController.text = fallbackName;
      _emailController.text = user.email ?? '';
    });

    try {
      Map<String, dynamic>? row;
      try {
        row =
            await _client
                .from('users')
                .select('*')
                .eq('userId', user.id)
                .maybeSingle();
      } catch (_) {
        row =
            await _client
                .from('users')
                .select('*')
                .eq('userid', user.id)
                .maybeSingle();
      }
      final dbName = row?['fullname'];
      final dbEmail = row?['email'];
      final dbPhoto = row?['photourl'];

      final dbNameCamel = row?['fullName'];
      final dbPhotoCamel = row?['photoUrl'];

      if (!mounted) return;
      setState(() {
        if (dbName is String && dbName.trim().isNotEmpty) {
          _nameController.text = dbName;
        } else if (dbNameCamel is String && dbNameCamel.trim().isNotEmpty) {
          _nameController.text = dbNameCamel;
        }
        if (dbEmail is String && dbEmail.trim().isNotEmpty) {
          _emailController.text = dbEmail;
        }
        if (dbPhoto is String && dbPhoto.trim().isNotEmpty) {
          _photoUrl = dbPhoto;
        } else if (dbPhotoCamel is String && dbPhotoCamel.trim().isNotEmpty) {
          _photoUrl = dbPhotoCamel;
        }
      });
    } catch (_) {
      // Keep auth metadata fallback if users row is unavailable.
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1500,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _pickedImage = image;
    });
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_pickedImage == null) {
      return _photoUrl;
    }

    final bytes = await _pickedImage!.readAsBytes();
    final ext = _pickedImage!.path.split('.').last.toLowerCase();
    final safeExt =
        (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp')
            ? ext
            : 'jpg';
    final contentType =
        safeExt == 'png'
            ? 'image/png'
            : safeExt == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    final filePath =
        '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    await _client.storage
        .from('User Image')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(upsert: false, contentType: contentType),
        );

    return _client.storage.from('User Image').getPublicUrl(filePath);
  }

  Future<void> _upsertUserRow({
    required String userId,
    required String email,
    required String fullName,
    required String? photoUrl,
  }) async {
    try {
      await _client.from('users').upsert({
        'userId': userId,
        'email': email,
        'fullName': fullName,
        'photoUrl': photoUrl,
      });
    } catch (_) {
      await _client.from('users').upsert({
        'userid': userId,
        'email': email,
        'fullname': fullName,
        'photourl': photoUrl,
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in again.')));
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email cannot be empty.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uploadedPhotoUrl = await _uploadProfileImage(user.id);

      final attrs = UserAttributes(
        email: email != user.email ? email : null,
        data: {'fullName': name},
      );
      await _client.auth.updateUser(attrs);

      await _upsertUserRow(
        userId: user.id,
        email: email,
        fullName: name,
        photoUrl: uploadedPhotoUrl,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor:
                          isDark ? AppUiStyle.cardMuted(context) : Colors.grey.shade300,
                      child: ClipOval(
                        child:
                            _pickedImage != null
                                ? FutureBuilder<Uint8List>(
                                  future: _pickedImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Icon(
                                        Icons.person,
                                        size: 54,
                                        color: Colors.grey.shade700,
                                      );
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 108,
                                      height: 108,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                                : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? Image.network(
                                  _photoUrl!,
                                  width: 108,
                                  height: 108,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 54,
                                      color: Colors.grey.shade700,
                                    );
                                  },
                                )
                                : Icon(
                                  Icons.person,
                                  size: 54,
                                  color: Colors.grey.shade700,
                                ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: InkWell(
                        onTap: _isLoading ? null : _pickImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color:
                              AppUiStyle.primaryButton(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isDark
                                      ? const Color(0xFF1A1F28)
                                      : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _InputCard(
                label: 'Name',
                hint: 'Enter your name',
                controller: _nameController,
              ),
              const SizedBox(height: 14),
              _InputCard(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppUiStyle.primaryButton(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppUiStyle.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppUiStyle.border(context)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color:
                    Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.75),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
