import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ProfileImageUploader extends StatefulWidget {
  const ProfileImageUploader({super.key});

  @override
  State<ProfileImageUploader> createState() => _ProfileImageUploaderState();
}

class _ProfileImageUploaderState extends State<ProfileImageUploader>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  File? _image;
  String? _imageUrl;
  final picker = ImagePicker();
  bool _isUploading = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!mounted) return;
    final data = doc.data();
    if (data != null && data.containsKey('profileImageUrl')) {
      final newUrl = data['profileImageUrl'];
      if (_imageUrl != newUrl) {
        setState(() {
          _imageUrl = newUrl;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Image Source'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
              onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      );
      if (source == null) return;
      final pickedFile = await picker.pickImage(source: source);
      if (!mounted) return;
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await _uploadImageToFirebase(_image!);
        await _loadProfileImage();
      }
    } catch (e) {
      logger.e('Error picking image: $e');
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _uploadImageToFirebase(File imageFile) async {
    try {
      setState(() {
        _isUploading = true;
      });
      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final ref = FirebaseStorage.instance.ref().child(
        "profile_images/$uid/profile.png",
      );

      try {
        await ref.delete();
      } catch (_) {}

      await ref.putFile(imageFile);
      final downloadURL = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profileImageUrl': downloadURL,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _imageUrl = downloadURL;
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile image uploaded successfully',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: SizedBox(
              width: 240,
              height: 240,
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.cover)
                  : _imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _imageUrl!,
                      cacheKey: fb_auth.FirebaseAuth.instance.currentUser?.uid,
                      cacheManager: CustomCacheManager.instance,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error, size: 50, color: Colors.red),
                    )
                  : const Icon(Icons.camera_alt, size: 50, color: Colors.white),
            ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const SweepGradient(
                        colors: [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.indigo,
                          Colors.purple,
                          Colors.red,
                        ],
                        startAngle: 0.0,
                        endAngle: 3.14 * 2,
                        tileMode: TileMode.clamp,
                      ).createShader(bounds);
                    },
                    child: const CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomCacheManager {
  static CacheManager instance = CacheManager(
    Config(
      'customProfileImageCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 20,
    ),
  );
}
