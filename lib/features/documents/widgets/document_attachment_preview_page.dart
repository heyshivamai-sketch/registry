import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DocumentAttachmentPreviewPage extends StatefulWidget {
  const DocumentAttachmentPreviewPage({
    super.key,
    required this.bytes,
    this.additionalImages = const [],
  });
  final Uint8List bytes;
  final List<Uint8List> additionalImages;

  @override
  State<DocumentAttachmentPreviewPage> createState() =>
      _DocumentAttachmentPreviewPageState();
}

class _DocumentAttachmentPreviewPageState
    extends State<DocumentAttachmentPreviewPage> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final images = [widget.bytes, ...widget.additionalImages];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.attachmentPreview)),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (_, index) => InteractiveViewer(
                  child: Center(
                    child: Image.memory(images[index], fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      color: Colors.white,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).previousPageTooltip,
                      onPressed: _index == 0
                          ? null
                          : () => _pages.jumpToPage(_index - 1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${_index + 1} / ${images.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      color: Colors.white,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).nextPageTooltip,
                      onPressed: _index == images.length - 1
                          ? null
                          : () => _pages.jumpToPage(_index + 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
