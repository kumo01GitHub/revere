import 'package:flutter_test/flutter_test.dart';
import 'package:revere/src/utils/ansi_color.dart';

void main() {
  group('AnsiColor – constants', () {
    test('reset is correct escape sequence', () {
      expect(AnsiColor.reset, '\x1B[0m');
    });

    test('bold is correct escape sequence', () {
      expect(AnsiColor.bold, '\x1B[1m');
    });

    test('black is correct escape sequence', () {
      expect(AnsiColor.black, '\x1B[30m');
    });

    test('red is correct escape sequence', () {
      expect(AnsiColor.red, '\x1B[31m');
    });

    test('green is correct escape sequence', () {
      expect(AnsiColor.green, '\x1B[32m');
    });

    test('yellow is correct escape sequence', () {
      expect(AnsiColor.yellow, '\x1B[33m');
    });

    test('blue is correct escape sequence', () {
      expect(AnsiColor.blue, '\x1B[34m');
    });

    test('magenta is correct escape sequence', () {
      expect(AnsiColor.magenta, '\x1B[35m');
    });

    test('cyan is correct escape sequence', () {
      expect(AnsiColor.cyan, '\x1B[36m');
    });

    test('white is correct escape sequence', () {
      expect(AnsiColor.white, '\x1B[37m');
    });
  });

  group('AnsiColor – wrap', () {
    test('wraps text with color and reset', () {
      expect(AnsiColor.wrap('hello', AnsiColor.red), '\x1B[31mhello\x1B[0m');
    });

    test('wraps empty string', () {
      expect(AnsiColor.wrap('', AnsiColor.green), '\x1B[32m\x1B[0m');
    });

    test('wraps with bold', () {
      expect(
        AnsiColor.wrap('bold text', AnsiColor.bold),
        '\x1B[1mbold text\x1B[0m',
      );
    });

    test('resulting string starts with the color code', () {
      final result = AnsiColor.wrap('msg', AnsiColor.cyan);
      expect(result, startsWith(AnsiColor.cyan));
    });

    test('resulting string ends with reset', () {
      final result = AnsiColor.wrap('msg', AnsiColor.yellow);
      expect(result, endsWith(AnsiColor.reset));
    });

    test('text is preserved in the middle', () {
      const text = 'some text';
      final result = AnsiColor.wrap(text, AnsiColor.blue);
      expect(result.contains(text), isTrue);
    });
  });
}
