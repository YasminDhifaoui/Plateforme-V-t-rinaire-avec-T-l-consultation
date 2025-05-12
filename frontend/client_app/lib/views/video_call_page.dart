import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signaling_service.dart';

class VideoPage extends StatefulWidget {
  final String jwtToken;
  final String userId;
  final String peerId;

  const VideoPage({required this.jwtToken, required this.userId, required this.peerId});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final SignalingService _signaling = SignalingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Connect to signaling server
    await _signaling.connect(widget.jwtToken, widget.userId);

    // Set local media stream
    _localRenderer.srcObject = _signaling.getLocalStream();

    // Set up peer connection and listen for incoming streams
    await _signaling.setupPeerConnection(widget.peerId);

    // Listen for remote stream after connection setup
    _signaling.peer.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});  // Trigger UI update when the remote stream is added
    };
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _signaling.dispose();  // Clean up the signaling service (close peer connection)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Call')),
      body: Column(
        children: [
          // Local video stream (mirror the video for local view)
          Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
          // Remote video stream
          Expanded(child: RTCVideoView(_remoteRenderer)),
          ElevatedButton(
            onPressed: () => _signaling.sendOffer(widget.peerId),
            child: Text('Call'),
          )
        ],
      ),
    );
  }
}
