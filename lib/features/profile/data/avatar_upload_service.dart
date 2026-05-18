// Spec: AVATAR-UPLOAD-001
// Design: AD-58 (path convention), AD-60 (no interface), AD-62 (gallery only)
// TDD: T-06 [GREEN] — AvatarUploadService implementation

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the user cancels the image picker without selecting an image.
class AvatarUploadCancelled implements Exception {
  const AvatarUploadCancelled();
}

/// Thrown when the Supabase Storage upload fails.
class AvatarUploadFailed implements Exception {
  const AvatarUploadFailed(this.message);
  final String message;

  @override
  String toString() => 'AvatarUploadFailed: $message';
}

/// Thin service that orchestrates image picking and Supabase Storage upload.
///
/// Constructor receives [SupabaseClient] (required) and an optional
/// [ImagePicker] for DI in tests (AD-60).
///
/// Method [pickAndUpload] picks an image from the gallery, uploads it to
/// the `avatars` bucket, and returns the public URL.
///
/// Throws [AvatarUploadCancelled] if the user cancels.
/// Throws [AvatarUploadFailed] if the upload fails.
class AvatarUploadService {
  AvatarUploadService({
    required SupabaseClient supabaseClient,
    ImagePicker? imagePicker,
  })  : _supabase = supabaseClient,
        _picker = imagePicker ?? ImagePicker();

  final SupabaseClient _supabase;
  final ImagePicker _picker;

  static const _bucket = 'avatars';

  /// Picks an image from the gallery and uploads it to Supabase Storage.
  ///
  /// [userId] is used as the folder prefix for the storage path.
  ///
  /// Returns the public URL of the uploaded avatar.
  /// Throws [AvatarUploadCancelled] if the user cancels the picker.
  /// Throws [AvatarUploadFailed] on upload error.
  Future<String> pickAndUpload(String userId) async {
    // 1. Pick image from gallery with quality constraints (AVATAR-UPLOAD-001-S4)
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (file == null) throw const AvatarUploadCancelled();

    // 2. Read bytes and upload (uploadBinary — cross-platform, AD-60)
    final bytes = await file.readAsBytes();
    final path = '$userId/avatar.jpg';

    try {
      await _supabase.storage.from(_bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true, // overwrite existing avatar (AD-58)
        ),
      );
    } catch (e) {
      throw AvatarUploadFailed(e.toString());
    }

    // 3. Get and return public URL (synchronous — returns String)
    return _supabase.storage.from(_bucket).getPublicUrl(path);
  }
}
