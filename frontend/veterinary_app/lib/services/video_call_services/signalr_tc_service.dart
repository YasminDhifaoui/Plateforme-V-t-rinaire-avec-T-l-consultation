import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:veterinary_app/services/video_call_services/rtc_peer_service.dart';
import 'package:veterinary_app/utils/base_url.dart';

class SignalRTCService {
  static late HubConnection connection;
  static String? callerUserId;
  static String? targetUserId;

  static Future<void> init(String token) async {
    connection =
        HubConnectionBuilder()
            .withUrl(
              '${BaseUrl.api}/rtchub',
              HttpConnectionOptions(
                accessTokenFactory: () => Future.value(token),
              ),
            )
            .build();

    await connection.start();

    connection.on('ReceiveOffer', _handleOffer);
    connection.on('ReceiveAnswer', _handleAnswer);
    connection.on('ReceiveIceCandidate', _handleIceCandidate);
  }

  static Future<void> sendOffer(String targetUserId, dynamic offer) async {
    await connection.invoke('SendOffer', args: [targetUserId, offer]);
    SignalRTCService.targetUserId = targetUserId;
  }

  static Future<void> sendAnswer(String callerUserId, dynamic answer) async {
    await connection.invoke('SendAnswer', args: [callerUserId, answer]);
    SignalRTCService.callerUserId = callerUserId;
  }

  static Future<void> sendIceCandidate(
    String targetUserId,
    dynamic candidate,
  ) async {
    await connection.invoke(
      'SendIceCandidate',
      args: [targetUserId, candidate],
    );
  }

  static void _handleOffer(List<dynamic>? message) {
    if (message == null) return;
    callerUserId = message[0];
    final offer = RTCSessionDescription(message[1]['sdp'], message[1]['type']);
    RTCPeerService().setRemoteOffer(offer);
  }

  static void _handleAnswer(List<dynamic>? message) {
    if (message == null) return;
    final answer = RTCSessionDescription(message[0]['sdp'], message[0]['type']);
    RTCPeerService().setRemoteAnswer(answer);
  }

  static void _handleIceCandidate(List<dynamic>? message) {
    if (message == null) return;
    final candidate = RTCIceCandidate(
      message[0]['candidate'],
      message[0]['sdpMid'],
      message[0]['sdpMLineIndex'],
    );
    RTCPeerService().addIceCandidate(candidate);
  }

  static Future<void> disconnect() async {
    await connection.stop();
  }
}
