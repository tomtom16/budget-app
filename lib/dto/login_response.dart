class LoginResponse {
  final String token;
  final String refreshToken;
  final String validUntil;
  final String username;
  final String uid;

  const LoginResponse({
    required this.token,
    required this.refreshToken,
    required String validUntil,
    required this.username,
    required this.uid
  }) : validUntil = validUntil;
}