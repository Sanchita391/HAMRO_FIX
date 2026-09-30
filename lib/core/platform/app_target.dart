import 'package:flutter/foundation.dart';

import 'package:hamro_fix/models/public_model.dart';

// Phone app: public and worker. Browser: official and admin.
// Same Firebase Auth users; the screen they see depends on the device.
class AppTarget {
  static bool get isWeb => kIsWeb;

  static bool get isMobileApp => !kIsWeb;

  static bool roleCanUseThisApp(String? role) {
    final normalized = UserRole.normalize(role);
    if (normalized == UserRole.official || normalized == UserRole.admin) {
      return isWeb;
    }
    if (normalized == UserRole.public || normalized == UserRole.worker) {
      return isMobileApp;
    }
    return false;
  }

  static bool get showStaffLanding => isWeb;

  static bool get showFieldLanding => isMobileApp;
}
