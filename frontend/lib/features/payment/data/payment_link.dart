String? paymentReferenceFromLink(String route) {
  final uri = Uri.tryParse(route);
  if (uri == null || uri.path != '/payment-result') return null;
  if (uri.hasScheme &&
      (uri.scheme != 'houserental' || uri.host != 'payments')) {
    return null;
  }
  try {
    return uri.queryParameters['reference'] ?? '';
  } on FormatException {
    return '';
  }
}
