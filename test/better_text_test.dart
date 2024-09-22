import 'package:better_flutter/better_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  test('BetterText constructor parameters', () {
    const customStyle = TextStyle(fontStyle: FontStyle.italic);
    customAction() {}
    const customColor = Color(0xff000000);
    const defaultStyle = TextStyle(fontSize: 16);
    const textAlign = TextAlign.center;
    const textDirection = TextDirection.rtl;
    const locale = Locale('en', 'US');
    const maxLines = 2;
    const overflow = TextOverflow.ellipsis;
    const selectionColor = Color(0xff000000);
    const softWrap = false;
    const strutStyle = StrutStyle(fontSize: 16);
    const textHeightBehavior = TextHeightBehavior(applyHeightToFirstAscent: true, applyHeightToLastDescent: true);
    const textScaler = TextScaler.noScaling;
    const textWidthBasis = TextWidthBasis.parent;

    final widget = BetterText(
      'Test text',
      styles: const {'custom': customStyle},
      actions: {'tap': customAction},
      colors: const {'primary': customColor},
      defaultStyle: defaultStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      maxLines: maxLines,
      overflow: overflow,
      selectionColor: selectionColor,
      softWrap: softWrap,
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior,
      textScaler: textScaler,
      textWidthBasis: textWidthBasis,
      selectionRegistrar: null,
    );

    expect(widget.styles['custom'], equals(customStyle));
    expect(widget.actions['tap'], equals(customAction));
    expect(widget.colors['primary'], equals(customColor));
    expect(widget.defaultStyle, equals(defaultStyle));
    expect(widget.textAlign, equals(textAlign));
    expect(widget.textDirection, equals(textDirection));
    expect(widget.locale, equals(locale));
    expect(widget.maxLines, equals(maxLines));
    expect(widget.overflow, equals(overflow));
    expect(widget.selectionColor, equals(selectionColor));
    expect(widget.softWrap, equals(softWrap));
    expect(widget.strutStyle, equals(strutStyle));
    expect(widget.textHeightBehavior, equals(textHeightBehavior));
    expect(widget.textScaler, equals(textScaler));
    expect(widget.textWidthBasis, equals(textWidthBasis));
    expect(widget.selectionRegistrar, equals(null));
  });

  test('splitIntoSubstrings', () {
    final widget = BetterText('Hello, {world}!');

    // Basic case
    expect(widget.splitIntoSubstrings("Hello, {world}!"), ['Hello, ', '{world}', '!']);

    // Multiple tokens
    expect(widget.splitIntoSubstrings("This is a {test} with {multiple} tokens"), ['This is a ', '{test}', ' with ', '{multiple}', ' tokens']);

    // Empty string
    expect(widget.splitIntoSubstrings(""), []);

    // String with only tokens
    expect(widget.splitIntoSubstrings("{token1}{token2}{token3}"), ['{token1}', '{token2}', '{token3}']);

    // String with no tokens
    expect(widget.splitIntoSubstrings("Plain text without tokens"), ['Plain text without tokens']);

    // Nested tokens (not supported, but should handle gracefully)
    expect(widget.splitIntoSubstrings("Nested {outer{inner}}"), ['Nested ', '{outer{inner}}']);

    // Unmatched brackets (should be ignored)
    expect(widget.splitIntoSubstrings("Unmatched {bracket"), ['Unmatched ', 'bracket']);

    // Empty tokens
    expect(widget.splitIntoSubstrings("Empty {} token"), ['Empty ', '{}', ' token']);

    // Whitespace in tokens
    expect(widget.splitIntoSubstrings("Whitespace { in token }"), ['Whitespace ', '{ in token }']);
  });

  test('splitTokens', () {
    final widget = BetterText(
      '',
      styles: const {'custom': TextStyle(fontStyle: FontStyle.italic)},
      actions: {'tap': () {}},
      colors: const {'primary': Color(0xff000000)},
    );
    final failedCases = [];

    final testCases = {
      "bold Hello, world!": (['bold'], 'Hello, world!'),
      "bold italic Styled text": (['bold', 'italic'], 'Styled text'),
      "Plain text": ([], 'Plain text'),
      "bold ": (['bold'], ''),
      "bold italic underline Text": (['bold', 'italic', 'underline'], 'Text'),
      "": ([], ''),
      "bold Unclosed": (['bold'], 'Unclosed'),
      "boldText": ([], 'boldText'),
      "custom Styled text": (['custom'], 'Styled text'),
      "tap Clickable text": (['tap'], 'Clickable text'),
      "primary Colored text": (['primary'], 'Colored text'),
    };

    testCases.forEach((input, expected) {
      try {
        final result = widget.splitTokens(input);
        expect(result.$1, expected.$1, reason: 'Tokens mismatch for input: $input');
        expect(result.$2, expected.$2, reason: 'Content mismatch for input: $input');
      } catch (e) {
        failedCases.add('Failed case: $input\nError: $e');
      }
    });

    if (failedCases.isNotEmpty) {
      fail('The following test cases failed:\n${failedCases.join('\n\n')}');
    }
  });

  group('buildSpans', () {
    final mockContext = MockBuildContext();
    const defaultTextStyle = TextStyle(fontSize: 14, color: Color(0xff000000));
    when(DefaultTextStyle.of(mockContext).style).thenReturn(defaultTextStyle);

    final widget = BetterText(
      'Test text',
      defaultStyle: const TextStyle(fontSize: 16),
      styles: const {'custom': TextStyle(fontStyle: FontStyle.italic)},
      actions: {'tap': () {}},
      colors: const {'primary': Colors.blue},
    );

    test('empty substrings', () {
      final spans = widget.buildSpans(mockContext, []);
      expect(spans.length, 1);
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'Test text');
      expect((spans[0] as TextSpan).style?.fontSize, 16);
    });

    test('substrings without tokens', () {
      final spans = widget.buildSpans(mockContext, [([], 'Plain text')]);
      expect(spans.length, 1);
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'Plain text');
      expect((spans[0] as TextSpan).style?.fontSize, 16);
    });

    test('substrings with default tokens', () {
      final spans = widget.buildSpans(mockContext, [
        (['bold'], 'Bold text')
      ]);
      expect(spans.length, 1);
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'Bold text');
      expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
    });

    test('substrings with custom styles', () {
      final spans = widget.buildSpans(mockContext, [
        (['custom'], 'Italic text')
      ]);
      expect(spans.length, 1);
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'Italic text');
      expect((spans[0] as TextSpan).style?.fontStyle, FontStyle.italic);
    });

    test('substrings with colors', () {
      final spans = widget.buildSpans(mockContext, [
        (['primary'], 'Blue text')
      ]);
      expect(spans.length, 1);
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'Blue text');
      expect((spans[0] as TextSpan).style?.color, Colors.blue);
    });

    test('substrings with actions', () {
      final spans = widget.buildSpans(mockContext, [
        (['tap'], 'Tap me')
      ]);
      expect(spans.length, 1);
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'Tap me');
      expect((spans[0] as TextSpan).recognizer, isA<TapGestureRecognizer>());
    });

    test('multiple substrings', () {
      final spans = widget.buildSpans(mockContext, [
        (['bold'], 'Bold'),
        ([], ' and '),
        (['custom', 'primary'], 'Blue Italic'),
      ]);
      expect(spans.length, 3);
      expect((spans[0] as TextSpan).text, 'Bold');
      expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
      expect((spans[1] as TextSpan).text, ' and ');
      expect((spans[2] as TextSpan).text, 'Blue Italic');
      expect((spans[2] as TextSpan).style?.fontStyle, FontStyle.italic);
      expect((spans[2] as TextSpan).style?.color, Colors.blue);
    });
  });
}
