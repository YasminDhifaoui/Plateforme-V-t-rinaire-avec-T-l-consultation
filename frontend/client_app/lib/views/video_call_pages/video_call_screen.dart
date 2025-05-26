import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/auth_services/token_service.dart';
import '../../services/video_call_services/rtc_peer_service.dart';
import '../../services/video_call_services/signalr_tc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String targetUserId; // The ID of the user you are calling (if isCaller is true)
  final String? callerUserId; // The ID of the user who called you (if isCaller is false)
  final bool isCaller; // True if this instance initiated the call
  final bool isCallAcceptedImmediately; // True if the callee accepted the call from a dialog

  const VideoCallScreen({
    super.key,
    required this.targetUserId, // This is the ID of the person on the OTHER side of the call
    this.callerUserId, // Only used when `isCaller` is false (for callee receiving call)
    required this.isCaller,
    this.isCallAcceptedImmediately = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCPeerService _rtcService = RTCPeerService(); // Singleton instance
  String? _callStatusMessage;
  bool _isCallActive = false; // Indicates if the WebRTC connection is stable/active
  String? _authToken;

  // State for controls
  bool _isAudioMuted = false;
  bool _isVideoOff = false;

  // Stream subscriptions to manage
  late List<StreamSubscription> _subscriptions;

  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;

  // Track if `_endCallAndPop` has already been called to prevent multiple executions
  bool _isEndingCall = false;

  @override
  void initState() {
    super.initState();
    print('[_VideoCallScreenState] - initState started. isCaller: ${widget.isCaller}, targetId: ${widget.targetUserId}, callerId: ${widget.callerUserId}');

    _subscriptions = []; // Initialize the list of subscriptions

    // Get fresh references from the service's getters
    _localRenderer = _rtcService.localRenderer;
    _remoteRenderer = _rtcService.remoteRenderer;

    // This ensures renderers are initialized, even if RTCPeerService was previously disposed
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
      String remoteUserId = widget.targetUserId;
      print('[VideoCallScreen] Sending ICE candidate to $remoteUserId');
      // Wrap SignalR invokes in try-catch for robustness
      SignalRTCService.sendIceCandidate(remoteUserId, candidate.toMap()).catchError((e) {
        _handleError('Error sending ICE candidate: $e');
      });
    };

    _rtcService.onPeerConnectionStateChange = (state) {
      print('[VideoCallScreen] PeerConnection State: $state');
      if (!mounted) return;

      setState(() {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _isCallActive = true;
          _callStatusMessage = null; // Clear any connecting messages
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _isCallActive = false;
          _callStatusMessage = 'Call Disconnected or Failed';
          // Let SignalR `CallEnded` or `CallRejected` handle the actual pop
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _isCallActive = false;
          _callStatusMessage = 'Call Ended Locally';
          // Let SignalR `CallEnded` or `CallRejected` handle the actual pop
        } else {
          _callStatusMessage = 'Call Status: ${state.name.split('.').last}';
        }
      });
    };

    _rtcService.onError = (message) {
      _handleError('RTCPeerService Error: $message');
    };

    // --- SignalRTCService Stream Listeners ---

    // Callee receives offer from caller
    _subscriptions.add(SignalRTCService.receiveOfferStream.listen((offerData) async {
      print('[VideoCallScreen] Callee - Received Offer from SignalR.');
      if (mounted && !widget.isCaller) {
        try {
          final String offerCallerId = offerData['callerId'];
          if (offerCallerId == widget.targetUserId) {
            await _rtcService.setRemoteDescription(RTCSessionDescription(offerData['offer']['sdp'], offerData['offer']['type']));
            final answer = await _rtcService.createAnswer();
            if (answer != null) {
              print('[VideoCallScreen] Callee - Sending Answer to $offerCallerId.');
              await SignalRTCService.sendAnswer(offerCallerId, answer.toMap());
            }
          } else {
            print('[VideoCallScreen] Callee - Received offer from unexpected caller: $offerCallerId. Expected: ${widget.targetUserId}');
          }
        } catch (e) {
          _handleError('Error processing received offer: $e');
        }
      }
    }, onError: (e) {
      _handleError('SignalRTCService.receiveOfferStream error: $e');
    }));

    // Caller receives answer from callee
    _subscriptions.add(SignalRTCService.receiveAnswerStream.listen((answerData) async {
      print('[VideoCallScreen] Caller - Received Answer from SignalR.');
      if (mounted && widget.isCaller) {
        try {
          await _rtcService.setRemoteDescription(RTCSessionDescription(answerData['sdp'], answerData['type']));
          print('[VideoCallScreen] Caller - Remote description (answer) set.');
          setState(() {
            _isCallActive = true;
            _callStatusMessage = null;
          });
        } catch (e) {
          _handleError('Error processing received answer: $e');
        }
      }
    }, onError: (e) {
      _handleError('SignalRTCService.receiveAnswerStream error: $e');
    }));

    // Both receive ICE candidates
    _subscriptions.add(SignalRTCService.receiveIceCandidateStream.listen((candidateData) async {
      print('[VideoCallScreen] Received ICE Candidate from SignalR.');
      if (mounted) {
        try {
          await _rtcService.addIceCandidate(RTCIceCandidate(
            candidateData['candidate'],
            candidateData['sdpMid'],
            candidateData['sdpMLineIndex'],
          ));
        } catch (e) {
          print('[VideoCallScreen] Error adding ICE candidate (may be harmless or indicates SDP not set): $e');
          // If this is a persistent error, you might want to call _handleError
        }
      }
    }, onError: (e) {
      _handleError('SignalRTCService.receiveIceCandidateStream error: $e');
    }));

    // For the Caller: Callee accepted the call.
    _subscriptions.add(SignalRTCService.callAcceptedStream.listen((acceptedById) async {
      print('[VideoCallScreen] Caller - Received Call Accepted by: $acceptedById.');
      if (mounted && widget.isCaller && acceptedById == widget.targetUserId) {
        setState(() {
          _callStatusMessage = 'Call Accepted. Waiting for connection...';
        });
        print('[VideoCallScreen] Caller is now waiting for callee\'s answer.');
      } else if (mounted && !widget.isCaller && acceptedById == widget.callerUserId) {
        print('[VideoCallScreen] Callee - Received Call Accepted (redundant).');
      }
    }, onError: (e) {
      _handleError('SignalRTCService.callAcceptedStream error: $e');
    }));

    // Both: Call was rejected
    _subscriptions.add(SignalRTCService.callRejectedStream.listen((reason) {
      print('[VideoCallScreen] >>> Received Call Rejected: $reason');
      _handleEndCall('Call Rejected: $reason');
    }, onError: (e) {
      _handleError('SignalRTCService.callRejectedStream error: $e');
    }));

    // Both: Call was ended
    _subscriptions.add(SignalRTCService.callEndedStream.listen((reason) {
      print('[VideoCallScreen] >>> Received Call Ended: $reason');
      _handleEndCall('Call Ended: $reason');
    }, onError: (e) {
      _handleError('SignalRTCService.callEndedStream error: $e');
    }));

    _subscriptions.add(SignalRTCService.incomingCallStream.listen((incomingCallerId) {
      print('[VideoCallScreen] Received unexpected IncomingCall signal for $incomingCallerId. This screen might already be in a call or should not receive this.');
    }, onError: (e) {
      _handleError('SignalRTCService.incomingCallStream error: $e');
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
      print('[_initCallFlow] Permissions granted: $permissionsGranted');
    } catch (e) {
      _handleError('Permission request failed: $e');
      print('[_initCallFlow] ERROR: Permission request failed: $e');
      return;
    }

    if (!permissionsGranted) {
      _handleError('Camera & microphone permissions are required.');
      print('[_initCallFlow] ERROR: Permissions not granted.');
      return;
    }
    if (!mounted) { print('[_initCallFlow] - ABORTING after permissions.'); return; }

    setState(() => _callStatusMessage = 'Connecting to signaling server...');
    try {
      await SignalRTCService.init(_authToken!);
      print('[_initCallFlow] - SignalRTCService.init completed. SignalR state: ${SignalRTCService.connection?.state}');
      if (!mounted) { print('[_initCallFlow] - ABORTING after SignalR init.'); return; }
    } catch (e) {
      _handleError('Failed to connect to signaling server: $e');
      print('[_initCallFlow] - ERROR connecting to signaling server: $e');
      return;
    }

    setState(() => _callStatusMessage = 'Initializing WebRTC...');
    try {
      await _rtcService.initWebRTC();
      print('[_initCallFlow] - WebRTC init completed.');

      if (!mounted) { print('[_initCallFlow] - ABORTING after WebRTC init.'); return; }

      if (widget.isCaller) {
        setState(() => _callStatusMessage = 'Calling ${widget.targetUserId}...');
        try {
          await SignalRTCService.initiateCall(widget.targetUserId);
          print('[_initCallFlow] - SignalRTCService.initiateCall sent. (Caller)');
        } catch (e) {
          _handleError('Failed to send initiateCall signal: $e');
          return;
        }

        final offer = await _rtcService.createOffer();
        print('[_initCallFlow] - RTCPeerService.createOffer completed. Offer is null: ${offer == null}. (Caller)');

        if (offer != null) {
          print('[VideoCallScreen] Caller sending offer to ${widget.targetUserId}');
          try {
            await SignalRTCService.sendOffer(widget.targetUserId, offer.toMap());
            print('[_initCallFlow] - SignalRTCService.sendOffer sent. (Caller)');
          } catch (e) {
            _handleError('Failed to send offer: $e');
            return;
          }
        } else {
          _handleError('Failed to create offer for caller.');
          print('[_initCallFlow] ERROR: Failed to create offer for caller.');
          return;
        }

      } else { // This is the callee
        print('[_initCallFlow] - Callee path. isCallAcceptedImmediately: ${widget.isCallAcceptedImmediately}');
        if (widget.isCallAcceptedImmediately) {
          if (widget.targetUserId.isNotEmpty) {
            try {
              await SignalRTCService.acceptCall(widget.targetUserId);
              setState(() {
                _isCallActive = true;
                _callStatusMessage = 'Call Accepted. Waiting for offer...';
              });
              print('[_initCallFlow] - Callee accepted call via SignalR.');
            } catch (e) {
              _handleError('Failed to send acceptCall signal: $e');
              return;
            }
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
      print('[_initCallFlow] - CATCH ALL ERROR initializing call setup: $e');
      return;
    }

    print('[_initCallFlow] - Call setup flow initiated (end of try block).');
  }

  void _handleError(String message) {
    print('Error: $message');
    if (!mounted) return;
    setState(() {
      _callStatusMessage = 'Error: $message';
      _isCallActive = false; // Mark call as inactive
    });
    // Trigger end call and pop after a short delay to display error message
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _endCallAndPop();
      }
    });
  }

  // Unified method to handle call termination (due to rejection, end, or local hangup)
  void _handleEndCall(String message) {
    print('[_VideoCallScreenState] _handleEndCall called. Message: $message');
    if (!mounted) return;
    setState(() {
      _callStatusMessage = message;
      _isCallActive = false;
    });
    // Give a brief moment for the user to read the message before popping
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _endCallAndPop(); // Centralized cleanup and pop
      }
    });
  }

  // New centralized method for cleanup and popping the screen
  Future<void> _endCallAndPop() async {
    if (_isEndingCall) {
      print('[_VideoCallScreenState] _endCallAndPop already in progress. Skipping.');
      return;
    }
    _isEndingCall = true;

    print('[_VideoCallScreenState] _endCallAndPop called. Initiating cleanup and pop.');

    if (!mounted) {
      print('[_VideoCallScreenState] Not mounted, skipping cleanup and pop.');
      _isEndingCall = false;
      return;
    }

    String? otherUserId = widget.targetUserId;
    if (otherUserId.isNotEmpty) {
      print('[_VideoCallScreenState] Attempting to send endCall signal to $otherUserId.');
      try {
        await SignalRTCService.endCall(otherUserId: otherUserId);
        print('[_VideoCallScreenState] endCall signal sent successfully.');
      } catch (e) {
        print('[_VideoCallScreenState] WARNING: Failed to send endCall signal: $e');
      }
    } else {
      print('[_VideoCallScreenState] No otherUserId found, skipping endCall signal.');
    }

    for (var subscription in _subscriptions) {
      try {
        await subscription.cancel();
      } catch (e) {
        print('[_VideoCallScreenState] Error canceling subscription: $e');
      }
    }
    _subscriptions.clear();
    print('[_VideoCallScreenState] All stream subscriptions canceled.');

    await _rtcService.dispose();
    print('[_VideoCallScreenState] RTCPeerService disposed.');

    // This ensures SignalR connection is stopped when the call screen is no longer needed.
    // This is vital for the caller's connection to not drop unexpectedly by other means.
    await SignalRTCService.disconnect();
    print('[_VideoCallScreenState] SignalRTCService disconnected.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        print('[_VideoCallScreenState] Popping screen.');
        Navigator.of(context).pop();
      } else if (mounted) {
        print('[_VideoCallScreenState] Cannot pop, but mounted. Possibly root route or pushReplacement was used earlier.');
      } else {
        print('[_VideoCallScreenState] Not mounted, cannot pop.');
      }
      _isEndingCall = false;
    });
    print('[_VideoCallScreenState] _endCallAndPop completed.');
  }

  void _toggleAudio() {
    _rtcService.toggleAudioMute();
    if (mounted) setState(() => _isAudioMuted = !_isAudioMuted);
  }

  void _toggleVideo() {
    _rtcService.toggleVideoEnabled();
    if (mounted) setState(() => _isVideoOff = !_isVideoOff);
  }

  @override
  void dispose() {
    print('[_VideoCallScreenState] dispose() called.');
    // Ideally, _endCallAndPop handles all cleanup. This dispose is mainly for Flutter's lifecycle.
    // It's crucial that `_endCallAndPop` is called *before* `dispose` in response to any call-ending event.
    // Your `onWillPop`, `_handleError`, and stream listeners for `CallEnded`/`CallRejected` ensure this.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print('[_VideoCallScreenState] onWillPop called. Handling call end.');
        _handleEndCall('User pressed back button.');
        return false;
      },
      child: Scaffold(
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
                    _isCallActive ? 'Waiting for remote video...' : (_callStatusMessage ?? 'Connecting...'),
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
                    onPressed: () => _handleEndCall('User hung up.'),
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
      ),
    );
  }
}