import 'dart:math';

class SecurePassword {
  static const _chars =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

  static String generate({int length = 12}) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
  }
}
