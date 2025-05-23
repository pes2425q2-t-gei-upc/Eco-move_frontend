import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  final FlutterSecureStorage storage;

  TokenService({required this.storage});

  Future<bool> deleteTokens() async {
    try {
      await storage.delete(key: 'access');
      await storage.delete(key: 'refresh');
      return true;
    } catch (e) {
      return false;
    }
  }
}
