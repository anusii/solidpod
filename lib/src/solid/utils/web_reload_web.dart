/// Web-specific implementation to reload the page.

library;

import 'package:web/web.dart' as web;

void reloadPage() {
  web.window.location.reload();
}
