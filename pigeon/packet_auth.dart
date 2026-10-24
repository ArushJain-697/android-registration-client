import 'package:pigeon/pigeon.dart';

class PacketAuth {
  final String response;
  final String? errorCode;

  PacketAuth({
    required this.response,
    this.errorCode,
  });
}

@HostApi()
abstract class PacketAuthApi {
  @async
  PacketAuth authenticate(String username, String password);

  /// SAJEEV #55/#56: operator or supervisor authentication by face. Needs the single-use face ticket from the Java side.
  @async
  PacketAuth authenticateWithFace(String username);

  @async
  void syncPacketAll(List<String> packetIds);

  @async
  void uploadPacketAll(List<String> packetIds);

  @async
  List<String> getAllRegistrationPacket();

  @async
  List<String> getAllCreatedRegistrationPacket();

  @async
  void updatePacketStatus(
      String packetId, String? serverStatus, String clientStatus);

  @async
  void supervisorReview(
      String packetId, String supervisorStatus, String supervisorComment);
}
