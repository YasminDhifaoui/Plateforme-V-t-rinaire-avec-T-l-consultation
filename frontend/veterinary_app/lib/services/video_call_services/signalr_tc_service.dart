import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:veterinary_app/services/video_call_services/rtc_peer_service.dart';
import 'package:veterinary_app/utils/base_url.dart';

class SignalRTCService {
  static late HubConnection connection;
  static String? callerUserId;
  static String? targetUserId;
  static Function(String)? onIncomingCall;
  static Function()? onCallAccepted;
  static Function(String)? onCallRejected;
  static Function()? onCallEnded;

  static Future<void> init(String token) async {
    connection = HubConnectionBuilder()
        .withUrl(
      '${BaseUrl.api}/rtchub',
      HttpConnectionOptions(
        accessTokenFactory: () => Future.value(token),
        logging: (level, message) => print(message),
      ),
    )
        .withAutomaticReconnect()
        .build();

    await connection.start();

    // WebRTC Signaling Handlers
    connection.on('ReceiveOffer', _handleOffer);
    connection.on('ReceiveAnswer', _handleAnswer);
    connection.on('ReceiveIceCandidate', _handleIceCandidate);

    // Call Management Handlers
    connection.on('IncomingCall', _handleIncomingCall);
    connection.on('CallAccepted', _handleCallAccepted);
    connection.on('CallRejected', _handleCallRejected);
    connection.on('CallEnded', _handleCallEnded);
  }

  // Call Management Methods
  static Future<void> initiateCall(String targetUserId) async {
    await connection.invoke('InitiateCall', args: [targetUserId]);
    SignalRTCService.targetUserId = targetUserId;
  }

  static Future<void> acceptCall(String callerUserId) async {
    await connection.invoke('AcceptCall', args: [callerUserId]);
    SignalRTCService.callerUserId = callerUserId;
  }

  static Future<void> rejectCall(String callerUserId, {String? reason}) async {
    await connection.invoke('RejectCall', args: [callerUserId, reason ?? 'Call rejected']);
  }

  static Future<void> endCall() async {
    if (callerUserId != null) {
      await connection.invoke('EndCall', args: [callerUserId]);
    } else if (targetUserId != null) {
      await connection.invoke('EndCall', args: [targetUserId]);
    }
    await RTCPeerService().endCall();
  }

  // WebRTC Signaling Methods
  static Future<void> sendOffer(String targetUserId, dynamic offer) async {
    await connection.invoke('SendOffer', args: [targetUserId, offer]);
  }

  static Future<void> sendAnswer(String callerUserId, dynamic answer) async {
    await connection.invoke('SendAnswer', args: [callerUserId, answer]);
  }

  static Future<void> sendIceCandidate(String targetUserId, dynamic candidate) async {
    await connection.invoke('SendIceCandidate', args: [targetUserId, candidate]);
  }

  // Handler Methods
  static void _handleIncomingCall(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    callerUserId = args[0];
    onIncomingCall?.call(callerUserId!);
  }

  static void _handleCallAccepted(List<dynamic>? args) {
    onCallAccepted?.call();
  }

  static void _handleCallRejected(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    onCallRejected?.call(args[0].toString());
  }

  static void _handleCallEnded(List<dynamic>? args) {
    onCallEnded?.call();
    RTCPeerService().endCall();
  }

  static void _handleOffer(List<dynamic>? args) {
    if (args == null || args.length < 2) return;
    callerUserId = args[0];
    final offer = RTCSessionDescription(args[1]['sdp'], args[1]['type']);
    RTCPeerService().setRemoteOffer(offer);
  }

  static void _handleAnswer(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    final answer = RTCSessionDescription(args[0]['sdp'], args[0]['type']);
    RTCPeerService().setRemoteAnswer(answer);
  }

  static void _handleIceCandidate(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    final candidate = RTCIceCandidate(
      args[0]['candidate'],
      args[0]['sdpMid'],
      args[0]['sdpMLineIndex'],
    );
    RTCPeerService().addIceCandidate(candidate);
  }
  // Inside SignalRTCService.dart
 /* static Function(String)? onIncomingCall;

// When initializing the service
  connection.on('IncomingCall', (args) {
  final callerId = args[0];
  if (onIncomingCall != null) {
  onIncomingCall!(callerId);
  }
  });*/

  static Future<void> disconnect() async {
    await connection.stop();
    callerUserId = null;
    targetUserId = null;
  }
}