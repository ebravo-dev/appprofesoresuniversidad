import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:pointycastle/export.dart';
import '../utils/utils.dart';

/// Servicio de encriptación RSA para contraseñas
/// Usa RSA-OAEP con SHA-256 para coincidir con el backend Node.js
class EncryptionService {
  // Clave pública del servidor para encriptación RSA
  static const String _publicKeyPEM = '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArF5a3wJHLAyafBk7RLE2
0DrQUq+FTGtNt6Ve34p4OxAs/ckxm9+8KuuM46kvN0L/qYk2Ft3qaOxqdnNw3m2R
Yz9nkCELOz5jXwVwCImSWQn/C4PtRbUX6z2yCGYQtCqYkXT4UMypEbQOVWKrRUC/
J8BCkFe6C1/2kU1/299urYA5eFx7gbLiUmOkPYRg44Lc7/irI1tqMsqRimrPI1Og
+pao+JkMiwzWiLcboTkAPsxNu4Dp19NmHnxdGkpako/NceIJJVFAKiVnpp/mxX9z
8dnXQVnq5zh1odLfUQnGNUkKQwy6e5OvMgIdcdp33aYzI9mAA6dg/TP+xjQnxkSi
DjKL2sIEYQCoaFiPaL1wpU1jG2l/Qkbn0Fz1Pxwil0aAbryVzopbq6EVmJi8U6Tn
n/vQ2quR7zqkETp72Icyjq4xLw63Sq8qVNqU/H9LFy1X9jPYeJuX3eVtmxndSH9w
2R2KxXrtTtYHU3OPhVHMGKasNX0PUwpImweItflqgwr2JnuCm/0FfNKv1yD5gtQ2
LOY2yBSObPdgR2mwsrOgjZY4WkakPrj/8XZwBU12icM6ELW0bPADfljwFyVA9kKi
qYqvgD/QEu/W2SNd7XZTwyPTS2Bm9hekozPJxKaofYh4zXJ/j09blH6DRqEofnaC
XgPSfQyppuhJqPdt6Sr9L9kCAwEAAQ==
-----END PUBLIC KEY-----''';

  late final RSAPublicKey _publicKey;

  EncryptionService() {
    try {
      _publicKey = _parsePublicKey(_publicKeyPEM);
      Logger.info('EncryptionService inicializado con RSA-OAEP SHA-256');
    } catch (e, stackTrace) {
      Logger.error('Error al inicializar EncryptionService', e, stackTrace);
      rethrow;
    }
  }

  /// Parse la clave pública PEM usando el parser del paquete encrypt
  RSAPublicKey _parsePublicKey(String pem) {
    final parser = encrypt_pkg.RSAKeyParser();
    return parser.parse(pem) as RSAPublicKey;
  }

  /// Encripta una contraseña usando RSA-OAEP con SHA-256
  /// Esto coincide exactamente con el backend Node.js:
  /// padding: RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha256'
  String encryptPassword(String password) {
    try {
      Logger.info('Encriptando contraseña con RSA-OAEP SHA-256...');

      // Convertir password a bytes UTF-8
      final passwordBytes = Uint8List.fromList(utf8.encode(password));

      // Encriptar con OAEP + SHA-256
      final encryptedBytes = _encryptWithOAEP(passwordBytes);

      // Convertir a Base64
      final encryptedBase64 = base64.encode(encryptedBytes);

      Logger.info(
        'Contraseña encriptada correctamente (${encryptedBytes.length} bytes)',
      );
      return encryptedBase64;
    } catch (e, stackTrace) {
      Logger.error('Error al encriptar contraseña', e, stackTrace);
      rethrow;
    }
  }

  /// Encripta datos usando RSA-OAEP con SHA-256
  /// Matching Node.js crypto: RSA_PKCS1_OAEP_PADDING with SHA-256
  Uint8List _encryptWithOAEP(Uint8List data) {
    // Crear cipher OAEP con SHA-256
    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(
        true, // true = encrypt
        PublicKeyParameter<RSAPublicKey>(_publicKey),
      );

    return cipher.process(data);
  }

  /// Encripta datos genéricos usando RSA-OAEP SHA-256
  String encryptData(String data) {
    try {
      final dataBytes = Uint8List.fromList(utf8.encode(data));
      final encryptedBytes = _encryptWithOAEP(dataBytes);
      return base64.encode(encryptedBytes);
    } catch (e, stackTrace) {
      Logger.error('Error al encriptar datos', e, stackTrace);
      rethrow;
    }
  }
}
