import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/services/video_call_services/rtc_peer_service.dart';
import 'package:veterinary_app/services/video_call_services/signalr_tc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String targetUserId;
  final bool isCaller;
  final bool isCallAcceptedImmediately;

  const VideoCallScreen({
    super.key,
    required this.targetUserId,
    required this.isCaller,
    this.isCallAcceptedImmediately = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCPeerService _rtcService = RTCPeerService(); // Get the singleton instance
  String? _callStatusMessage;
  bool _isCallActive = false;
  String? _authToken;

  bool _isAudioMuted = false;
  bool _isVideoOff = false;

  late List<StreamSubscription> _subscriptions;

  // REMOVE THESE: RTCVideoRenderer _localVideoRenderer;
  // REMOVE THESE: RTCVideoRenderer _remoteVideoRenderer;
  // These will now be accessed directly from _rtcService

  @override
  void initState() {
    super.initState();
    print('[_VideoCallScreenState] - initState started.');

    _subscriptions = []; // Initialize the list of subscriptions

    // REMOVE THIS: _localVideoRenderer = RTCVideoRenderer();
    // REMOVE THIS: _remoteVideoRenderer = RTCVideoRenderer();
    // REMOVE THIS: _initializeRenderersUI(); // This is no longer needed here

    _retrieveAuthTokenAndInitCall();
  }

  // REMOVE THIS ENTIRE METHOD, as renderers are managed by RTCPeerService
  /*
  Future<void> _initializeRenderersUI() async {
    print('[_VideoCallScreenState] Initializing UI-owned renderers.');
    try {
      await _localVideoRenderer.initialize();
      await _remoteVideoRenderer.initialize();
      print('[VideoCallScreen] UI-owned renderers initialized successfully.');
    } catch (e) {
      _handleError('Failed to initialize UI renderers: $e');
    }
  }
  */

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
    _subscriptions.add(_rtcService.onLocalStreamAvailable.listen((stream) {
      if (mounted) {
        setState(() {
          // Assign the stream to the renderer owned by RTCPeerService
          _rtcService.localRenderer!.srcObject = stream;
        });
        print('[VideoCallScreen] Local stream available and set to UI renderer.');
      }
    }));

    _subscriptions.add(_rtcService.onRemoteStreamAvailable.listen((stream) {
      if (mounted) {
        setState(() {
          // Assign the stream to the renderer owned by RTCPeerService
          _rtcService.remoteRenderer!.srcObject = stream;
        });
        print('[VideoCallScreen] Remote stream available and set to UI renderer.');
      }
    }));

    _subscriptions.add(_rtcService.onNewIceCandidate.listen((candidate) {
      final String? remoteUserId = SignalRTCService.currentCallPartnerId;
      if (remoteUserId != null) {
        print('[VideoCallScreen] Sending ICE candidate to $remoteUserId.');
        SignalRTCService.sendIceCandidate(remoteUserId, candidate.toMap());
      } else {
        print('[VideoCallScreen] WARNING: Cannot send ICE candidate, currentCallPartnerId is null.');
      }
    }));

    _subscriptions.add(_rtcService.onPeerConnectionStateChange.listen((state) {
      print('[VideoCallScreen] PeerConnection State: $state');
      if (!mounted) return;
      setState(() {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _isCallActive = true;
          _callStatusMessage = null;
          print('[VideoCallScreen] Peer connection is CONNECTED.');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _isCallActive = false;
          _callStatusMessage = 'Call Disconnected or Failed';
          print('[VideoCallScreen] Peer connection DISCONNECTED, FAILED, or CLOSED. Initiating end call.');
          _endCallAndPop();
        }
      });
    }));

    _subscriptions.add(_rtcService.onError.listen((message) {
      _handleError('RTCPeerService Error: $message');
    }));

    _subscriptions.add(SignalRTCService.receiveOfferStream.listen((offerData) async {
      print('[VideoCallScreen] SignalRTCService.receiveOfferStream: Received Offer. Data: $offerData');
      if (!widget.isCaller) {
        try {
          await _rtcService.setRemoteDescription(RTCSessionDescription(offerData['sdp'], offerData['type']));
          print('[VideoCallScreen] Callee: Remote Description (Offer) set. Creating Answer...');
          final answer = await _rtcService.createAnswer();
          if (answer != null && SignalRTCService.currentCallPartnerId != null) {
            await SignalRTCService.sendAnswer(SignalRTCService.currentCallPartnerId!, answer.toMap());
            print('[VideoCallScreen] Callee: Answer sent to ${SignalRTCService.currentCallPartnerId}.');
          } else {
            print('[VideoCallScreen] ERROR: Callee: Answer is null or currentCallPartnerId is null. Cannot send answer.');
            _handleError('Failed to create or send answer.');
          }
        } catch (e) {
          _handleError('Error processing received offer for callee: $e');
          print('[VideoCallScreen] SignalRTCService.receiveOfferStream: EXCEPTION: $e');
        }
      } else {
        print('[VideoCallScreen] WARN: Caller received unexpected offer. Ignoring.');
      }
    }));

    _subscriptions.add(SignalRTCService.receiveAnswerStream.listen((answerData) async {
      print('[VideoCallScreen] SignalRTCService.receiveAnswerStream: Received Answer. Data: $answerData');
      if (widget.isCaller) {
        try {
          await _rtcService.setRemoteDescription(RTCSessionDescription(answerData['sdp'], answerData['type']));
          print('[VideoCallScreen] Caller: Remote Description (Answer) set.');
        } catch (e) {
          _handleError('Error processing received answer for caller: $e');
        }
      } else {
        print('[VideoCallScreen] WARN: Callee received unexpected answer. Ignoring.');
      }
    }));

    _subscriptions.add(SignalRTCService.receiveIceCandidateStream.listen((candidateData) async {
      print('[VideoCallScreen] SignalRTCService.receiveIceCandidateStream: Received ICE Candidate. Data: $candidateData');
      try {
        await _rtcService.addIceCandidate(RTCIceCandidate(
          candidateData['candidate'],
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        ));
        print('[VideoCallScreen] Added remote ICE candidate.');
      } catch (e) {
        print('[VideoCallScreen] Error adding ICE candidate: $e');
      }
    }));

    _subscriptions.add(SignalRTCService.callAcceptedStream.listen((acceptedById) async {
      print('[VideoCallScreen] Call Accepted by: $acceptedById. Proceeding with offer/answer.');
      if (!mounted) return;

      SignalRTCService.currentCallPartnerId = acceptedById;
      _rtcService.setCurrentRemoteUserId(acceptedById);

      setState(() {
        _isCallActive = true;
        _callStatusMessage = null;
      });

      if (widget.isCaller) {
        try {
          print('[VideoCallScreen] Caller: Creating Offer after acceptance.');
          final offer = await _rtcService.createOffer();
          if (offer != null && SignalRTCService.currentCallPartnerId != null) {
            await SignalRTCService.sendOffer(SignalRTCService.currentCallPartnerId!, offer.toMap());
            print('[VideoCallScreen] Caller: Offer sent to ${SignalRTCService.currentCallPartnerId}.');
          } else {
            print('[VideoCallScreen] ERROR: Caller: Offer is null or currentCallPartnerId is null. Cannot send offer.');
            _handleError('Failed to create or send offer.');
          }
        } catch (e) {
          _handleError('Failed to create or send offer after acceptance: $e');
          print('[VideoCallScreen] EXCEPTION during offer creation/sending: $e');
        }
      } else {
        print('[VideoCallScreen] Callee: Call accepted signal received, awaiting offer or direct ICE candidates.');
      }
    }));

    _subscriptions.add(SignalRTCService.callRejectedStream.listen((reason) {
      _handleEndCall('Call Rejected: $reason');
    }));

    _subscriptions.add(SignalRTCService.callEndedStream.listen((reason) {
      _handleEndCall('Call Ended: $reason');
    }));

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

    // Set the target user ID immediately for the callee's services
    // We assume here that widget.targetUserId is indeed the ID of the caller who initiated this accepted call.
    _rtcService.setCurrentRemoteUserId(widget.targetUserId);
    SignalRTCService.currentCallPartnerId = widget.targetUserId;
    print('[_initCallFlow] Set currentCallPartnerId for services to: ${widget.targetUserId}');


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
      if (mounted) Navigator.of(context).pop(); // Pop if permissions denied
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
      await _rtcService.initWebRTC();
      print('[_initCallFlow] - WebRTC init completed.');

      if (!mounted) { print('[_initCallFlow] - ABORTING after WebRTC init.'); return; }

      if (widget.isCaller) {
        setState(() => _callStatusMessage = 'Calling ${widget.targetUserId}...');
        await SignalRTCService.initiateCall(widget.targetUserId);
        print('[_initCallFlow] - Caller: SignalRTCService.initiateCall sent.');
      } else { // Callee path
        print('[_initCallFlow] - Callee path. isCallAcceptedImmediately: ${widget.isCallAcceptedImmediately}');

        if (widget.isCallAcceptedImmediately) {
          setState(() {
            _callStatusMessage = 'Waiting for offer...';
            _isCallActive = true; // Mark as active, as call is immediately accepted
          });
          // The callee expects an offer to arrive.
          // The receiveOfferStream listener will handle setting remote description and creating the answer.
          // There's no explicit "accept call" signal to send from this screen
          // because the assumption is it was already accepted before navigating here.
          // Just proceed to wait for the offer.

          print('[VideoCallScreen] Callee: Call accepted immediately. Awaiting offer.');

        } else {
          // This 'else' block implies a scenario where the call was NOT accepted immediately,
          // which contradicts the `isCallAcceptedImmediately` flag.
          // You might not even need this 'else' if this screen is ONLY used for immediately accepted calls for callee.
          _handleError("Callee: Invalid call state. Call not accepted immediately.");
          return;
        }
      }
    } catch (e) {
      _handleError('Failed to initialize call setup: $e');
      print('[_initCallFlow] - ERROR initializing call setup: $e');
      return;
    }

    // Remove the `_isCallActive` check here if the callee path sets it earlier.
    if (mounted && _callStatusMessage != null) { // Removed && _isCallActive
      setState(() => _callStatusMessage = null); // Clear message if everything is set up
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
        _endCallAndPop();
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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _endCallAndPop();
      }
    });
  }

  Future<void> _endCallAndPop() async {
    print('[_VideoCallScreenState] _endCallAndPop called. Initiating cleanup and pop.');

    if (!mounted) {
      print('[_VideoCallScreenState] Not mounted, skipping cleanup and pop.');
      return;
    }

    // Clear renderers' srcObjects immediately for UI feedback
    // Access the renderers directly from _rtcService
    _rtcService.localRenderer?.srcObject = null;
    _rtcService.remoteRenderer?.srcObject = null;
    print('[_VideoCallScreenState] Renderers\' srcObjects cleared.');


    final String? remotePartnerId = SignalRTCService.currentCallPartnerId;
    if (remotePartnerId != null) {
      print('[_VideoCallScreenState] Attempting to send endCall signal to $remotePartnerId.');
      try {
        await SignalRTCService.endCall(otherUserId: remotePartnerId);
        print('[_VideoCallScreenState] endCall signal sent successfully to $remotePartnerId.');
      } catch (e) {
        print('[_VideoCallScreenState] WARNING: Failed to send endCall signal: $e');
      }
    } else {
      print('[_VideoCallScreenState] No remote partner ID to send EndCall signal to. Call ended locally.');
    }

    // Cancel all stream subscriptions to prevent further callbacks
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    print('[_VideoCallScreenState] All stream subscriptions canceled.');

    // This method is now responsible for telling RTCPeerService to clean up its *WebRTC objects* for the call
    // but NOT to dispose of the service's long-lived renderers or stream controllers.
    // Assuming RTCPeerService has an `endCurrentCall` or similar method that calls `_cleanUpPreviousWebRTCObjects`
    await _rtcService.endCurrentCall(); // Assuming you added this public method
    print('[_VideoCallScreenState] RTCPeerService\'s current call resources cleaned.');

    // REMOVE THESE, as renderers are owned and disposed by RTCPeerService ONLY when the entire service shuts down.
    // await _localVideoRenderer.dispose();
    // await _remoteVideoRenderer.dispose();
    // print('[_VideoCallScreenState] UI-owned renderers disposed.');

    SignalRTCService.clearCurrentCallPartner();
    print('[_VideoCallScreenState] SignalRTCService.currentCallPartnerId cleared.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        print('[_VideoCallScreenState] Popping screen.');
        Navigator.of(context).pop();
      } else if (mounted) {
        print('[_VideoCallScreenState] Cannot pop, but mounted. Maybe this is the root route or pushReplacement was used.');
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
    // It's crucial to call _endCallAndPop to clean up resources
    // before the widget is fully disposed.
    _endCallAndPop(); // This will handle all cleanup including canceling subscriptions
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        print('[_VideoCallScreenState] onPopInvoked called.');
        _endCallAndPop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              // Use _rtcService.remoteRenderer directly
        child: _rtcService.remoteRenderer != null && _rtcService.remoteRenderer!.srcObject != null
        ? RTCVideoView(_rtcService.remoteRenderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
            : Container(
                color: Colors.black,
                child: Center(
                  child: Text(
                    _isCallActive ? 'Waiting for remote video..' : (_callStatusMessage ?? 'Connecting...'),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              width: 120,
              height: 160,
              // Use _rtcService.localRenderer directly
              child: _rtcService.localRenderer!.srcObject != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(_rtcService.localRenderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: true),
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
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
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
                    onPressed: _endCallAndPop,
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