import 'package:the_registry/features/documents/domain/image_picker_service.dart';

class FakeImagePickerService implements ImagePickerService {
  ImagePickResult cameraResult = const ImagePickResult.cancelled();
  ImagePickResult galleryResult = const ImagePickResult.cancelled();
  AppCameraLens? lastCameraLens;

  @override
  Future<ImagePickResult> pickFromCamera({
    AppCameraLens lens = AppCameraLens.back,
  }) async {
    lastCameraLens = lens;
    return cameraResult;
  }

  @override
  Future<ImagePickResult> pickFromGallery() async => galleryResult;
}
