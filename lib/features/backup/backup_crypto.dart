import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:the_registry/features/backup/backup_models.dart';

/// Portable backup container, version 1.
///
/// ```
///  0 magic              4  RGRY
///  4 containerVersion   2  1
///  6 kdfId              1  1 = Argon2id (RFC 9106)
///  7 aeadId             1  1 = AES-256-GCM
///  8 memoryKiB          4  19456 (19 MiB, OWASP Argon2id)
/// 12 iterations         4  2
/// 16 parallelism        4  1
/// 20 hashLength         1  32
/// 21 salt              16  fresh
/// 37 verifierNonce     12  fresh
/// 49 payloadNonce      12  fresh
/// 61 verifierCipher     8
/// 69 verifierMac       16
/// 85 payloadLength      8  ciphertext length, excluding the 16-byte tag
/// 93 payload cipher || tag
/// ```
///
/// The whole payload, including counts and attachment bytes, is encrypted.
/// Only the KDF parameters, salt, and nonces are stored in the clear. A
/// separate GCM verifier distinguishes a wrong password from a changed
/// ciphertext. The password is not written into the file.
abstract final class RegistryBackupCrypto {
  static const magic = [0x52, 0x47, 0x52, 0x59]; // RGRY
  static const containerVersion = 1;
  static const kdfArgon2id = 1;
  static const aeadAes256Gcm = 1;
  static const argon2MemoryKiB = 19456;
  static const argon2Iterations = 2;
  static const argon2Parallelism = 1;
  static const argon2HashLength = 32;
  static const saltLength = 16;
  static const nonceLength = 12;
  static const tagLength = 16;
  static const verifierPlaintextLength = 8;
  static const headerLength = 93;

  static const _verifierPlaintext = [
    0x52, 0x47, 0x52, 0x59, // RGRY
    0x50, 0x57, 0x4F, 0x4B, // PWOK
  ];

  static final _cipher = AesGcm.with256bits();
  static final _random = SecureRandom.fast;

  static Future<Uint8List> encrypt({
    required Uint8List plaintext,
    required String password,
    required BackupCancelToken cancel,
  }) async {
    _requirePassword(password);
    cancel.throwIfCancelled();
    if (plaintext.length > BackupLimits.maxPlaintextBytes) {
      throw const BackupOversized();
    }
    if (_cipher.nonceLength != nonceLength ||
        _cipher.macAlgorithm.macLength != tagLength) {
      throw StateError('AES-GCM parameters do not match the backup format.');
    }
    final salt = _randomBytes(saltLength);
    final verifierNonce = _randomBytes(nonceLength);
    final payloadNonce = _distinctNonce(verifierNonce);
    final key = await _deriveKey(password: password, salt: salt);
    try {
      cancel.throwIfCancelled();
      final verifier = await _cipher.encrypt(
        _verifierPlaintext,
        secretKey: key,
        nonce: verifierNonce,
        aad: _verifierAad(salt),
      );
      final header = _header(
        salt: salt,
        verifierNonce: verifierNonce,
        payloadNonce: payloadNonce,
        verifier: verifier,
        payloadCipherLength: plaintext.length,
      );
      final payload = await _cipher.encrypt(
        plaintext,
        secretKey: key,
        nonce: payloadNonce,
        aad: header,
      );
      if (payload.cipherText.length != plaintext.length ||
          payload.mac.bytes.length != tagLength) {
        throw StateError('AES-GCM output does not match the backup format.');
      }
      cancel.throwIfCancelled();
      final file = Uint8List(
        header.length + payload.cipherText.length + tagLength,
      );
      file.setAll(0, header);
      file.setAll(header.length, payload.cipherText);
      file.setAll(header.length + payload.cipherText.length, payload.mac.bytes);
      if (file.length > BackupLimits.maxBackupFileBytes) {
        file.fillRange(0, file.length, 0);
        throw const BackupOversized();
      }
      return file;
    } on SecretBoxAuthenticationError {
      throw const BackupInvalid('encrypt');
    } finally {
      key.destroy();
    }
  }

  static Future<Uint8List> decrypt({
    required Uint8List file,
    required String password,
    required BackupCancelToken cancel,
  }) async {
    _requirePassword(password);
    cancel.throwIfCancelled();
    if (file.length > BackupLimits.maxBackupFileBytes) {
      throw const BackupOversized();
    }
    if (file.length < headerLength + tagLength) {
      throw const BackupInvalid('truncated');
    }
    if (!_matches(file, 0, magic)) {
      throw const BackupInvalid('magic');
    }
    final version = _u16(file, 4);
    final kdfId = file[6];
    final aeadId = file[7];
    if (version != containerVersion ||
        kdfId != kdfArgon2id ||
        aeadId != aeadAes256Gcm) {
      throw const BackupUnsupportedVersion();
    }
    final memoryKiB = _u32(file, 8);
    final iterations = _u32(file, 12);
    final parallelism = _u32(file, 16);
    final hashLength = file[20];
    if (hashLength != argon2HashLength ||
        parallelism != argon2Parallelism ||
        iterations < 1 ||
        iterations > 4 ||
        memoryKiB < 8192 ||
        memoryKiB > 65536) {
      throw const BackupInvalid('kdf');
    }
    final salt = Uint8List.sublistView(file, 21, 37);
    final verifierNonce = Uint8List.sublistView(file, 37, 49);
    final payloadNonce = Uint8List.sublistView(file, 49, 61);
    final verifierCipher = Uint8List.sublistView(file, 61, 69);
    final verifierMac = Uint8List.sublistView(file, 69, 85);
    final payloadCipherLength = _u64(file, 85);
    if (payloadCipherLength > BackupLimits.maxPlaintextBytes) {
      throw const BackupOversized();
    }
    final payloadStart = headerLength;
    final payloadEnd = payloadStart + payloadCipherLength;
    if (payloadEnd + tagLength != file.length) {
      throw const BackupInvalid('length');
    }
    cancel.throwIfCancelled();
    final key = await _deriveKey(
      password: password,
      salt: salt,
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: hashLength,
    );
    try {
      cancel.throwIfCancelled();
      try {
        final verified = await _cipher.decrypt(
          SecretBox(
            verifierCipher,
            nonce: verifierNonce,
            mac: Mac(verifierMac),
          ),
          secretKey: key,
          aad: _verifierAad(salt),
        );
        if (verified.length != _verifierPlaintext.length) {
          throw const BackupTampered();
        }
        for (var i = 0; i < verified.length; i++) {
          if (verified[i] != _verifierPlaintext[i]) {
            throw const BackupTampered();
          }
        }
      } on SecretBoxAuthenticationError {
        throw const BackupWrongPassword();
      }
      cancel.throwIfCancelled();
      try {
        final header = Uint8List.sublistView(file, 0, headerLength);
        final plaintext = await _cipher.decrypt(
          SecretBox(
            Uint8List.sublistView(file, payloadStart, payloadEnd),
            nonce: payloadNonce,
            mac: Mac(Uint8List.sublistView(file, payloadEnd)),
          ),
          secretKey: key,
          aad: header,
        );
        return Uint8List.fromList(plaintext);
      } on SecretBoxAuthenticationError {
        throw const BackupTampered();
      }
    } finally {
      key.destroy();
    }
  }

  static Future<SecretKeyData> _deriveKey({
    required String password,
    required List<int> salt,
    int memoryKiB = argon2MemoryKiB,
    int iterations = argon2Iterations,
    int parallelism = argon2Parallelism,
    int hashLength = argon2HashLength,
  }) async {
    final encoded = utf8.encode(password);
    final passwordBytes = Uint8List.fromList(encoded);
    encoded.fillRange(0, encoded.length, 0);
    final passwordKey = SecretKeyData(
      passwordBytes,
      overwriteWhenDestroyed: true,
    );
    try {
      final derived = await Argon2id(
        parallelism: parallelism,
        memory: memoryKiB,
        iterations: iterations,
        hashLength: hashLength,
      ).deriveKey(secretKey: passwordKey, nonce: salt);
      final material = await derived.extract();
      final copy = SecretKeyData(
        Uint8List.fromList(material.bytes),
        overwriteWhenDestroyed: true,
      );
      material.destroy();
      return copy;
    } finally {
      passwordKey.destroy();
    }
  }

  static Uint8List _header({
    required List<int> salt,
    required List<int> verifierNonce,
    required List<int> payloadNonce,
    required SecretBox verifier,
    required int payloadCipherLength,
  }) {
    if (verifier.cipherText.length != verifierPlaintextLength ||
        verifier.mac.bytes.length != tagLength) {
      throw StateError('Backup verifier size is not the AES-GCM result.');
    }
    final header = Uint8List(headerLength);
    header.setAll(0, magic);
    header[4] = 0;
    header[5] = containerVersion;
    header[6] = kdfArgon2id;
    header[7] = aeadAes256Gcm;
    _putU32(header, 8, argon2MemoryKiB);
    _putU32(header, 12, argon2Iterations);
    _putU32(header, 16, argon2Parallelism);
    header[20] = argon2HashLength;
    header.setAll(21, salt);
    header.setAll(37, verifierNonce);
    header.setAll(49, payloadNonce);
    header.setAll(61, verifier.cipherText);
    header.setAll(69, verifier.mac.bytes);
    _putU64(header, 85, payloadCipherLength);
    return header;
  }

  static List<int> _verifierAad(List<int> salt) {
    return [...utf8.encode('registry-backup-v1-verifier'), ...salt];
  }

  static void _requirePassword(String password) {
    final length = password.length;
    if (length < BackupLimits.minPasswordLength ||
        length > BackupLimits.maxPasswordLength) {
      throw const BackupInvalid('password');
    }
  }

  static Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var index = 0; index < length; index++) {
      bytes[index] = _random.nextInt(256);
    }
    return bytes;
  }

  static Uint8List _distinctNonce(List<int> other) {
    while (true) {
      final nonce = _randomBytes(nonceLength);
      var same = true;
      for (var i = 0; i < nonce.length; i++) {
        if (nonce[i] != other[i]) {
          same = false;
          break;
        }
      }
      if (!same) {
        return nonce;
      }
    }
  }

  static bool _matches(Uint8List bytes, int offset, List<int> expected) {
    if (offset + expected.length > bytes.length) {
      return false;
    }
    for (var i = 0; i < expected.length; i++) {
      if (bytes[offset + i] != expected[i]) {
        return false;
      }
    }
    return true;
  }

  static int _u16(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  static int _u32(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  static int _u64(Uint8List bytes, int offset) {
    return (_u32(bytes, offset) << 32) | _u32(bytes, offset + 4);
  }

  static void _putU32(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 24) & 0xFF;
    bytes[offset + 1] = (value >> 16) & 0xFF;
    bytes[offset + 2] = (value >> 8) & 0xFF;
    bytes[offset + 3] = value & 0xFF;
  }

  static void _putU64(Uint8List bytes, int offset, int value) {
    _putU32(bytes, offset, value >> 32);
    _putU32(bytes, offset + 4, value & 0xFFFFFFFF);
  }
}
