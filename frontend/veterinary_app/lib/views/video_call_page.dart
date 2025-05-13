import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signaling_service.dart';

class VideoCallPageVet extends StatefulWidget {
  final String peerId; // ID of the client the vet is calling
  final String jwtToken; // JWT token for authentication

  VideoCallPageVet({required this.peerId, required this.jwtToken});

  @override
  _VideoCallPageVetState createState() => _VideoCallPageVetState();
}

class _VideoCallPageVetState extends State<VideoCallPageVet> {
  late SignalingService _signaling;
  bool _isCallInProgress = false;
  bool _isCallAccepted = false;
  bool _isCallRejected = false;
  late MediaStream _localStream;
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;

  @override
  void initState() {
    super.initState();
    //_signaling = SignalingService();
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    _initRenderers();
    _connectAndCall();
  }

  // Initialize video renderers for local and remote streams
  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // Connect to the signaling service and initiate the call
  Future<void> _connectAndCall() async {
    await _signaling.connect(widget.jwtToken, 'vet_${widget.peerId}');
    _signaling.onCallAccepted = _onCallAccepted;
    _signaling.onCallRejected = _onCallRejected;

    // Send the call offer to the client
    await _signaling.sendOffer(widget.peerId);
    setState(() {
      _isCallInProgress = true;
    });
  }

  // Handle the acceptance of the call
  void _onCallAccepted() {
    setState(() {
      _isCallAccepted = true;
    });
  }

  // Handle call rejection
  void _onCallRejected() {
    setState(() {
      _isCallRejected = true;
    });
  }

  // Render the local and remote video streams
  Widget _buildVideoView() {
    if (_isCallRejected) {
      return Center(child: Text('Call Rejected'));
    }

    if (_isCallInProgress) {
      return Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(_remoteRenderer),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: RTCVideoView(_localRenderer),
          ),
        ],
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }

  @override
  void dispose() {
    _signaling.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Call with Client')),
      body: _buildVideoView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isCallInProgress ? () => _signaling.rejectCall(widget.peerId) : null,
        child: Icon(Icons.call_end),
        backgroundColor: Colors.red,
      ),
    );
  }
}
