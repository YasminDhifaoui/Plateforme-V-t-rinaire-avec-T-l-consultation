import 'dart:async'; // Essential for StreamController

import 'package:flutter_webrtc/flutter_webrtc.dart';

class RTCPeerService {
  // Singleton instance
  static final RTCPeerService _instance = RTCPeerService._internal();
  factory RTCPeerService() => _instance;

  // Private constructor to ensure singleton pattern
  RTCPeerService._internal() {
    // Initialize renderers immediately when the singleton is created
    // They are then disposed and recreated on a per-call basis in initWebRTC
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    _localRenderer!.initialize();
    _remoteRenderer!.initialize();
  }

  // Public renderers for UI access
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  // Private peer connection and stream
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // New: Store the remote user ID here for consistent use
  String? _currentRemoteUserId; // Renamed for clarity

  // --- Callbacks for the UI (e.g., VideoCallScreen) to subscribe to ---
  // These StreamControllers should be long-lived and NOT closed until app shutdown
  final _localStreamController = StreamController<MediaStream>.broadcast();
  Stream<MediaStream> get onLocalStreamAvailable => _localStreamController.stream;

  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  Stream<MediaStream> get onRemoteStreamAvailable => _remoteStreamController.stream;

  final _iceCandidateController = StreamController<RTCIceCandidate>.broadcast();
  Stream<RTCIceCandidate> get onNewIceCandidate => _iceCandidateController.stream;

  final _peerConnectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get onPeerConnectionStateChange => _peerConnectionStateController.stream;
  final _errorController = StreamController<String>.broadcast();
  Stream<String> get onError => _errorController.stream;

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

  // --- Public Getters for UI ---
  RTCVideoRenderer? get localRenderer => _localRenderer;
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
  MediaStream? get localStream => _localStream;

  void setCurrentRemoteUserId(String userId) {
    _currentRemoteUserId = userId;
    print('[RTCPeerService] Current Remote User ID set to: $_currentRemoteUserId');
  }

  // Helper to clean up only WebRTC objects, NOT StreamControllers
  Future<void> _cleanUpPreviousWebRTCObjects() async {
    print('[RTCPeerService] Cleaning up previous WebRTC objects...');

    // Close peer connection
    if (_peerConnection != null) {
      // Unsubscribe existing listeners *before* closing to prevent errors if callbacks fire
      _peerConnection?.onIceCandidate = null;
      _peerConnection?.onTrack = null;
      _peerConnection?.onIceConnectionState = null;
      _peerConnection?.onSignalingState = null;
      _peerConnection?.onConnectionState = null;

      try {
        await _peerConnection!.close();
      } catch (e) {
        print('[RTCPeerService] Error closing peer connection: $e');
      } finally {
        _peerConnection = null;
        print('[RTCPeerService] PeerConnection closed.');
      }
    }

    // Stop and dispose local stream tracks
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (e) {
          print('[RTCPeerService] Error stopping local track: $e');
        }
      });
      try {
        await _localStream!.dispose();
      } catch (e) {
        print('[RTCPeerService] Error disposing local stream: $e');
      } finally {
        _localStream = null;
        print('[RTCPeerService] Local stream disposed.');
      }
    }

    // Importantly, renderers are not fully disposed here, only their srcObjects are cleared
    // and they will be reused or re-initialized in initWebRTC.
    // If you always want new renderers, you would dispose them here.
    if (_localRenderer != null) {
      print('[RTCPeerService] Old localRenderer disposed.');
      await _localRenderer!.dispose(); // Might throw if already disposed by the FlutterWebRTC plugin
      _localRenderer = null; // Clear it after disposing
    }
    if (_remoteRenderer != null) {
      print('[RTCPeerService] Old remoteRenderer disposed.');
      await _remoteRenderer!.dispose(); // Might throw if already disposed
      _remoteRenderer = null; // Clear it after disposing
    }

    // Clear the stored remote user ID
    _currentRemoteUserId = null;

    print('[RTCPeerService] Previous WebRTC objects cleaned up.');
  }

  // Initializes WebRTC for a new call. This should be called when a call starts.
  Future<void> initWebRTC() async {
    print('[RTCPeerService] Initializing WebRTC for a new call...');

    // Always clean up previous WebRTC objects before setting up a new call
    await _cleanUpPreviousWebRTCObjects();

    try {
      // Re-initialize renderers (if they were disposed in cleanup, or if reusing)
      // In this current structure, renderers are initialized once in constructor
      // and only their srcObject is cleared in cleanup. So no re-initialize here.
      // If you changed _cleanUpPreviousCallResources to dispose renderers, uncomment:

      //if (_remoteRenderer == null) {
      //  _remoteRenderer = RTCVideoRenderer();
       // await _remoteRenderer!.initialize();
       // }
      print('[RTCPeerService] Renderers (re)initialized or ready.');

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
      if (_localRenderer == null) {
        _localRenderer = RTCVideoRenderer();

       _localRenderer!.srcObject = _localStream; // Assign local stream to renderer
        await _localRenderer!.initialize();
        if (!_localStreamController.isClosed) {
          _localStreamController.add(_localStream!); // Notify UI about local stream
        }
        print('[RTCPeerService] Local stream set and notified. Video tracks: ${_localStream?.getVideoTracks().length}');
      } else {
        print('[RTCPeerService] WARNING: Local stream is null!');
        if (!_errorController.isClosed) {
          _errorController.add('Failed to get local media stream.');
        }
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
        if (!_iceCandidateController.isClosed) {
          _iceCandidateController.add(candidate); // Notify UI to send candidate via SignalR
        }
      };

      // Set up track handler for remote stream
      _peerConnection?.onTrack = (RTCTrackEvent event) {
        print('[RTCPeerService] onTrack: ${event.track.id}, streams: ${event.streams.length}');
        if (event.streams.isNotEmpty && !_remoteStreamController.isClosed) {
          _remoteRenderer!.srcObject = event.streams[0]; // Set remote stream to renderer
          _remoteStreamController.add(event.streams[0]); // Notify UI about remote stream
          print('[RTCPeerService] Remote stream set and notified.');
        } else {
          print('[RTCPeerService] onTrack received event with empty streams or controller closed.');
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
        if (!_peerConnectionStateController.isClosed) {
          _peerConnectionStateController.add(state); // Notify UI about overall connection state
        }
      };

    } catch (e) {
      print('[RTCPeerService] WebRTC initialization failed: $e');
      if (!_errorController.isClosed) {
        _errorController.add('Failed to initialize WebRTC: $e');
      }
      // Ensure renderers are disposed if init fails and they were newly created
      // If renderers are long-lived (as in current code), only clear srcObject.
      if (_localRenderer != null) _localRenderer!.srcObject = null;
      if (_remoteRenderer != null) _remoteRenderer!.srcObject = null;

      await _cleanUpPreviousWebRTCObjects(); // Clean up any partial setup
      rethrow; // Propagate the error up
    }
  }

  Future<RTCSessionDescription?> createOffer() async {
    if (_peerConnection == null) {
      print('[RTCPeerService] Error: PeerConnection not initialized for createOffer.');
      if (!_errorController.isClosed) {
        _errorController.add('PeerConnection not initialized for offer creation.');
      }
      return null;
    }
    try {
      final offer = await _peerConnection!.createOffer(_offerSdpConstraints);
      await _peerConnection!.setLocalDescription(offer);
      print('[RTCPeerService] Offer created and set as local description.');
      return offer;
    } catch (e) {
      print('[RTCPeerService] Error creating offer: $e');
      if (!_errorController.isClosed) {
        _errorController.add('Error creating offer: $e');
      }
      return null;
    }
  }

  Future<RTCSessionDescription?> createAnswer() async {
    if (_peerConnection == null) {
      print('[RTCPeerService] Error: PeerConnection not initialized for createAnswer.');
      if (!_errorController.isClosed) {
        _errorController.add('PeerConnection not initialized for answer creation.');
      }
      return null;
    }
    try {
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      print('[RTCPeerService] Answer created and set as local description.');
      return answer;
    } catch (e) {
      print('[RTCPeerService] Error creating answer: $e');
      if (!_errorController.isClosed) {
        _errorController.add('Error creating answer: $e');
      }
      return null;
    }
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_peerConnection == null) {
      print('[RTCPeerService] Error: PeerConnection not initialized for setRemoteDescription.');
      if (!_errorController.isClosed) {
        _errorController.add('PeerConnection not initialized to set remote description.');
      }
      return;
    }
    try {
      await _peerConnection!.setRemoteDescription(description);
      print('[RTCPeerService] Remote description (${description.type}) set.');
    } catch (e) {
      print('[RTCPeerService] Error setting remote description: $e');
      if (!_errorController.isClosed) {
        _errorController.add('Error setting remote description: $e');
      }
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) {
      print('[RTCPeerService] Error: PeerConnection not initialized for addIceCandidate.');
      if (!_errorController.isClosed) {
        _errorController.add('PeerConnection not initialized to add ICE candidate.');
      }
      return;
    }
    try {
      await _peerConnection!.addCandidate(candidate);
      // print('[RTCPeerService] ICE candidate added.'); // Often too verbose for production
    } catch (e) {
      print('[RTCPeerService] Error adding ICE candidate: $e');
      // This error might happen if a candidate arrives before SDP negotiation is complete.
      // Often safe to ignore, but log for debugging.
    }
  }

  Future<void> switchCamera() async {
    if (_localStream == null || _localStream!.getVideoTracks().isEmpty) {
      print('[RTCPeerService] No local video stream to switch camera.');
      if (!_errorController.isClosed) {
        _errorController.add('No local video stream to switch camera.');
      }
      return;
    }
    try {
      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
      print('[RTCPeerService] Camera switched.');
    } catch (e) {
      print('[RTCPeerService] Error switching camera: $e');
      if (!_errorController.isClosed) {
        _errorController.add('Error switching camera: $e');
      }
    }
  }

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

  // This dispose method should ONLY be called when the entire application is shutting down
  // or the user explicitly logs out and all WebRTC functionality is no longer needed.
  // It closes the long-lived StreamControllers.
  Future<void> dispose() async {
    print('[RTCPeerService] Disposing RTCPeerService (full shutdown)...');

    // Clean up any active WebRTC objects first
    await _cleanUpPreviousWebRTCObjects();

    // Dispose renderers fully
    if (_localRenderer != null) {
      _localRenderer!.srcObject = null; // Clear association
      await _localRenderer!.dispose();
      _localRenderer = null;
      print('[RTCPeerService] Final localRenderer disposed.');
    }
    if (_remoteRenderer != null) {
      _remoteRenderer!.srcObject = null; // Clear association
      await _remoteRenderer!.dispose();
      _remoteRenderer = null;
      print('[RTCPeerService] Final remoteRenderer disposed.');
    }

    // Close stream controllers only if they are not already closed
    if (!_localStreamController.isClosed) await _localStreamController.close();
    if (!_remoteStreamController.isClosed) await _remoteStreamController.close();
    if (!_iceCandidateController.isClosed) await _iceCandidateController.close();
    if (!_peerConnectionStateController.isClosed) await _peerConnectionStateController.close();
    if (!_errorController.isClosed) await _errorController.close();

    print('[RTCPeerService] RTCPeerService fully disposed (all controllers closed).');
  }
  Future<void> endCurrentCall() async {
    print('[RTCPeerService] Public endCurrentCall called. Triggering WebRTC object cleanup.');
    await _cleanUpPreviousWebRTCObjects(); // This method already exists and does the cleanup
    _currentRemoteUserId = null; // Clear the currentRemoteUserId for a clean slate
    // You might also want to explicitly clear the srcObject of the renderers
    // if you haven't already, although _cleanUpPreviousCallResources should handle the streams.
    // _localRenderer?.srcObject = null;
    // _remoteRenderer?.srcObject = null;
  }
}