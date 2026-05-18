// Spec: AVATAR-UPLOAD-001-S1, S2, S3, S4
// Design: AD-60 — AvatarUploadService unit tests
// TDD: T-05 [RED] → T-06 [GREEN]

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage_client/storage_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nutriguide_mobile/features/profile/data/avatar_upload_service.dart';
import '../../../helpers/mock_supabase.dart';

class MockImagePicker extends Mock implements ImagePicker {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

// XFile is a concrete class — we can use it via path
class FakeXFile extends Fake implements XFile {
  FakeXFile(this.path);
  @override
  final String path;
  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList([0, 1, 2, 3]);
}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockImagePicker mockPicker;
  late MockSupabaseStorageClient mockStorage;
  late MockStorageFileApi mockStorageApi;
  late AvatarUploadService service;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const FileOptions());
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockPicker = MockImagePicker();
    mockStorage = MockSupabaseStorageClient();
    mockStorageApi = MockStorageFileApi();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockClient.storage).thenReturn(mockStorage);
    when(() => mockStorage.from('avatars')).thenReturn(mockStorageApi);

    service = AvatarUploadService(
      supabaseClient: mockClient,
      imagePicker: mockPicker,
    );
  });

  group('AvatarUploadService', () {
    const fakeUserId = 'user-123';
    const fakePath = 'user-123/avatar.jpg';
    const fakePublicUrl =
        'https://sireffsmpcjnpiqlnfqs.supabase.co/storage/v1/object/public/avatars/user-123/avatar.jpg';

    // -------------------------------------------------------------------------
    // AVATAR-UPLOAD-001-S2 — user cancels picker → throws AvatarUploadCancelled
    // -------------------------------------------------------------------------
    test('S2 — throws AvatarUploadCancelled when user cancels picker',
        () async {
      when(() => mockAuth.currentUser).thenReturn(createFakeUser(id: fakeUserId));
      when(() => mockPicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
          )).thenAnswer((_) async => null); // user cancelled

      await expectLater(
        service.pickAndUpload(fakeUserId),
        throwsA(isA<AvatarUploadCancelled>()),
      );
      // Storage never touched
      verifyNever(() => mockStorage.from(any()));
    });

    // -------------------------------------------------------------------------
    // AVATAR-UPLOAD-001-S1 — successful pick + upload → returns public URL
    // -------------------------------------------------------------------------
    test('S1 — returns public URL on successful pick and upload', () async {
      when(() => mockAuth.currentUser).thenReturn(createFakeUser(id: fakeUserId));
      when(() => mockPicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
          )).thenAnswer((_) async => FakeXFile('/tmp/avatar.jpg'));

      when(() => mockStorageApi.uploadBinary(
            fakePath,
            any(),
            fileOptions: any(named: 'fileOptions'),
          )).thenAnswer((_) async => fakePath);

      when(() => mockStorageApi.getPublicUrl(fakePath))
          .thenReturn(fakePublicUrl);

      final result = await service.pickAndUpload(fakeUserId);
      expect(result, fakePublicUrl);
    });

    // -------------------------------------------------------------------------
    // AVATAR-UPLOAD-001-S3 — upload failure → throws AvatarUploadFailed
    // -------------------------------------------------------------------------
    test('S3 — throws AvatarUploadFailed on upload error', () async {
      when(() => mockAuth.currentUser).thenReturn(createFakeUser(id: fakeUserId));
      when(() => mockPicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
          )).thenAnswer((_) async => FakeXFile('/tmp/avatar.jpg'));

      when(() => mockStorageApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          )).thenThrow(StorageException('Upload failed'));

      await expectLater(
        service.pickAndUpload(fakeUserId),
        throwsA(isA<AvatarUploadFailed>()),
      );
    });

    // -------------------------------------------------------------------------
    // AVATAR-UPLOAD-001-S4 — image quality constraints applied
    // -------------------------------------------------------------------------
    test('S4 — calls pickImage with maxWidth:512, maxHeight:512, imageQuality:80',
        () async {
      when(() => mockAuth.currentUser).thenReturn(createFakeUser(id: fakeUserId));
      when(() => mockPicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 80,
          )).thenAnswer((_) async => FakeXFile('/tmp/avatar.jpg'));

      when(() => mockStorageApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          )).thenAnswer((_) async => fakePath);

      when(() => mockStorageApi.getPublicUrl(fakePath))
          .thenReturn(fakePublicUrl);

      await service.pickAndUpload(fakeUserId);

      verify(() => mockPicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 80,
          )).called(1);
    });
  });
}
