import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/core/network/api_config.dart';
import 'package:rancakin_mobile/core/network/api_client.dart';
import 'package:rancakin_mobile/core/models/user_profile.dart';

void main() {
  group('ApiConfig Tests', () {
    test('Default configuration should be localhost:8080/api/v1', () {
      ApiConfig.useLocalhost();
      expect(ApiConfig.baseUrl, equals('http://localhost:8080/api/v1'));
      expect(ApiConfig.isAuthenticated, isFalse);
    });

    test('Switching environments should update baseUrl properly', () {
      ApiConfig.useAndroidEmulator();
      expect(ApiConfig.baseUrl, equals('http://10.0.2.2:8080/api/v1'));

      ApiConfig.useCloudflareTunnel('wisgo-demo.trycloudflare.com');
      expect(ApiConfig.baseUrl, equals('https://wisgo-demo.trycloudflare.com/api/v1'));

      ApiConfig.useProduction('wisgo-api.onrender.com');
      expect(ApiConfig.baseUrl, equals('https://wisgo-api.onrender.com/api/v1'));
    });

    test('Auth token storage should reflect authentication state', () {
      ApiConfig.setAuthToken('sample-jwt-token-2026');
      expect(ApiConfig.isAuthenticated, isTrue);
      expect(ApiConfig.authToken, equals('sample-jwt-token-2026'));

      ApiConfig.setAuthToken(null);
      expect(ApiConfig.isAuthenticated, isFalse);
    });

    test('Atomic setAuthSession and authNotifier should notify listeners', () {
      UserProfile? notifiedUser;
      void listener() {
        notifiedUser = ApiConfig.authNotifier.value;
      }

      ApiConfig.authNotifier.addListener(listener);

      const user = UserProfile(
        id: 'usr-999',
        phoneNumber: '628127578953',
        fullName: 'Luthfia Hasan',
        role: 'tourist',
      );

      ApiConfig.setAuthSession(token: 'jwt-token-abc', user: user);

      expect(ApiConfig.isAuthenticated, isTrue);
      expect(ApiConfig.currentUser?.id, equals('usr-999'));
      expect(ApiConfig.currentUserName, equals('Luthfia Hasan'));
      expect(ApiConfig.currentUserPhone, equals('628127578953'));
      expect(notifiedUser?.fullName, equals('Luthfia Hasan'));

      ApiConfig.clearAuth();
      expect(ApiConfig.isAuthenticated, isFalse);
      expect(ApiConfig.currentUser, isNull);
      expect(notifiedUser, isNull);

      ApiConfig.authNotifier.removeListener(listener);
    });
  });

  group('UserProfile Model Tests', () {
    test('fromJson and initials extraction', () {
      final json = {
        'id': 'usr-123',
        'phone_number': '6281211112222',
        'full_name': 'Siti Rahma',
        'role': 'tourist',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, equals('usr-123'));
      expect(profile.phoneNumber, equals('6281211112222'));
      expect(profile.fullName, equals('Siti Rahma'));
      expect(profile.initials, equals('SR'));

      const singleName = UserProfile(id: '1', phoneNumber: '62', fullName: 'Padang');
      expect(singleName.initials, equals('PA'));

      const blank = UserProfile(id: '2', phoneNumber: '62', fullName: '');
      expect(blank.initials, equals('W'));
    });
  });

  group('ApiResponse Model Tests', () {
    test('ApiResponse success and error factory constructors', () {
      final success = ApiResponse.success(
        message: 'Data berhasil diambil',
        data: {'total': 20},
      );
      expect(success.isSuccess, isTrue);
      expect(success.status, equals('success'));
      expect(success.statusCode, equals(200));

      final error = ApiResponse.error(
        message: 'Tiket QR tidak valid',
        statusCode: 400,
      );
      expect(error.isSuccess, isFalse);
      expect(error.status, equals('error'));
      expect(error.statusCode, equals(400));
    });
  });
}
