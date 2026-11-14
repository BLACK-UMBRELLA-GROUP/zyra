import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_code_link.dart';

const _code = 'ZYRA-7A2F-09D4-B81C-3E6A-5F0D';
const _address = 'https://zyraconnect.app/c';
const _userInfoSeparator = '@';

void main() {
  group('parseZyraCodeLink', () {
    test('accepts both locked paths and uppercases a lowercase code', () {
      expect(parseZyraCodeLink('$_address/#$_code'), _code);
      expect(parseZyraCodeLink('$_address#$_code'), _code);
      expect(parseZyraCodeLink('$_address/#${_code.toLowerCase()}'), _code);
    });

    const invalidLinks = {
      'an HTTP address': 'http://zyraconnect.app/c/#$_code',
      'the www host': 'https://www.zyraconnect.app/c/#$_code',
      'a different host': 'https://example.com/c/#$_code',
      'a deceptive subdomain': 'https://zyraconnect.app.example.com/c/#$_code',
      'ZYRA in the user info': 'https://zyraconnect.app@example.com/c/#$_code',
      'other user info on the ZYRA host':
          'https://other${_userInfoSeparator}zyraconnect.app/c/#$_code',
      'an explicit port': 'https://zyraconnect.app:443/c/#$_code',
      'a look-alike host': 'https://zyrac\u043Ennect.app/c/#$_code',
      'a look-alike code character':
          '$_address/#ZYRA-7\u04102F-09D4-B81C-3E6A-5F0D',
      'a different path': 'https://zyraconnect.app/code/#$_code',
      'a path needing normalization': 'https://zyraconnect.app/x/../c/#$_code',
      'a query': '$_address/?from=share#$_code',
      'an empty query': '$_address/?#$_code',
      'text after the code': '$_address/#$_code/extra',
      'a newline after the code': '$_address/#$_code\n',
      'an encoded fragment separator': '$_address/%23$_code',
      'an encoded fragment character':
          '$_address/#ZYRA-7%412F-09D4-B81C-3E6A-5F0D',
      'a short code': '$_address/#ZYRA-7A2F-09D4-B81C-3E6A',
      'a nonhexadecimal character': '$_address/#ZYRA-7G2F-09D4-B81C-3E6A-5F0D',
      'an empty fragment': '$_address/#',
      'a plain code': _code,
    };

    for (final invalid in invalidLinks.entries) {
      test('rejects ${invalid.key}', () {
        expect(parseZyraCodeLink(invalid.value), isNull);
      });
    }
  });

  test('builds the canonical link for a server code only', () {
    final link = zyraCodeLinkFor(_code);
    expect(link, '$_address/#$_code');
    expect(parseZyraCodeLink(link!), _code);
    expect(zyraCodeLinkFor('ABCDEF12'), isNull);
    expect(zyraCodeLinkFor('$_code\n'), isNull);
  });
}
