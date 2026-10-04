import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> previewResourceFile({
  required String fileUrl,
  required String fileType,
}) async {
  final fileUri = Uri.parse(fileUrl);
  await launchUrl(fileUri, mode: LaunchMode.externalApplication);
}

Future<void> downloadResourceFile(String fileUrl) async {
  final uri = Uri.parse(fileUrl);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> copyTextWithMessage({
  required BuildContext context,
  required String text,
  required String message,
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> shareResourceLinks({
  required String text,
  required String subject,
}) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: subject));
}
