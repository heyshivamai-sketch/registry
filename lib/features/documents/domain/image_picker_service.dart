import 'dart:typed_data';

enum ImagePickStatus { success, cancelled, failed }

class ImagePickResult {
  const ImagePickResult._(this.status, [this.bytes]);

  const ImagePickResult.success(Uint8List bytes)
    : this._(ImagePickStatus.success, bytes);

  const ImagePickResult.cancelled() : this._(ImagePickStatus.cancelled);

  const ImagePickResult.failed() : this._(ImagePickStatus.failed);

  final ImagePickStatus status;
  final Uint8List? bytes;

  bool get isSuccess => status == ImagePickStatus.success && bytes != null;
}

abstract class ImagePickerService {
  Future<ImagePickResult> pickFromCamera();

  Future<ImagePickResult> pickFromGallery();
}
