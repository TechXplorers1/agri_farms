import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/language_provider.dart';
import '../services/translation_service.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translatedText = '';
  String _lastText = '';
  String _lastLang = '';

  @override
  void initState() {
    super.initState();
    _translatedText = widget.text;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translate();
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translate();
    }
  }

  Future<void> _translate() async {
    if (!mounted) return;
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.languageCode;
    
    if (widget.text == _lastText && lang == _lastLang) {
      return;
    }
    
    _lastText = widget.text;
    _lastLang = lang;

    if (lang == 'en' || widget.text.isEmpty || widget.text.trim() == '') {
      if (mounted) {
        setState(() {
          _translatedText = widget.text;
        });
      }
      return;
    }

    final result = await TranslationService().translate(widget.text, lang);
    if (mounted) {
      setState(() {
        _translatedText = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translatedText,
      style: widget.style,
      textAlign: widget.textAlign,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
    );
  }
}

/// Helper function to translate a string asynchronously based on current build context locale
Future<String> translateString(BuildContext context, String text) async {
  if (text.isEmpty || text.trim() == '') return text;
  final langProvider = Provider.of<LanguageProvider>(context, listen: false);
  final lang = langProvider.languageCode;
  if (lang == 'en') return text;
  return await TranslationService().translate(text, lang);
}

/// Dynamic Translation FutureBuilder for widgets that need to load text translations (e.g. lists, options, alerts)
class TranslationBuilder extends StatelessWidget {
  final List<String> texts;
  final Widget Function(BuildContext context, List<String> translatedTexts) builder;

  const TranslationBuilder({
    super.key,
    required this.texts,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).languageCode;
    if (lang == 'en') {
      return builder(context, texts);
    }

    return FutureBuilder<List<String>>(
      future: Future.wait(texts.map((text) => TranslationService().translate(text, lang))),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }
        return builder(context, texts); // Fallback to original text while loading
      },
    );
  }
}
