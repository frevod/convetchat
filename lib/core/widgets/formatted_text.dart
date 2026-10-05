import 'package:flutter/gestures.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class const FormattedText({
  super.key,
  required final String html,
  required final TextStyle style,
  final TextStyle? linkStyle,
  final bool linkifyOnly = false,
  final bool selectable = false,
}) extends StatelessWidget {
  static FormattedText plain(
    String text, {
    Key? key,
    required TextStyle style,
    TextStyle? linkStyle,
    bool selectable = false,
  }) {
    return FormattedText(
      key: key,
      html: text,
      style: style,
      linkStyle: linkStyle,
      linkifyOnly: true,
      selectable: selectable,
    );
  }

  static final _linkPattern = RegExp(
    r'(?:https?://|www\.|matrix:)[^\s<]+',
  );

  static List<InlineSpan> _linkify(
    String text,
    TextStyle link,
  ) {
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in _linkPattern.allMatches(text)) {
      var end = match.end;
      while (end > match.start &&
          '.,;:!?)'.contains(text.substring(end - 1, end))) {
        end--;
      }
      if (match.start > offset) {
        spans.add(TextSpan(text: text.substring(offset, match.start)));
      }
      var url = text.substring(match.start, end);
      if (url.startsWith('www.')) url = 'https://$url';
      final uri = Uri.tryParse(url);
      spans.add(
        TextSpan(
          text: text.substring(match.start, end),
          style: link,
          recognizer: uri == null
              ? null
              : (TapGestureRecognizer()
                  ..onTap = () => launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  )),
        ),
      );
      if (end < match.end) {
        spans.add(TextSpan(text: text.substring(end, match.end)));
      }
      offset = match.end;
    }
    if (offset < text.length) {
      spans.add(TextSpan(text: text.substring(offset)));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveLinkStyle =
        linkStyle ??
        style.copyWith(
          color: scheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: scheme.primary,
        );
    if (linkifyOnly) {
      final span = TextSpan(
        children: _linkify(html, effectiveLinkStyle),
        style: style,
      );
      if (selectable) return SelectableText.rich(span);
      return Text.rich(span);
    }
    final body = html_parser.parse(html).body;
    final span = _renderNodes(
      body?.nodes ?? const <dom.Node>[],
      style,
      effectiveLinkStyle,
    );
    final textSpan = TextSpan(children: span, style: style);
    if (selectable) return SelectableText.rich(textSpan);
    return Text.rich(textSpan);
  }

  static List<InlineSpan> _renderNodes(
    List<dom.Node> nodes,
    TextStyle base,
    TextStyle link,
  ) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      spans.add(_renderNode(node, base, link));
      if (node is dom.Element && _isBlock(node.localName)) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    if (spans.isNotEmpty &&
        spans.last is TextSpan &&
        (spans.last as TextSpan).text == '\n') {
      spans.removeLast();
    }
    return spans;
  }

  static bool _isBlock(String? tag) {
    return switch (tag) {
      'p' || 'div' || 'blockquote' || 'pre' || 'ul' || 'ol' || 'table' => true,
      'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6' || 'li' => true,
      _ => false,
    };
  }

  static InlineSpan _renderNode(
    dom.Node node,
    TextStyle base,
    TextStyle link,
  ) {
    if (node is! dom.Element) {
      return TextSpan(text: node.text);
    }
    if (node.localName == 'mx-reply') {
      return const TextSpan();
    }
    if (node.localName == 'br') {
      return const TextSpan(text: '\n');
    }
    if (node.localName == 'hr') {
      return const TextSpan(text: '\n───\n');
    }
    if (node.localName == 'a') {
      final href = node.attributes['href'];
      final children = _renderNodes(node.nodes, base, link);
      if (href == null || href.isEmpty) {
        return TextSpan(children: children);
      }
      final uri = Uri.tryParse(href);
      return TextSpan(
        children: children,
        style: link,
        recognizer: uri == null
            ? null
            : (TapGestureRecognizer()
                ..onTap = () => launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                )),
      );
    }
    final childStyle = switch (node.localName) {
      'b' || 'strong' => const TextStyle(fontWeight: FontWeight.bold),
      'i' || 'em' => const TextStyle(fontStyle: FontStyle.italic),
      'u' => const TextStyle(decoration: TextDecoration.underline),
      's' || 'del' || 'strike' => const TextStyle(
        decoration: TextDecoration.lineThrough,
      ),
      'code' => TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['monospace'],
        backgroundColor: base.color?.withValues(alpha: 0.12),
      ),
      'pre' => const TextStyle(fontFamily: 'monospace'),
      'h1' => const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      'h2' => const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      'h3' => const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      'h4' || 'h5' || 'h6' => const TextStyle(fontWeight: FontWeight.bold),
      'blockquote' => const TextStyle(fontStyle: FontStyle.italic),
      _ => null,
    };
    final children = _renderNodes(node.nodes, base, link);
    if (node.localName == 'li') {
      return TextSpan(
        children: [const TextSpan(text: '• '), ...children],
        style: childStyle,
      );
    }
    if (childStyle == null) {
      return TextSpan(children: children);
    }
    return TextSpan(children: children, style: base.merge(childStyle));
  }
}
