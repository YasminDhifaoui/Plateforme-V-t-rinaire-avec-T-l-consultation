import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/services/video_call_services/rtc_peer_service.dart';
import 'package:veterinary_app/services/video_call_services/signalr_tc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String targetUserId; // The ID of the user you are calling (if isCaller is true)
  final String? callerUserId; // The ID of the user who called you (if isCaller is false)
  final bool isCaller; // True if this instance initiated the call
  final bool isCallAcceptedImmediately; // True if the callee accepted the call from a dialog

  const VideoCallScreen({
    super.key,
    required this.targetUserId,
    this.callerUserId,
    required this.isCaller,
    this.isCallAcceptedImmediately = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCPeerService _rtcService = RTCPeerService(); // Singleton instance
  String? _callStatusMessage;
  bool _isCallActive = false;
  String? _authToken;
  bool _isDisposed = false; // Flag to prevent multiple dispose calls

  // State for controls
  bool _isAudioMuted = false;
  bool _isVideoOff = false;

  // Stream subscriptions to manage
  late List<StreamSubscription> _subscriptions;

  @override
  void initState() {
    super.initState();
    print('[_VideoCallScreenState] - initState started.');
    _localRenderer = _rtcService.localRenderer;
    _remoteRenderer = _rtcService.remoteRenderer;
    _subscriptions = []; // Initialize the list

    _rtcService.initRenderers().catchError((e) {
      _handleError('Failed to initialize renderers: $e');
    });

    _retrieveAuthTokenAndInitCall();
  }

  Future<void> _retrieveAuthTokenAndInitCall() async {
    print('[_VideoCallScreenState] - Retrieving auth token...');
    _authToken = await TokenService.getToken();

    if (_authToken == null) {
      _handleError('Authentication token not found. Cannot establish call.');
      if (mounted) Navigator.of(context).pop();
      return;
    }

    _setupServiceCallbacksAndListeners();
    _initCallFlow();
  }

  void _setupServiceCallbacksAndListeners() {
    // --- RTCPeerService Callbacks ---
    _rtcService.onLocalStreamAvailable = (stream) {
      if (mounted) setState(() {}); // Trigger rebuild to update RTCVideoView
      print('[VideoCallScreen] Local stream available.');
    };

    _rtcService.onRemoteStreamAvailable = (stream) {
      if (mounted) setState(() {}); // Trigger rebuild to update RTCVideoView
      print('[VideoCallScreen] Remote stream available.');
    };

    _rtcService.onNewIceCandidate = (candidate) {
      String? remoteUserId = widget.isCaller ? SignalRTCService.targetUserId : SignalRTCService.callerUserId;
      if (remoteUserId != null) {
        SignalRTCService.sendIceCandidate(remoteUserId, candidate.toMap());
      } else {
        print('[VideoCallScreen] No remote user ID to send ICE candidate.');
      }
    };

    _rtcService.onPeerConnectionStateChange = (state) {
      print('[VideoCallScreen] PeerConnection State: $state');
      if (!mounted || _isDisposed) return;
      setState(() {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _isCallActive = true;
          _callStatusMessage = 'Call Connected';
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _isCallActive = false;
          _callStatusMessage = 'Call Disconnected';
          _showAlertDialog('Call Disconnected', 'The call connection was lost unexpectedly.').then((_) {
            _cleanupAndPop();
          });
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _isCallActive = false;
          _callStatusMessage = 'Call Ended';
          // No alert here, _cleanupAndPop will handle navigation
          _cleanupAndPop();
        }
      });
    };

    _rtcService.onError = (message) {
      _handleError('RTCPeerService Error: $message');
    };

    // --- SignalRTCService Stream Listeners ---
    _subscriptions.add(SignalRTCService.receiveOfferStream.listen((offerData) async {
      print('[VideoCallScreen] Received Offer from SignalR.');
      try {
        await _rtcService.setRemoteDescription(RTCSessionDescription(offerData['sdp'], offerData['type']));
        final answer = await _rtcService.createAnswer();
        if (answer != null && SignalRTCService.callerUserId != null) {
          await SignalRTCService.sendAnswer(SignalRTCService.callerUserId!, answer.toMap());
        }
      } catch (e) {
        _handleError('Error processing received offer: $e');
      }
    }));

    _subscriptions.add(SignalRTCService.receiveAnswerStream.listen((answerData) async {
      print('[VideoCallScreen] Received Answer from SignalR.');
      try {
        await _rtcService.setRemoteDescription(RTCSessionDescription(answerData['sdp'], answerData['type']));
      } catch (e) {
        _handleError('Error processing received answer: $e');
      }
    }));

    _subscriptions.add(SignalRTCService.receiveIceCandidateStream.listen((candidateData) async {
      print('[VideoCallScreen] Received ICE Candidate from SignalR.');
      try {
        await _rtcService.addIceCandidate(RTCIceCandidate(
          candidateData['candidate'],
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        ));
      } catch (e) {
        print('[VideoCallScreen] Error adding ICE candidate: $e');
        // This error often occurs if candidate arrives before SDP. Can usually be safely ignored.
      }
    }));

    _subscriptions.add(SignalRTCService.callAcceptedStream.listen((acceptedById) async {
      print('[VideoCallScreen] Call Accepted by: $acceptedById. Starting offer/answer flow.');
      if (!mounted || _isDisposed) return;
      setState(() {
        _isCallActive = true;
        _callStatusMessage = 'Call Connected';
      });
      // If this is the caller, now send the offer
      if (widget.isCaller && SignalRTCService.targetUserId != null) {
        try {
          final offer = await _rtcService.createOffer();
          if (offer != null) {
            await SignalRTCService.sendOffer(SignalRTCService.targetUserId!, offer.toMap());
          }
        } catch (e) {
          _handleError('Failed to create or send offer after acceptance: $e');
        }
      }
    }));

    _subscriptions.add(SignalRTCService.callRejectedStream.listen((reason) {
      _handleEndCall('Call Rejected: $reason');
    }));

    _subscriptions.add(SignalRTCService.callEndedStream.listen((reason) {
      _handleEndCall('Call Ended: $reason');
    }));

    // The incoming call stream should ideally be handled by HomePage,
    // but adding it here for completeness if this screen could receive new incoming calls
    // while already open (less common for a dedicated call screen).
    _subscriptions.add(SignalRTCService.incomingCallStream.listen((incomingCallerId) {
      print('[VideoCallScreen] Received unexpected IncomingCall signal for $incomingCallerId. This screen might already be in a call or should not receive this.');
    }));
  }

  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    return cameraStatus.isGranted && microphoneStatus.isGranted;
  }

  Future<void> _initCallFlow() async {
    print('[_initCallFlow] - START.');
    if (!mounted || _authToken == null) {
      print('[_initCallFlow] - ABORTING: Not mounted or auth token missing.');
      return;
    }

    setState(() => _callStatusMessage = 'Requesting permissions...');
    bool permissionsGranted = false;
    try {
      permissionsGranted = await _requestPermissions();
    } catch (e) {
      _handleError('Permission request failed: $e');
      return;
    }

    if (!permissionsGranted) {
      _handleError('Camera & microphone permissions are required.');
      return;
    }
    if (!mounted || _isDisposed) { print('[_initCallFlow] - ABORTING after permissions.'); return; }

    setState(() => _callStatusMessage = 'Connecting to signaling server...');
    try {
      await SignalRTCService.init(_authToken!);
      print('[_initCallFlow] - SignalRTCService.init completed.');
      if (!mounted || _isDisposed) { print('[_initCallFlow] - ABORTING after SignalR init.'); return; }
    } catch (e) {
      _handleError('Failed to connect to signaling server: $e');
      print('[_initCallFlow] - ERROR connecting to signaling server: $e');
      return;
    }

    setState(() => _callStatusMessage = 'Initializing WebRTC...');
    try {
      await _rtcService.initWebRTC(); // No need for isCaller here, RTCPeerService just sets up media
      print('[_initCallFlow] - WebRTC init completed.');

      if (!mounted || _isDisposed) { print('[_initCallFlow] - ABORTING after WebRTC init.'); return; }

      if (widget.isCaller) {
        setState(() => _callStatusMessage = 'Calling ${widget.targetUserId}...');
        await SignalRTCService.initiateCall(widget.targetUserId);
        print('[_initCallFlow] - SignalRTCService.initiateCall sent.');
      } else {
        print('[_initCallFlow] - Callee path. isCallAcceptedImmediately: ${widget.isCallAcceptedImmediately}');
        if (widget.isCallAcceptedImmediately) {
          // This path is taken when HomePage accepts the call and navigates here.
          // The `callerUserId` for SignalRTCService should have been set by the `IncomingCall` handler
          // and used by HomePage to call `SignalRTCService.acceptCall`.
          // We just need to ensure the remote offer is handled correctly by SignalRTCService.
          if (SignalRTCService.callerUserId != null) {
            await SignalRTCService.acceptCall(SignalRTCService.callerUserId!);
            setState(() {
              _isCallActive = true;
              _callStatusMessage = null; // Clear status as call is accepted
            });
            print('[_initCallFlow] - Callee accepted call via SignalR.');
          } else {
            _handleError("Cannot accept call: Caller ID not established for callee.");
            return;
          }
        } else {
          _handleError("Invalid call state for receiver. Call not accepted or unknown state.");
          return;
        }
      }
    } catch (e) {
      _handleError('Failed to initialize call setup: $e');
      print('[_initCallFlow] - ERROR initializing call setup: $e');
      return;
    }

    if (mounted && _callStatusMessage != null) {
      // If we reach here and still have a status message, clear it (e.g., if a connection was established)
      setState(() => _callStatusMessage = null);
      print('[_initCallFlow] - Call setup completed.');
    }
  }

  void _handleError(String message) {
    print('Error: $message');
    if (!mounted || _isDisposed) return;
    setState(() {
      _callStatusMessage = 'Error: $message';
      _isCallActive = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDisposed) {
        _cleanupAndPop(); // Clean up and pop on error
      }
    });
  }

  void _handleEndCall(String message) {
    print('Call Ended: $message');
    if (!mounted || _isDisposed) return;
    setState(() {
      _callStatusMessage = message;
      _isCallActive = false;
    });

    _cleanupAndPop(); // Centralized cleanup

    // Optionally, give a brief moment for the user to read the message before popping
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isDisposed) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _cleanupAndPop() async {
    if (_isDisposed) {
      print('[_VideoCallScreenState] Resources already disposed. Skipping.');
      return;
    }
    _isDisposed = true; // Set flag immediately

    print('[_VideoCallScreenState] Performing cleanup and popping screen.');

    // Cancel all active stream subscriptions
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    print('[_VideoCallScreenState] All stream subscriptions canceled.');

    // Inform the other user the call is ending (if a remote ID is known)
    String? otherUserId = widget.isCaller ? SignalRTCService.targetUserId : SignalRTCService.callerUserId;
    if (otherUserId != null) {
      await SignalRTCService.endCall(otherUserId: otherUserId);
    }

    await _rtcService.dispose(); // Dispose RTCPeerService
    // SignalRTCService.disconnect() is handled by _initCallFlow or global app lifecycle

    if (mounted) {
      // Ensure we don't pop twice if Navigator handles it (e.g. back button)
      // This is often called when the screen is already off the stack.
      // Check if the screen is still visible before popping.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
    print('[_VideoCallScreenState] Cleanup and pop complete.');
  }

  Future<void> _showAlertDialog(String title, String message) async {
    if (!mounted || _isDisposed) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleAudio() {
    _rtcService.toggleAudioMute();
    if (mounted) setState(() => _isAudioMuted = !_isAudioMuted);
  }

  void _toggleVideo() {
    _rtcService.toggleVideoEnabled();
    if (mounted) setState(() => _isVideoOff = !_isVideoOff);
  }

  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;

  @override
  void dispose() {
    print('[_VideoCallScreenState] dispose() called. Initiating final cleanup.');
    // Ensure cleanup happens if widget is removed from tree by system or back button
    _cleanupAndPop(); // Call the centralized cleanup method
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video (full screen)
          Positioned.fill(
            child: _remoteRenderer.srcObject != null
                ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                : Container(
              color: Colors.black,
              child: Center(
                child: Text(
                  _isCallActive ? 'Waiting for remote video...' : (_callStatusMessage ?? ''),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Local Video (small, top-right corner)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            width: 120,
            height: 160,
            child: _localRenderer.srcObject != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RTCVideoView(_localRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: true),
            )
                : Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isVideoOff ? const Icon(Icons.videocam_off, color: Colors.white) : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
          // Status Message overlay
          if (_callStatusMessage != null && !_isCallActive)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _callStatusMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Control Buttons
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'muteBtn',
                  onPressed: _toggleAudio,
                  backgroundColor: _isAudioMuted ? Colors.red : Colors.blueGrey,
                  child: Icon(_isAudioMuted ? Icons.mic_off : Icons.mic),
                ),
                FloatingActionButton(
                  heroTag: 'hangupBtn',
                  onPressed: _cleanupAndPop, // Hang up button
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.call_end),
                ),
                FloatingActionButton(
                  heroTag: 'cameraBtn',
                  onPressed: _toggleVideo,
                  backgroundColor: _isVideoOff ? Colors.red : Colors.blueGrey,
                  child: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam),
                ),
                FloatingActionButton(
                  heroTag: 'switchCameraBtn',
                  onPressed: _rtcService.switchCamera,
                  backgroundColor: Colors.blueGrey,
                  child: const Icon(Icons.switch_camera),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}