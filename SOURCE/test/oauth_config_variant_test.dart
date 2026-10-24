import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/oauth_config.dart';
import 'package:zyra/config/zyra_app_variant.dart';

void main() {
  const productionWeb =
      '734578322486-gvi63m04ogd7bbmsunokuq2klkepetq1.apps.googleusercontent.com';
  const productionIos =
      '734578322486-eoh5ba4usl0svs9ihqh2ltagqfgusnft.apps.googleusercontent.com';

  group('Google OAuth app boundary', () {
    test('production accepts its complete production pair', () {
      expect(
        OAuthConfig.isGoogleConfigurationAllowed(
          variant: ZyraAppVariant.production,
          webClientId: productionWeb,
          iosClientId: productionIos,
        ),
        isTrue,
      );
    });

    test('Unsupported artifact refuses either production client', () {
      expect(
        OAuthConfig.isGoogleConfigurationAllowed(
          variant: ZyraAppVariant.unsupported,
          webClientId: productionWeb,
          iosClientId: '123456789-stagingios.apps.googleusercontent.com',
        ),
        isFalse,
      );
      expect(
        OAuthConfig.isGoogleConfigurationAllowed(
          variant: ZyraAppVariant.unsupported,
          webClientId: '123456789-stagingweb.apps.googleusercontent.com',
          iosClientId: productionIos,
        ),
        isFalse,
      );
    });

    test('Unsupported artifact denies an unapproved separate pair', () {
      expect(
        OAuthConfig.isGoogleConfigurationAllowed(
          variant: ZyraAppVariant.unsupported,
          webClientId: '123456789-stagingweb.apps.googleusercontent.com',
          iosClientId: '123456789-stagingios.apps.googleusercontent.com',
        ),
        isFalse,
      );
      expect(
        OAuthConfig.isGoogleConfigurationAllowed(
          variant: ZyraAppVariant.unsupported,
          webClientId: '',
          iosClientId: '123456789-stagingios.apps.googleusercontent.com',
        ),
        isFalse,
      );
      expect(
        OAuthConfig.isGoogleConfigurationAllowed(
          variant: ZyraAppVariant.unsupported,
          webClientId: '123456789-stagingweb.apps.googleusercontent.com',
          iosClientId: '987654321-stagingios.apps.googleusercontent.com',
        ),
        isFalse,
      );
    });
  });
}
