import 'package:flutter_test/flutter_test.dart';
import 'package:bangla_panjika_native/main.dart';

void main() {
  test('Bangla Panjika app can be created', () {
    const app = BanglaPanjikaApp();

    expect(app, isA<BanglaPanjikaApp>());
  });
}
