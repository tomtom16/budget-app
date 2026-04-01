import 'package:flutter/foundation.dart';

import 'token_storage.dart';
import 'mobile_token_storage.dart';
import 'web_token_storage.dart';

TokenStorage createTokenStorage() {
  if (kIsWeb) {
    return WebTokenStorage();
  } else {
    return MobileTokenStorage();
  }
}