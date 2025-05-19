import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/video_call_services/rtc_peer_service.dart';
import '../../services/video_call_services/signalr_tc_service.dart';


class VideoCallScreen extends StatefulWidget {
  final String targetUserId;

  const VideoCallScreen({Key? key, required this.targetUserId}) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCPeerService _rtcService = RTCPeerService();
  bool _isCallActive = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initCall();
  }


  Future<void> _initCall() async {
    try {
      // Step 1: Check if permissions are already granted
      var cameraStatus = await Permission.camera.status;
      var micStatus = await Permission.microphone.status;

      // Step 2: Request if not granted
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
      }
      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
      }

      // Step 3: Handle denied permissions
      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        if (await Permission.camera.isPermanentlyDenied ||
            await Permission.microphone.isPermanentlyDenied) {
          _openAppSettings(); // Guide user to enable manually
          return;
        }
        throw Exception('Permissions not granted');
      }

      // Step 4: Initialize WebRTC
      await _rtcService.initRenderers();
      await _rtcService.initWebRTC();
      final offer = await _rtcService.createOffer();
      await SignalRTCService.sendOffer(widget.targetUserId, {
        'sdp': offer.sdp,
        'type': offer.type,
      });
      setState(() => _isCallActive = true);

    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _openAppSettings() async {
    await openAppSettings();
    _handleError('Please enable permissions in Settings');
  }

  void _handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Remote video (fullscreen)
          RTCVideoView(_rtcService.remoteRenderer),

          // Local video (small overlay)
          Positioned(
            top: 20,
            right: 20,
            width: 120,
            height: 180,
            child: RTCVideoView(_rtcService.localRenderer),
          ),

          // Call controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.call_end, color: Colors.red),
                  onPressed: _endCall,
                ),
                IconButton(
                  icon: Icon(Icons.switch_camera, color: Colors.white),
                  onPressed: _rtcService.switchCamera,
                ),
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                  onPressed: _toggleMute,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMute() async {
    await _rtcService.toggleMute();
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _endCall() async {
    await _rtcService.dispose();
    await SignalRTCService.disconnect();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _rtcService.dispose();
    super.dispose();
  }
}