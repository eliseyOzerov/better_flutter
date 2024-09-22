import 'package:better_extensions/text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BetterText extends StatelessWidget {
  final String text;
  final TextStyle? defaultStyle;
  final Map<String, TextStyle> styles;
  final Map<String, VoidCallback> actions;
  final Map<String, Color> colors;

  // -- Standard rich text properties
  final Locale? locale;
  final int? maxLines;
  final TextOverflow overflow;
  final Color? selectionColor;
  final SelectionRegistrar? selectionRegistrar;
  final bool softWrap;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final TextHeightBehavior? textHeightBehavior;
  final TextScaler textScaler;
  final TextWidthBasis textWidthBasis;

  /// A widget that displays styled and interactive text.
  ///
  /// BetterText allows you to easily create rich text with custom styles, colors, and interactive elements.
  /// It supports markdown-like syntax for applying styles and actions to specific parts of the text.
  ///
  /// Example usage:
  /// ```dart
  /// BetterText(
  ///   'Hello, {bold world}! {red Click me}',
  ///   styles: {'custom': TextStyle(fontStyle: FontStyle.italic)},
  ///   actions: {'tap': () => print('Tapped!')},
  ///   colors: {'primary': Colors.blue},
  /// )
  /// ```
  ///
  /// [text] is the string to be displayed, which can include style tokens in curly braces.
  /// [defaultStyle] is the base style for the text.
  /// [styles] is a map of custom style tokens to TextStyle objects.
  /// [actions] is a map of action tokens to callback functions.
  /// [colors] is a map of color tokens to Color objects.
  ///
  /// The widget also supports standard text properties like [textAlign], [maxLines], etc.
  ///
  /// Default tokens available:
  /// - Font weights: 'thin', 'extraLight', 'light', 'regular', 'medium', 'semibold', 'bold', 'extraBold', 'heavy'
  /// - Decorations: 'italic', 'underline', 'strike'
  /// - Weight shorthands: '*' (bold), '/' (italic)
  /// - Decoration shorthands: '_' (underline), '~' (strikethrough)
  /// - Colors: 'red', 'blue', 'green', 'yellow', 'orange', 'purple', 'pink', 'brown', 'grey', 'black', 'white'
  BetterText(
    this.text, {
    super.key,
    this.defaultStyle,
    this.styles = const {},
    this.actions = const {},
    this.colors = const {},
    // -- Standard rich text properties
    this.locale,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.selectionColor,
    this.selectionRegistrar,
    this.softWrap = true,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textHeightBehavior,
    this.textScaler = TextScaler.noScaling,
    this.textWidthBasis = TextWidthBasis.parent,
  });

  final defaultTokens = {
    // Font weights
    'thin': const TextStyle().thin(),
    'extraLight': const TextStyle().extraLight(),
    'light': const TextStyle().light(),
    'regular': const TextStyle().regular(),
    'medium': const TextStyle().medium(),
    'semibold': const TextStyle().semibold(),
    'bold': const TextStyle().bold(),
    'extraBold': const TextStyle().extraBold(),
    'heavy': const TextStyle().black(),
    // Decorations
    'italic': const TextStyle().italic(),
    'underline': const TextStyle().underlined(),
    'strike': const TextStyle().strikethrough(),
    // Weight shorthands
    "*": const TextStyle().bold(),
    "/": const TextStyle().italic(),
    // Decoration shorthands
    "_": const TextStyle().underlined(),
    "~": const TextStyle().strikethrough(),
    // Colors
    'red': const TextStyle(color: Colors.red),
    'blue': const TextStyle(color: Colors.blue),
    'green': const TextStyle(color: Colors.green),
    'yellow': const TextStyle(color: Colors.yellow),
    'orange': const TextStyle(color: Colors.orange),
    'purple': const TextStyle(color: Colors.purple),
    'pink': const TextStyle(color: Colors.pink),
    'brown': const TextStyle(color: Colors.brown),
    'grey': const TextStyle(color: Colors.grey),
    'black': const TextStyle(color: Colors.black),
    'white': const TextStyle(color: Colors.white),
  };

  @visibleForTesting
  List<String> splitIntoSubstrings(String text) {
    final List<String> substrings = [];
    final RegExp regex = RegExp(r'(\{(?:[^{}]|\{[^{}]*\})*\}|[^{}]+)');
    final Iterable<Match> matches = regex.allMatches(text);
    for (final Match match in matches) {
      substrings.add(match.group(0)!);
    }
    return substrings;
  }

  @visibleForTesting
  (List<String> tokens, String content) splitTokens(String text) {
    if (text.isEmpty) {
      return ([], '');
    }
    final String noBraces = text.replaceAll("{", "").replaceAll("}", "");
    final List<String> parts = noBraces.split(" ").toList();
    final Set<String> tokens = {};
    int contentStartIndex = 0;

    for (int i = 0; i < parts.length; i++) {
      final String part = parts[i];
      if (!tokens.contains(part) && (defaultTokens.containsKey(part) || styles.containsKey(part) || colors.containsKey(part) || actions.containsKey(part))) {
        tokens.add(part);
      } else {
        contentStartIndex = i;
        break;
      }
    }

    final String content = parts.sublist(contentStartIndex).join(" ");
    return (tokens.toList(), content);
  }

  @visibleForTesting
  List<InlineSpan> buildSpans(BuildContext context, List<(List<String> tokens, String content)> substrings) {
    final List<InlineSpan> spans = [];
    if (substrings.isEmpty) {
      return [TextSpan(style: defaultStyle ?? DefaultTextStyle.of(context).style, text: text)];
    }
    for (final (tokens, content) in substrings) {
      TextStyle style = defaultStyle ?? DefaultTextStyle.of(context).style;
      List<VoidCallback> tapHandlers = [];
      if (tokens.isEmpty) {
        spans.add(TextSpan(style: style, text: content));
        continue;
      }
      for (final token in tokens) {
        if (defaultTokens.containsKey(token)) {
          style = style.merge(defaultTokens[token]!);
        }
        if (colors.containsKey(token)) {
          style = style.copyWith(color: colors[token]);
        }
        if (styles.containsKey(token)) {
          style = style.merge(styles[token]!);
        }
        if (actions.containsKey(token)) {
          tapHandlers.add(actions[token]!);
        }
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          for (final handler in tapHandlers) {
            handler();
          }
        };
      final span = TextSpan(style: style, text: content, recognizer: recognizer);
      spans.add(span);
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> substrings = splitIntoSubstrings(text);
    final List<(List<String> tokens, String content)> substringsWithTokens = substrings.map((substring) => splitTokens(substring)).toList();
    final List<InlineSpan> spans = buildSpans(context, substringsWithTokens);

    return RichText(
      text: TextSpan(
        style: defaultStyle ?? DefaultTextStyle.of(context).style,
        children: spans,
      ),
      // -- Standard rich text properties
      locale: locale,
      maxLines: maxLines,
      overflow: overflow,
      selectionColor: selectionColor,
      selectionRegistrar: selectionRegistrar,
      softWrap: softWrap,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      textHeightBehavior: textHeightBehavior,
      textScaler: textScaler,
      textWidthBasis: textWidthBasis,
    );
  }
}

extension BetterTextExtension on Text {
  BetterText better({Map<String, TextStyle> styles = const {}, String? stylesSeparator}) {
    return BetterText(
      data ?? '',
      styles: styles,
      defaultStyle: style,
    );
  }
}
