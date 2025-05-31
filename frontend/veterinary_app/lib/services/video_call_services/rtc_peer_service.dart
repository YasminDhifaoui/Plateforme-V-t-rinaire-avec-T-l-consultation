import 'package:flutter_webrtc/flutter_webrtc.dart';

class RTCPeerService {
  // Singleton instance
  static final RTCPeerService _instance = RTCPeerService._internal();
  factory RTCPeerService() => _instance;
  RTCPeerService._internal();

  // Public renderers for UI access
  // These are initialized once and then re-initialized/reset their state
  // rather than being replaced with new instances.
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Private peer connection and stream
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // Flag to prevent RTCPeerService's own dispose from running multiple times
  // This flag is still useful for the service's own lifecycle
  bool _isDisposed = false;

  // Configuration for WebRTC
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // Add your TURN servers here if needed for robust NAT traversal
      // {'urls': 'turn:YOUR_TURN_SERVER_URL', 'username': 'user', 'credential': 'password'},
    ]
  };

  final Map<String, dynamic> _offerSdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  // --- Callbacks for the UI (e.g., VideoCallScreen) to subscribe to ---
  Function(MediaStream)? onLocalStreamAvailable;
  Function(MediaStream)? onRemoteStreamAvailable;
  Function(RTCIceCandidate)? onNewIceCandidate;
  Function(RTCPeerConnectionState)? onPeerConnectionStateChange;
  Function(String)? onError; // General error callback

  Future<void> initRenderers() async {
    print('[RTCPeerService] Initializing/re-initializing renderers.');

    // Dispose previous streams from renderers if they exist
    if (localRenderer.srcObject != null) {
      localRenderer.srcObject = null;
    }
    if (remoteRenderer.srcObject != null) {
      remoteRenderer.srcObject = null;
    }


    await localRenderer.initialize();
    await remoteRenderer.initialize();
    print('[RTCPeerService] Renderers initialized.');
  }

  Future<void> initWebRTC() async {
    print('[RTCPeerService] Initializing WebRTC...');
    try {
      await initRenderers();  if (_peerConnection != null) {
        if (_peerConnection!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          print('[RTCPeerService] Closing existing peer connection...');
          await _peerConnection!.close();
        }
        _peerConnection = null; // Clear reference for new creation
      }

      _isDisposed = false; // Reset disposition flag for a new call session

      // Get local media stream (camera and microphone)
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '15',
          },
          'optional': [
            {'maxWidth': '1280'},
            {'maxHeight': '720'},
            {'maxFrameRate': '30'},
          ],
        },
      });

      print('[RTCPeerService] Got local stream. Video tracks: ${_localStream?.getVideoTracks().length}');
      if (_localStream != null) {
        localRenderer.srcObject = _localStream; // Assign local stream to renderer
        onLocalStreamAvailable?.call(_localStream!); // Notify UI about local stream
        print('[RTCPeerService] Local stream set and notified.');
      } else {
        print('[RTCPeerService] WARNING: Local stream is null!');
        onError?.call('Failed to get local media stream.');
        throw Exception('Local stream is null');
      }

      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration);
      print('[RTCPeerService] PeerConnection created.');

      // Add local stream tracks to peer connection
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
        print('[RTCPeerService] Added local track: ${track.id} (${track.kind})');
      });

      // Set up ICE candidate handler
      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        print('[RTCPeerService] onIceCandidate: ${candidate.candidate}');
        onNewIceCandidate?.call(candidate); // Notify UI to send candidate via SignalR
      };

      // Set up track handler for remote stream
      _peerConnection?.onTrack = (RTCTrackEvent event) {
        print('[RTCPeerService] onTrack: ${event.track.id}, streams: ${event.streams.length}');
        // Check if stream is actually new or changed before re-assigning
        if (event.streams.isNotEmpty && remoteRenderer.srcObject?.id != event.streams[0].id) {
          remoteRenderer.srcObject = event.streams[0];
          onRemoteStreamAvailable?.call(event.streams[0]); // Notify UI about remote stream
          print('[RTCPeerService] Remote stream set and notified.');
        } else if (event.streams.isEmpty) {
          print('[RTCPeerService] onTrack received event with empty streams.');
        }
      };

      // Handle connection state changes
      _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
        print('[RTCPeerService] ICE connection state: $state');
      };
      _peerConnection?.onSignalingState = (state) {
        print('[RTCPeerService] Signaling state: $state');
      };
      _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
        print('[RTCPeerService] PeerConnection state: $state');
        onPeerConnectionStateChange?.call(state); // Notify UI about overall connection state
      };

    } catch (e) {
      print('WebRTC initialization failed: $e');
      onError?.call('Failed to initialize WebRTC: $e');
      rethrow;
    }
  }

  Future<RTCSessionDescription?> createOffer() async {
    if (_peerConnection == null) {
      print('[RTCPeerService] Error: PeerConnection not initialized for createOffer.');
      onError?.call('PeerConnection not initialized for offer creation.');
      return null;
    }
    try {
      final offer = await _peerConnection!.createOffer(_offerSdpConstraints);
      await _peerConnection!.setLocalDescription(offer);
      print('[RTCPeerService] Offer created and set as local description.');
      return offer;
    } catch (e) {
      print('[RTCPeerService] Error creating offer: $e');
      onError?.call('Error creating offer: $e');
      return null;
    }
  }

  Future<RTCSessionDescription?> createAnswer() async {
    if (_peerConnection == null) {
      print('[RTCPeerService] Error: PeerConnection not initialized for createAnswer.');
      onError?.call('PeerConnection not initialized for answer creation.');
      return null;
    }
    try {
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      print('[RTCPeerService] Answer created and set as local description.');
      return answer;
    } catch (e) {
      print('[RTCPeerService] Error creating answer: $e');
      onError?.call('Error creating answer: $e');
      return null;
    }
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_peerConnection == null) {
      print('[RTCPeerService] Error: PeerConnection not initialized for setRemoteDescription.');
      onError?.call('PeerConnection not initialized to set remote description.');
      return;
    }
    try {
      await _peerConnection!.setRemoteDescription(description);
      print('[RTCPeerService] Remote description (${description.type}) set.');
    } catch (e) {
      print('[RTCPeerService] Error setting remote description: $e');
      onError?.call('Error setting remote description: $e');
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) {
      print('[RTCPeerService] Error: PeerConnection not initialized for addIceCandidate.');
      onError?.call('PeerConnection not initialized to add ICE candidate.');
      return;
    }
    try {
      await _peerConnection!.addCandidate(candidate);
      print('[RTCPeerService] ICE candidate added.');
    } catch (e) {
      print('[RTCPeerService] Error adding ICE candidate: $e');
      // This error might happen if a candidate arrives before SDP negotiation is complete.
      // Often safe to ignore or log for debugging.
    }
  }

  Future<void> switchCamera() async {
    if (_localStream == null || _localStream!.getVideoTracks().isEmpty) {
      print('[RTCPeerService] No local video stream to switch camera.');
      onError?.call('No local video stream to switch camera.');
      return;
    }
    try {
      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
      print('[RTCPeerService] Camera switched.');
    } catch (e) {
      print('[RTCPeerService] Error switching camera: $e');
      onError?.call('Error switching camera: $e');
    }
  }

  // These methods now control the state of the media tracks directly
  void toggleAudioMute() {
    final audioTracks = _localStream?.getAudioTracks();
    if (audioTracks != null && audioTracks.isNotEmpty) {
      audioTracks[0].enabled = !audioTracks[0].enabled; // Toggle the enabled state
      print('[RTCPeerService] Audio track enabled: ${audioTracks[0].enabled}');
    }
  }

  void toggleVideoEnabled() {
    final videoTracks = _localStream?.getVideoTracks();
    if (videoTracks != null && videoTracks.isNotEmpty) {
      videoTracks[0].enabled = !videoTracks[0].enabled; // Toggle the enabled state
      print('[RTCPeerService] Video track enabled: ${videoTracks[0].enabled}');
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      print('[RTCPeerService] Already disposed. Skipping.');
      return;
    }
    _isDisposed = true; // Set flag immediately

    print('[RTCPeerService] Disposing RTCPeerService resources...');

    // Close peer connection
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
      print('[RTCPeerService] PeerConnection closed.');
    }

    // Stop and dispose local stream tracks
    _localStream?.getTracks().forEach((track) {
      track.stop(); // Stop the track
      print('[RTCPeerService] Local stream track stopped: ${track.id}');
    });
    if (_localStream != null) {
      await _localStream!.dispose(); // Dispose the stream itself
      _localStream = null;
      print('[RTCPeerService] Local stream disposed.');
    }

    // Unassign srcObject from renderers before disposing them
    // This is crucial to avoid "Can't set srcObject: The RTCVideoRenderer is disposed"
    if (localRenderer.srcObject != null) {
      localRenderer.srcObject = null;
    }
    if (remoteRenderer.srcObject != null) {
      remoteRenderer.srcObject = null;
    }

    // Dispose the renderers
    // It's safe to dispose even if srcObject is null, or it's already disposed.
    // The key is that `initialize()` will re-enable them for the next call.
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    print('[RTCPeerService] Renderers disposed.');

    // Clear callbacks to prevent memory leaks or calling on stale widgets
    onLocalStreamAvailable = null;
    onRemoteStreamAvailable = null;
    onNewIceCandidate = null;
    onPeerConnectionStateChange = null;
    onError = null;
    print('[RTCPeerService] All RTCPeerService callbacks cleared.');

    print('[RTCPeerService] RTCPeerService resources cleaned up.');
  }
}