import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' as md;

import '../models/uml_model.dart';


class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFe79aff) : const Color(0xFFf3ccff),
          borderRadius: BorderRadius.circular(16),
        ),
        child: isUser
            ? Text(
          message.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        )
            : Html(
          data: markdownToHtml(message.content),
          style: {
            "body": Style(color: Colors.black),
            "h1": Style(fontSize: FontSize.xLarge, fontWeight: FontWeight.bold),
            "h2": Style(fontSize: FontSize.larger, fontWeight: FontWeight.bold),
            "h3": Style(fontSize: FontSize.large, fontWeight: FontWeight.bold),
            "ul": Style(margin: Margins.only(bottom: 8)),
            "li": Style(margin: Margins.only(bottom: 6)),
            "code": Style(fontFamily: 'monospace', backgroundColor: Colors.black12),
            "p": Style(fontSize: FontSize.medium),
          },
        ),
      ),
    );
  }

  String markdownToHtml(String markdownText) {
    final safeMarkdown = markdownText
        .replaceAllMapped(RegExp(r'```(\w+)?([\s\S]*?)```'), (match) {
      return "<pre><code>${match.group(2)?.trim()}</code></pre>";
    })
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) {
      return "<b>${match.group(1)}</b>";
    })
        .replaceAllMapped(RegExp(r'_([^_]+)_'), (match) {
      return "<i>${match.group(1)}</i>";
    })
        .replaceAllMapped(RegExp(r'### (.*?)\n'), (match) {
      return "<h3>${match.group(1)}</h3>";
    })
        .replaceAllMapped(RegExp(r'1\. (.*?)\n'), (match) {
      return "<p>1. ${match.group(1)}</p>";
    });

    return "<body>$safeMarkdown</body>";
  }
}



  String _sanitizeMarkdown(String input) {
    final lines = input.split('\n');
    final output = <String>[];
    int codeBlockCount = 0;

    for (final line in lines) {
      final trimmed = line.trim();

      // Count code block openers
      if (trimmed.startsWith('```')) {
        codeBlockCount++;
        output.add(line);
        continue;
      }

      // Avoid leaving trailing ``` after diagram
      if (codeBlockCount % 2 != 0 &&
          trimmed.startsWith('###') ||
          trimmed.startsWith('1.') ||
          trimmed.startsWith('**')) {
        output.add('```'); // Close rogue code block before continuing
        codeBlockCount = 0;
      }

      output.add(line);
    }

    // Final fallback
    if (codeBlockCount % 2 != 0) {
      output.add('```'); // Close any remaining open code blocks
    }

    return output.join('\n');
  }




