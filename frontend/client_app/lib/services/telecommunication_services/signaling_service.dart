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

  // Connect to SignalR Hub
  Future<void> connect(String jwtToken, String userId) async {
    _userId = userId;
    _hub = HubConnectionBuilder()
        .withUrl(
      'http://10.0.2.2:5000/webrtchub?access_token=$jwtToken',
      HttpConnectionOptions(transport: HttpTransportType.webSockets),
    )
        .build();

    // Listen to events from the SignalR Hub
    _hub.on('ReceiveOffer', (args) => _onOffer(args![0]));
    _hub.on('ReceiveAnswer', (args) => _onAnswer(args![0]));
    _hub.on('ReceiveIceCandidate', (args) => _onIceCandidate(args![0]));
    _hub.on('CallRejected', (args) => onCallRejected?.call());
    _hub.on('CallAccepted', (args) => onCallAccepted?.call());

    await _hub.start();
  }

  // Set up peer connection
  Future<void> setupPeerConnection(String toUserId) async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peer = await createPeerConnection(configuration);

    _peer.onIceCandidate = (RTCIceCandidate candidate) {
      sendIceCandidate(toUserId, {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
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

  // Send call offer to the other user
  Future<void> sendOffer(String toUserId) async {
    await setupPeerConnection(toUserId);
    RTCSessionDescription offer = await _peer.createOffer();
    await _peer.setLocalDescription(offer);

    _hub.invoke('SendOffer', args: [toUserId, {
      'sdp': offer.sdp,
      'type': offer.type,
    }]);
  }

  // Send call answer to the caller
  void sendAnswer(String toUserId, dynamic answer) {
    _hub.invoke('SendAnswer', args: [toUserId, answer]);
  }

  // Send ICE candidate
  void sendIceCandidate(String toUserId, dynamic candidate) {
    _hub.invoke('SendIceCandidate', args: [toUserId, candidate]);
  }

  // Reject the call
  void rejectCall(String toUserId) {
    _hub.invoke('RejectCall', args: [toUserId]);
  }

  // Accept the call
  void acceptCall(String toUserId) {
    _hub.invoke('AcceptCall', args: [toUserId]);
  }

  // Receive an incoming offer
  Future<void> _onOffer(dynamic data) async {
    String fromUserId = data['from'];
    await setupPeerConnection(fromUserId);
    await _peer.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
    RTCSessionDescription answer = await _peer.createAnswer();
    await _peer.setLocalDescription(answer);
    sendAnswer(fromUserId, {
      'sdp': answer.sdp,
      'type': answer.type,
    });
    print("Connected as $_userId");
    print("Offer received from: $fromUserId");

  }

  // Receive an answer
  Future<void> _onAnswer(dynamic data) async {
    await _peer.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
  }

  // Receive an ICE candidate
  Future<void> _onIceCandidate(dynamic data) async {
    var candidate = RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );
    await _peer.addCandidate(candidate);
  }

  // Get local media stream
  MediaStream getLocalStream() => _localStream;
  RTCPeerConnection get peer => _peer;

  // Dispose resources
  void dispose() {
    _peer.close();
    _hub.stop();
  }
}
