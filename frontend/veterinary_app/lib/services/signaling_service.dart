import 'package:signalr_core/signalr_core.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
class SignalingService {
  late HubConnection _hub;
  late RTCPeerConnection _peer;
  late MediaStream _localStream;

  Future<void> connect(String jwtToken, String userId) async {
    _hub = HubConnectionBuilder()
        .withUrl(
      'http://10.0.2.2:5000/webrtchub?access_token=$jwtToken',
      HttpConnectionOptions(
        transport: HttpTransportType.webSockets,
      ),
    )
        .build();

    _hub.on('ReceiveOffer', (args) => _onOffer(args![0], userId));
    _hub.on('ReceiveAnswer', (args) => _onAnswer(args![0]));
    _hub.on('ReceiveIceCandidate', (args) => _onIceCandidate(args![0]));

    await _hub.start();
  }

  Future<void> setupPeerConnection(String toUserId) async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    // createPeerConnection is asynchronous and returns a Future<RTCPeerConnection>
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

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    _localStream.getTracks().forEach((track) {
      _peer.addTrack(track, _localStream);
    });
  }

  void sendOffer(String toUserId) async {
    await setupPeerConnection(toUserId);
    RTCSessionDescription offer = await _peer.createOffer();
    await _peer.setLocalDescription(offer);

    _hub.invoke('SendOffer', args: [toUserId, {
      'sdp': offer.sdp,
      'type': offer.type,
    }]);
  }

  void sendAnswer(String toUserId, dynamic answer) {
    _hub.invoke('SendAnswer', args: [toUserId, answer]);
  }

  void sendIceCandidate(String toUserId, dynamic candidate) {
    _hub.invoke('SendIceCandidate', args: [toUserId, candidate]);
  }

  void _onOffer(dynamic data, String userId) async {
    await setupPeerConnection(userId);
    await _peer.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
    RTCSessionDescription answer = await _peer.createAnswer();
    await _peer.setLocalDescription(answer);
    sendAnswer(userId, {
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  void _onAnswer(dynamic data) async {
    await _peer.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
  }

  void _onIceCandidate(dynamic data) async {
    var candidate = RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );
    await _peer.addCandidate(candidate);
  }

  MediaStream getLocalStream() => _localStream;

  RTCPeerConnection get peer => _peer;

  // Dispose method to clean up the peer connection
  void dispose() {
    _peer.close();
    _hub.stop();
  }
}
