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
  // bool _isDisposed = false; // REMOVE THIS FLAG - it's causing issues.
  // We will rely on mounted check and a single dispose trigger.

  // State for controls
  bool _isAudioMuted = false;
  bool _isVideoOff = false;

  // Stream subscriptions to manage
  late List<StreamSubscription> _subscriptions; // Corrected: Now initialized in initState

  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;

  @override
  void initState() {
    super.initState();
    print('[_VideoCallScreenState] - initState started.');

    // --- FIX IS HERE ---
    _subscriptions = []; // Initialize the list of subscriptions
    // --- END FIX ---

    // IMPORTANT: Get fresh references from the service's getters each time
    _localRenderer = _rtcService.localRenderer;
    _remoteRenderer = _rtcService.remoteRenderer;

    // This call is now a no-op in RTCPeerService, but harmless to keep
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
      if (!mounted) return; // Only update if still mounted
      setState(() {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _isCallActive = true;
          _callStatusMessage = 'Call Connected';
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _isCallActive = false;
          _callStatusMessage = 'Call Disconnected';
          _endCallAndPop(); // Centralized cleanup after showing alert

        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _isCallActive = false;
          _callStatusMessage = 'Call Ended';
          _endCallAndPop(); // Centralized cleanup
        }
      });
    };

    _rtcService.onError = (message) {
      _handleError('RTCPeerService Error: $message');
    };

// In video_call_screen.dart, inside _setupServiceCallbacksAndListeners()

    _subscriptions.add(SignalRTCService.receiveOfferStream.listen((arguments) async { // Changed offerData to arguments
      print('[VideoCallScreen] SignalRTCService.receiveOfferStream: Received Offer from SignalR. Arguments: $arguments');
      // arguments[0] will be the callerId, arguments[1] will be the offer map
      if (arguments.length < 2 || !(arguments[1] is Map<dynamic, dynamic>)) {
        print('[VideoCallScreen] ERROR: ReceiveOffer arguments unexpected format: $arguments');
        _handleError('Received malformed offer data.');
        return;
      }
      final String remoteCallerId = arguments[0]; // Extract the callerId
      final Map<String, dynamic> offerData = Map<String, dynamic>.from(arguments[1]); // Extract the offer map

      // IMPORTANT: Set SignalRTCService.callerUserId on the callee side
      // This is crucial for sending the answer back to the correct caller.
      if (!widget.isCaller) { // Only set this if this instance is the callee
        SignalRTCService.callerUserId = remoteCallerId;
        print('[VideoCallScreen] Callee: Set SignalRTCService.callerUserId to $remoteCallerId');
      }

      try {
        await _rtcService.setRemoteDescription(RTCSessionDescription(offerData['sdp'], offerData['type']));
        print('[VideoCallScreen] Remote Description (Offer) set. Creating Answer...');
        final answer = await _rtcService.createAnswer();
        if (answer != null && SignalRTCService.callerUserId != null) {
          await SignalRTCService.sendAnswer(SignalRTCService.callerUserId!, answer.toMap());
          print('[VideoCallScreen] Answer sent to ${SignalRTCService.callerUserId}.');
        } else {
          print('[VideoCallScreen] ERROR: Answer is null or SignalRTCService.callerUserId is null. Cannot send answer.');
        }
      } catch (e) {
        _handleError('Error processing received offer: $e');
        print('[VideoCallScreen] SignalRTCService.receiveOfferStream: EXCEPTION: $e');
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
      if (!mounted) return;
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
    if (!mounted) { print('[_initCallFlow] - ABORTING after permissions.'); return; }

    setState(() => _callStatusMessage = 'Connecting to signaling server...');
    try {
      await SignalRTCService.init(_authToken!);
      print('[_initCallFlow] - SignalRTCService.init completed.');
      if (!mounted) { print('[_initCallFlow] - ABORTING after SignalR init.'); return; }
    } catch (e) {
      _handleError('Failed to connect to signaling server: $e');
      print('[_initCallFlow] - ERROR connecting to signaling server: $e');
      return;
    }

    setState(() => _callStatusMessage = 'Initializing WebRTC...');
    try {
      await _rtcService.initWebRTC(); // No need for isCaller here, RTCPeerService just sets up media
      print('[_initCallFlow] - WebRTC init completed.');

      if (!mounted) { print('[_initCallFlow] - ABORTING after WebRTC init.'); return; }

      if (widget.isCaller) {
        setState(() => _callStatusMessage = 'Calling ${widget.targetUserId}...');
        await SignalRTCService.initiateCall(widget.targetUserId);
        print('[_initCallFlow] - SignalRTCService.initiateCall sent.');
      } else {
        print('[_initCallFlow] - Callee path. isCallAcceptedImmediately: ${widget.isCallAcceptedImmediately}');
        if (widget.isCallAcceptedImmediately) {

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
    if (!mounted) return;
    setState(() {
      _callStatusMessage = 'Error: $message';
      _isCallActive = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _endCallAndPop(); // Centralized cleanup after showing alert
      }
    });
  }

  void _handleEndCall(String message) {
    print('Call Ended: $message');
    if (!mounted) return;
    setState(() {
      _callStatusMessage = message;
      _isCallActive = false;
    });
    // Give a brief moment for the user to read the message before popping
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _endCallAndPop(); // Centralized cleanup after showing alert
      }
    });
  }

  // New centralized method for cleanup and popping the screen
  Future<void> _endCallAndPop() async {
    print('[_VideoCallScreenState] _endCallAndPop called. Initiating cleanup and pop.');

    if (!mounted) {
      print('[_VideoCallScreenState] Not mounted, skipping cleanup and pop.');
      return;
    }

    // Inform the other user the call is ending (if a remote ID is known)
    String? otherUserId = widget.isCaller ? SignalRTCService.targetUserId : SignalRTCService.callerUserId;
    if (otherUserId != null) {
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


    // Cancel all active stream subscriptions
    // This will now work because _subscriptions is guaranteed to be initialized
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    print('[_VideoCallScreenState] All stream subscriptions canceled.');

    // Dispose RTCPeerService
    await _rtcService.dispose();
    print('[_VideoCallScreenState] RTCPeerService disposed.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        print('[_VideoCallScreenState] Popping screen.');
        Navigator.of(context).pop();
      } else if (mounted) {
        print('[_VideoCallScreenState] Cannot pop, but mounted. Maybe pushReplacement was used or it is the root route.');

      } else {
        print('[_VideoCallScreenState] Not mounted, cannot pop.');
      }
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
    print('[_VideoCallScreenState] dispose() called. Triggering _endCallAndPop.');
    // Call the centralized cleanup method only once when dispose is triggered.
    // This ensures resources are released whether the user navigates back,
    // or the call ends through SignalR, or through the hang-up button.
    _endCallAndPop(); // Call the unified cleanup method
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print('[_VideoCallScreenState] onWillPop called.');
        _endCallAndPop(); // Handle back button press by ending the call
        return false; // Prevent default pop behavior until cleanup is done
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
                    onPressed: _endCallAndPop, // Call the centralized hangup method
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