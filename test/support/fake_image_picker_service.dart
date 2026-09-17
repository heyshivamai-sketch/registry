import 'package:the_registry/features/documents/domain/image_picker_service.dart';

class FakeImagePickerService implements ImagePickerService {
  ImagePickResult cameraResult = const ImagePickResult.cancelled();
  ImagePickResult galleryResult = const ImagePickResult.cancelled();

  @override
  Future<ImagePickResult> pickFromCamera() async => cameraResult;

  @override
  Future<ImagePickResult> pickFromGallery() async => galleryResult;
}
