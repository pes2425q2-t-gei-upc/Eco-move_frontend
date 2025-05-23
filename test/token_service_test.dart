import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:eco_move_frontend/services/token_service.dart';

import 'token_service_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  group('TokenService', () {
    late MockFlutterSecureStorage mockStorage;
    late TokenService service;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      service = TokenService(storage: mockStorage);
    });

    test('deletes access and refresh tokens successfully', () async {
      when(mockStorage.delete(key: 'access')).thenAnswer((_) async {});
      when(mockStorage.delete(key: 'refresh')).thenAnswer((_) async {});

      final result = await service.deleteTokens();

      verify(mockStorage.delete(key: 'access')).called(1);
      verify(mockStorage.delete(key: 'refresh')).called(1);
      expect(result, true);
    });

    test('returns false when deletion fails', () async {
      when(mockStorage.delete(key: 'access')).thenThrow(Exception('Fail'));

      final result = await service.deleteTokens();

      expect(result, false);
    });
  });
}
