import 'package:image_picker/image_picker.dart';
import '../domain/image_picker_service.dart';

class ImagePickerImageService implements ImagePickerService {
  ImagePickerImageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const double _maxDimension = 1280;
  static const int _quality = 70;

  final ImagePicker _picker;

  @override
  Future<ImagePickResult> pickFromCamera({
    AppCameraLens lens = AppCameraLens.back,
  }) => _pick(ImageSource.camera, lens: lens);

  @override
  Future<ImagePickResult> pickFromGallery() => _pick(ImageSource.gallery);

  Future<ImagePickResult> _pick(
    ImageSource source, {
    AppCameraLens lens = AppCameraLens.back,
  }) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
        preferredCameraDevice: lens == AppCameraLens.front
            ? CameraDevice.front
            : CameraDevice.rear,
      );
      if (file == null) {
        return const ImagePickResult.cancelled();
      }
      final bytes = await file.readAsBytes();
      return ImagePickResult.success(bytes);
    } catch (_) {
      return const ImagePickResult.failed();
    }
  }
}
