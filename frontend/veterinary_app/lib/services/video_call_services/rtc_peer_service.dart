import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:veterinary_app/services/video_call_services/signalr_tc_service.dart';

class RTCPeerService {
  // Public renderers for UI access
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Private peer connection and stream
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _isMuted = false;

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }
 Future<void> initWebRTC() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      localRenderer.srcObject = _localStream;

      // Rest of your WebRTC initialization...
    } catch (e) {
      print('WebRTC initialization failed: $e');
      throw Exception('Failed to access camera/microphone');
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<void> setRemoteAnswer(RTCSessionDescription answer) async {
    await _peerConnection?.setRemoteDescription(answer);
  }

  Future<void> setRemoteOffer(RTCSessionDescription offer) async {
    await _peerConnection?.setRemoteDescription(offer);
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
    await _peerConnection?.addCandidate(candidate);
  }

  Future<void> switchCamera() async {
    await _localStream?.getVideoTracks()[0].switchCamera();
  }

  Future<void> toggleMute() async {
    final audioTracks = _localStream?.getAudioTracks();
    if (audioTracks != null && audioTracks.isNotEmpty) {
      _isMuted = !_isMuted;
      audioTracks[0].enabled = !_isMuted;
    }
  }

  Future<void> dispose() async {
    await _peerConnection?.close();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    _localStream?.getTracks().forEach((track) => track.stop());
  }
}