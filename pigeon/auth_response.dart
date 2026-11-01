import 'package:pigeon/pigeon.dart';

class AuthResponse {
  final String response;
  final String userId;
  final String username;
  final String userEmail;
  final bool isOfficer;
  final bool isDefault;
  final bool isSupervisor;
  final bool isOperator;
  final String? errorCode;

  AuthResponse({
    required this.response,
    required this.userId,
    required this.username,
    required this.userEmail,
    required this.isOfficer,
    required this.isDefault,
    required this.isSupervisor,
    required this.isOperator,
    this.errorCode, 
  });
}

@HostApi()
abstract class AuthResponseApi {
  @async
  AuthResponse login(String username, String password, bool isConnected);
  /// SAJEEV #55: offline login after a face check that matched live. Needs the single-use face ticket from the Java side.
  @async
  AuthResponse loginWithFace(String username);
  @async
  String logout();
  @async
  String stopAlarmService();
  @async
  String forgotPasswordUrl();
  @async
  String getIdleTime();
  @async
  String getAutoLogoutPopupTimeout();
  @async
  List<String> getRolesByUserId(String userId);
  @async
  String getPasswordLength();
}
