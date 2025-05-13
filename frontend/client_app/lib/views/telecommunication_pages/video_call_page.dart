import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/telecommunication_services/signaling_service.dart';

class VideoCallPageClient extends StatefulWidget {
  final String peerId; // ID of the vet calling
  final String jwtToken; // JWT token for authentication

  VideoCallPageClient({required this.peerId, required this.jwtToken});

  @override
  _VideoCallPageClientState createState() => _VideoCallPageClientState();
}

class _VideoCallPageClientState extends State<VideoCallPageClient> {
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
    _signaling = SignalingService();
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    _initRenderers();
    _connectAndListen();
  }

  // Initialize video renderers for local and remote streams
  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // Connect to signaling service and listen for offers
  Future<void> _connectAndListen() async {
    await _signaling.connect(widget.jwtToken, 'client_${widget.peerId}');
    _signaling.onCallAccepted = _onCallAccepted;
    _signaling.onCallRejected = _onCallRejected;
    _signaling.onRemoteStream = _onRemoteStream;
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

  // Set the remote stream when received
  void _onRemoteStream(MediaStream stream) {
    setState(() {
      _remoteRenderer.srcObject = stream;
    });
  }

  // Answer the incoming call
  void _acceptCall() {
    setState(() {
      _isCallInProgress = true;
    });
    _signaling.acceptCall(widget.peerId); // just send acceptance
    // No need to call sendAnswer manually — it's handled in _onOffer
  }


  // Reject the call
  void _rejectCall() {
    _signaling.rejectCall(widget.peerId);
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
      appBar: AppBar(title: Text('Incoming Call from Vet')),
      body: _buildVideoView(),
      floatingActionButton: _isCallInProgress
          ? null
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _acceptCall,
            child: Icon(Icons.call),
            backgroundColor: Colors.green,
          ),
          SizedBox(width: 20),
          FloatingActionButton(
            onPressed: _rejectCall,
            child: Icon(Icons.call_end),
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
