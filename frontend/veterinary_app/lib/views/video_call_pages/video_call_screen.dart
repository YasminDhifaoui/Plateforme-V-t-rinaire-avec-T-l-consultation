import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/video_call_services/rtc_peer_service.dart';
import '../../services/video_call_services/signalr_tc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String targetUserId;
  final bool isCaller;

  const VideoCallScreen({
    Key? key,
    required this.targetUserId,
    this.isCaller = true,
  }) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCPeerService _rtcService = RTCPeerService();
  bool _isCallActive = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isLoading = true;
  String? _callStatus;

  @override
  void initState() {
    super.initState();
    _initCall();
    _setupSignalRListeners();
  }

  void _setupSignalRListeners() {
    SignalRTCService.onCallAccepted = () {
      setState(() {
        _isCallActive = true;
        _callStatus = null;
      });
    };

    SignalRTCService.onCallRejected = (reason) {
      _handleError('Call rejected: $reason');
    };

    SignalRTCService.onCallEnded = () {
      _endCall(showMessage: false);
    };

    SignalRTCService.onIncomingCall = (callerId) {
      // Only relevant for receiver side
      if (!widget.isCaller) {
        setState(() => _callStatus = 'Incoming call...');
      }
    };
  }

  Future<void> _initCall() async {
    try {
      // Check and request permissions
      final permissions = await Future.wait([
        Permission.camera.request(),
        Permission.microphone.request(),
      ]);

      if (permissions.any((status) => !status.isGranted)) {
        if (await Permission.camera.isPermanentlyDenied ||
            await Permission.microphone.isPermanentlyDenied) {
          _openAppSettings();
          return;
        }
        throw Exception('Camera & microphone permissions required');
      }

      // Initialize WebRTC
      await _rtcService.initRenderers();
      await _rtcService.initWebRTC(isCaller: widget.isCaller);

      if (widget.isCaller) {
        // Caller logic
        final offer = await _rtcService.createOffer();
        await SignalRTCService.initiateCall(widget.targetUserId);
        await SignalRTCService.sendOffer(widget.targetUserId, {
          'sdp': offer.sdp,
          'type': offer.type,
        });
        setState(() => _isCallActive = true);
      } else {
        // Receiver logic
        setState(() => _callStatus = 'Connecting...');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _openAppSettings() async {
    await openAppSettings();
    _handleError('Please enable permissions in Settings');
  }

  void _handleError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
  }

  Future<void> _acceptCall() async {
    await SignalRTCService.acceptCall(SignalRTCService.callerUserId!);
    setState(() {
      _isCallActive = true;
      _callStatus = null;
    });
  }

  Future<void> _rejectCall() async {
    await SignalRTCService.rejectCall(
      SignalRTCService.callerUserId!,
      reason: 'User rejected the call',
    );
    Navigator.pop(context);
  }

  Future<void> _endCall({bool showMessage = true}) async {
    await SignalRTCService.endCall();
    if (mounted) {
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call ended')),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Remote video
          RTCVideoView(
            _rtcService.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),

          // Local video preview
          Positioned(
            top: 40,
            right: 20,
            width: 120,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: RTCVideoView(_rtcService.localRenderer),
              ),
            ),
          ),

          // Call status overlay
          if (_callStatus != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _callStatus!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    if (!widget.isCaller) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            heroTag: 'reject',
                            backgroundColor: Colors.red,
                            onPressed: _rejectCall,
                            child: const Icon(Icons.call_end),
                          ),
                          const SizedBox(width: 40),
                          FloatingActionButton(
                            heroTag: 'accept',
                            backgroundColor: Colors.green,
                            onPressed: _acceptCall,
                            child: const Icon(Icons.call),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Call controls
          if (_isCallActive)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // End call button
                  FloatingActionButton(
                    heroTag: 'end',
                    backgroundColor: Colors.red,
                    onPressed: _endCall,
                    child: const Icon(Icons.call_end),
                  ),

                  const SizedBox(width: 20),

                  // Camera switch button
                  FloatingActionButton(
                    heroTag: 'switch',
                    backgroundColor: Colors.blueGrey,
                    onPressed: _rtcService.switchCamera,
                    child: const Icon(Icons.switch_camera),
                  ),

                  const SizedBox(width: 20),

                  // Mic toggle button
                  FloatingActionButton(
                    heroTag: 'mic',
                    backgroundColor: Colors.blueGrey,
                    onPressed: _toggleMute,
                    child: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  ),

                  const SizedBox(width: 20),

                  // Camera toggle button
                  FloatingActionButton(
                    heroTag: 'camera',
                    backgroundColor: Colors.blueGrey,
                    onPressed: _toggleCamera,
                    child: Icon(_isCameraOff
                        ? Icons.videocam_off
                        : Icons.videocam),
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

  Future<void> _toggleCamera() async {
    await _rtcService.toggleCamera();
    setState(() => _isCameraOff = !_isCameraOff);
  }

  @override
  void dispose() {
    SignalRTCService.onCallAccepted = null;
    SignalRTCService.onCallRejected = null;
    SignalRTCService.onCallEnded = null;
    SignalRTCService.onIncomingCall = null;
    _rtcService.dispose();
    super.dispose();
  }
}