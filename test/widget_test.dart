import 'package:flutter_test/flutter_test.dart';
import 'package:runiverse/main.dart';

void main() {
  test('Runiverse uses the approved purple brand color', () {
    expect(purple.toARGB32(), 0xFF7657D6);
  });
}
