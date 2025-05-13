import 'package:flutter/material.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  late HubConnection _hub;
  late RTCPeerConnection _peer;
  late MediaStream _localStream;
  Function(MediaStream)? onRemoteStream;
  Function()? onCallRejected;
  Function()? onCallAccepted;
  String? _userId;

  final GlobalKey<NavigatorState> navigatorKey;

  SignalingService({required this.navigatorKey});

  // Connect to SignalR Hub
  Future<void> connect(String jwtToken, String userId) async {
    _userId = userId;

    _hub = HubConnectionBuilder()
        .withUrl(
      'http://10.0.2.2:5000/webrtchub?access_token=$jwtToken',
      HttpConnectionOptions(
        transport: HttpTransportType.webSockets,
      ),
    )
        .build();

    _hub.on('ReceiveOffer', (args) => _onOffer(args![0]));
    _hub.on('ReceiveAnswer', (args) => _onAnswer(args![0]));
    _hub.on('ReceiveIceCandidate', (args) => _onIceCandidate(args![0]));
    _hub.on('CallRejected', (args) => onCallRejected?.call());
    _hub.on('CallAccepted', (args) => onCallAccepted?.call());

    await _hub.start();
  }

  // Setup peer connection
  Future<void> setupPeerConnection(String toUserId) async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peer = await createPeerConnection(configuration);

    _peer.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate != null) {
        sendIceCandidate(toUserId, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    _peer.onAddStream = (MediaStream stream) {
      onRemoteStream?.call(stream);
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    _localStream.getTracks().forEach((track) {
      _peer.addTrack(track, _localStream);
    });
  }

  // Send offer to another user
  Future<void> sendOffer(String toUserId) async {
    await setupPeerConnection(toUserId);
    RTCSessionDescription offer = await _peer.createOffer();
    await _peer.setLocalDescription(offer);

    _hub.invoke('SendOffer', args: [
      toUserId,
      {
        'sdp': offer.sdp,
        'type': offer.type,
      }
    ]);
  }

  // Send answer
  void sendAnswer(String toUserId, dynamic answer) {
    _hub.invoke('SendAnswer', args: [toUserId, answer]);
  }

  // Send ICE
  void sendIceCandidate(String toUserId, dynamic candidate) {
    _hub.invoke('SendIceCandidate', args: [toUserId, candidate]);
  }

  // Reject call
  void rejectCall(String toUserId) {
    _hub.invoke('RejectCall', args: [toUserId]);
  }

  // Accept call
  void acceptCall(String toUserId) {
    _hub.invoke('AcceptCall', args: [toUserId]);
  }

  // Handle incoming offer with dialog
  Future<void> _onOffer(dynamic data) async {
    String fromUserId = data['from'];

    bool accepted = await showDialog<bool>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Incoming Call"),
          content: Text("You have a call from $fromUserId"),
          actions: [
            TextButton(
              onPressed: () {
                rejectCall(fromUserId);
                Navigator.of(context).pop(false);
              },
              child: const Text("Reject"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("Accept"),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!accepted) return;

    acceptCall(fromUserId);
    await setupPeerConnection(fromUserId);
    await _peer.setRemoteDescription(
      RTCSessionDescription(data['sdp'], data['type']),
    );
    RTCSessionDescription answer = await _peer.createAnswer();
    await _peer.setLocalDescription(answer);
    sendAnswer(fromUserId, {
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  // Handle answer
  Future<void> _onAnswer(dynamic data) async {
    await _peer.setRemoteDescription(
      RTCSessionDescription(data['sdp'], data['type']),
    );
  }

  // Handle ICE
  Future<void> _onIceCandidate(dynamic data) async {
    var candidate = RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );
    await _peer.addCandidate(candidate);
  }

  // Getters
  MediaStream getLocalStream() => _localStream;
  RTCPeerConnection get peer => _peer;

  // Cleanup
  void dispose() {
    _peer.close();
    _hub.stop();
  }
}
