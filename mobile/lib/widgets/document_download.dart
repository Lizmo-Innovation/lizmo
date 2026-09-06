import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lizmo_api/api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Getting a lease document off the server and onto the phone.
///
/// Downloaded rather than opened in a browser. The URL is presigned and lapses
/// in minutes, so a browser tab is a view of something that will shortly stop
/// existing — which is no use for a signed contract, the whole point of which
/// is having your own copy. Fetching the bytes and handing them to the
/// platform's save sheet gives somebody a file they keep.
///
/// The share sheet rather than writing straight to Downloads: it needs no
/// storage permission on any Android version, and it lets the file go wherever
/// the person actually wants it — Files, Drive, an email to themselves.
class DocumentDownload {
  const DocumentDownload._();

  /// Fetches and offers to save. Returns an error message, or null on success.
  ///
  /// The caller shows the message. A download is started from a row in a list,
  /// and a dialog thrown over the list is a heavier interruption than the
  /// action deserves.
  static Future<String?> save(LeaseDocumentResponse document) async {
    final url = document.url;
    if (url == null) {
      return 'That document is not available just now.';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        // Almost always a lapsed link rather than a missing file. Reopening
        // the screen asks for a fresh one, which is the fix worth naming.
        return 'That link has expired. Close this and open it again.';
      }

      // The cache directory, not documents: this copy exists only to be handed
      // to the save sheet, and the real one is wherever the person puts it.
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${_filename(document)}');
      await file.writeAsBytes(response.bodyBytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: _label(document)),
      );
      return null;
    } catch (_) {
      return 'Could not download it just now. Please try again.';
    }
  }

  static String _label(LeaseDocumentResponse document) =>
      document.label ?? 'Document';

  /// A name somebody will recognise in their Downloads folder.
  ///
  /// Built from the label rather than the storage key, which is a UUID and
  /// tells a person nothing about which of four documents they just saved.
  static String _filename(LeaseDocumentResponse document) {
    final extension =
        document.contentType == 'application/pdf' ? 'pdf' : 'jpg';
    final safe = _label(document)
        .replaceAll(RegExp(r'[^A-Za-z0-9 ._-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    return '${safe.isEmpty ? 'document' : safe}.$extension';
  }
}

/// Kept beside the download so both sides of the app report it the same way.
void showDownloadError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
