import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DocumentAttachmentPreviewPage extends StatelessWidget {
  const DocumentAttachmentPreviewPage({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.attachmentPreview)),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: InteractiveViewer(
          child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
