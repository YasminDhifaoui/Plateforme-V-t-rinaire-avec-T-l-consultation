import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:veterinary_app/services/video_call_services/signalr_tc_service.dart';

class RTCPeerService {
  // Singleton instance
  static final RTCPeerService _instance = RTCPeerService._internal();
  factory RTCPeerService() => _instance;
  RTCPeerService._internal();

  // Public renderers for UI access
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Private peer connection and stream
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _isMuted = false;
  bool _isCameraOff = false;
  String? _currentCallId;

  // Configuration for WebRTC
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // Add your TURN servers here if needed
    ]
  };

  final Map<String, dynamic> _offerSdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> initWebRTC({bool isCaller = false}) async {
    try {
      // Initialize media devices
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      localRenderer.srcObject = _localStream;

      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration);

      // Add local stream to peer connection
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      // Set up ICE candidate handler
      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null && SignalRTCService.targetUserId != null) {
          SignalRTCService.sendIceCandidate(
            SignalRTCService.targetUserId!,
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          );
        }
      };

      // Set up track handler for remote stream
      _peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty && remoteRenderer.srcObject != event.streams[0]) {
          remoteRenderer.srcObject = event.streams[0];
        }
      };

      // Handle connection state changes
      _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
        if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          endCall();
        }
      };

    } catch (e) {
      print('WebRTC initialization failed: $e');
      throw Exception('Failed to initialize WebRTC: $e');
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection not initialized');
    }

    final offer = await _peerConnection!.createOffer(_offerSdpConstraints);
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<void> setRemoteAnswer(RTCSessionDescription answer) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(answer);
  }

  Future<void> setRemoteOffer(RTCSessionDescription offer) async {
    if (_peerConnection == null) return;

    await _peerConnection!.setRemoteDescription(offer);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    SignalRTCService.sendAnswer(
      SignalRTCService.callerUserId!,
      {
        'sdp': answer.sdp,
        'type': answer.type,
      },
    );
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) return;
    await _peerConnection!.addCandidate(candidate);
  }

  Future<void> switchCamera() async {
    if (_localStream == null) return;
    final videoTrack = _localStream!.getVideoTracks().first;
    await Helper.switchCamera(videoTrack);
  }

  Future<void> toggleMute() async {
    final audioTracks = _localStream?.getAudioTracks();
    if (audioTracks != null && audioTracks.isNotEmpty) {
      _isMuted = !_isMuted;
      audioTracks[0].enabled = !_isMuted;
    }
  }

  Future<void> toggleCamera() async {
    final videoTracks = _localStream?.getVideoTracks();
    if (videoTracks != null && videoTracks.isNotEmpty) {
      _isCameraOff = !_isCameraOff;
      videoTracks[0].enabled = !_isCameraOff;
    }
  }

  Future<void> endCall() async {
    await dispose();
    await SignalRTCService.disconnect();
  }

  Future<void> dispose() async {
    await _peerConnection?.close();
    _peerConnection = null;

    await localRenderer.dispose();
    await remoteRenderer.dispose();

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;

    _currentCallId = null;
    SignalRTCService.callerUserId = null;
    SignalRTCService.targetUserId = null;
  }
}