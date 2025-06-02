import 'dart:async'; // Import for StreamSubscription

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:veterinary_app/views/video_call_pages/video_call_screen.dart';
import '../../services/video_call_services/signalr_tc_service.dart';
import '../../services/video_call_services/rtc_peer_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerId;
  final String callerName;

  const IncomingCallScreen({
    Key? key,
    required this.callerId,
    this.callerName = "Unknown",
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late StreamSubscription _callEndedSubscription;
  late StreamSubscription _callRejectedSubscription;
  StreamSubscription? _offerSubscription;
  StreamSubscription? _peerConnectionStateSubscription;
  late List<StreamSubscription> _subscriptions; // ADDED: Declare _subscriptions list
  bool _isAccepting = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    print('[IncomingCallScreen] initState: Setting up stream listeners.');

    _subscriptions = []; // INITIALIZE: Initialize the list in initState

    RTCPeerService().setCurrentRemoteUserId(widget.callerId);
    SignalRTCService.currentCallPartnerId = widget.callerId;
    print('[IncomingCallScreen] Set RTCPeerService._currentRemoteUserId and SignalRTCService.currentCallPartnerId to ${widget.callerId}');

    _callEndedSubscription = SignalRTCService.callEndedStream.listen(_handleCallEnded);
    _callRejectedSubscription = SignalRTCService.callRejectedStream.listen(_handleCallRejected);

    _peerConnectionStateSubscription = RTCPeerService().onPeerConnectionStateChange.listen((state) {
      print('[IncomingCallScreen] RTCPeerConnection State changed: $state');
      // REMOVED: RTCPeerConnectionStateCompleted as it might not exist
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected && mounted && !_isNavigating) {
        _isNavigating = true;
        print('[IncomingCallScreen] Peer connection connected. Navigating to VideoCallScreen...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              targetUserId: widget.callerId,
              isCaller: false,
              isCallAcceptedImmediately: true,
            ),
          ),
        );
        print('[IncomingCallScreen] Navigation complete.');
      } else if ((state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) &&
          mounted && _isAccepting && !_isNavigating) {
        print('[IncomingCallScreen] Peer connection failed or closed. Popping screen.');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.pop(context);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call failed: Peer connection closed unexpectedly.')),
          );
          _isAccepting = false;
        });
      }
    });

    _subscriptions.add(RTCPeerService().onNewIceCandidate.listen((candidate) {
      final remoteId = SignalRTCService.currentCallPartnerId;
      if (remoteId != null) {
        print('[IncomingCallScreen] Sending ICE candidate to $remoteId: ${candidate.candidate}');
        SignalRTCService.sendIceCandidate(remoteId, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      } else {
        print('[IncomingCallScreen] WARNING: Cannot send ICE candidate, currentCallPartnerId is null.');
      }
    }));
  }

  void _handleCallEnded(String reason) {
    print('IncomingCallScreen: Call ended by caller. Reason: $reason');
    if (mounted) {
      if (!_isNavigating && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call ended by caller: $reason')),
      );
    }
  }

  void _handleCallRejected(String reason) {
    print('IncomingCallScreen: Rejected signal from caller. Reason: $reason');
    if (mounted) {
      if (!_isNavigating && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call status: $reason')),
      );
    }
  }

  @override
  void dispose() {
    print('[IncomingCallScreen] dispose: Cancelling stream subscriptions.');
    _callEndedSubscription.cancel();
    _callRejectedSubscription.cancel();
    _offerSubscription?.cancel();
    _peerConnectionStateSubscription?.cancel();
    // CANCEL ALL: Loop through _subscriptions and cancel them
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear(); // Clear the list
    super.dispose();
  }

  Future<void> _acceptCall() async {
    if (_isAccepting) {
      print('[IncomingCallScreen] _acceptCall: Already in acceptance process, returning.');
      return;
    }
    _isAccepting = true;
    print('[IncomingCallScreen] Accept button pressed for ${widget.callerId}');

    try {
      print('[IncomingCallScreen] Requesting camera and microphone permissions...');
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
        print('Camera and microphone permissions are required to accept the call.');
        _isAccepting = false;
        if (mounted) Navigator.pop(context);
        return;
      }
      print('[IncomingCallScreen] Permissions granted.');

      print('[IncomingCallScreen] Initializing RTCPeerService...');
      await RTCPeerService().initWebRTC();
      print('[IncomingCallScreen] RTCPeerService initialized and renderers set up.');

      print('[IncomingCallScreen] Sending accept call signal via SignalRTCService...');
      await SignalRTCService.acceptCall(widget.callerId);
      print('[IncomingCallScreen] SignalRTCService accepted call. Waiting for offer...');

      _offerSubscription?.cancel();
      print('[IncomingCallScreen] Attaching offer stream listener.');

      _offerSubscription = SignalRTCService.receiveOfferStream.listen((offerData) async {
        print('[IncomingCallScreen] Received offer: $offerData');
        _offerSubscription?.cancel();
        _offerSubscription = null;

        try {
          print('[IncomingCallScreen] Setting remote description (offer)...');
          await RTCPeerService().setRemoteDescription(
            RTCSessionDescription(offerData['sdp'], offerData['type']),
          );
          print('[IncomingCallScreen] Remote Description (Offer) set. Creating Answer...');

          final answer = await RTCPeerService().createAnswer();
          if (answer != null) {
            print('[IncomingCallScreen] Sending answer to caller...');
            final String? partnerId = SignalRTCService.currentCallPartnerId;
            if (partnerId != null) {
              await SignalRTCService.sendAnswer(partnerId, {
                'sdp': answer.sdp,
                'type': answer.type,
              });
              print('[IncomingCallScreen] Answer sent to $partnerId. Waiting for ICE connection...');
            } else {
              print('[IncomingCallScreen] ERROR: currentCallPartnerId is null. Cannot send answer.');
              throw Exception('Failed to get current call partner ID.');
            }
          } else {
            print('[IncomingCallScreen] ERROR: Answer is null. Cannot send answer.');
            throw Exception('Failed to create answer.');
          }
        } catch (e) {
          print('Error handling offer: $e');
          print('[IncomingCallScreen] EXCEPTION during offer handling: $e');
          await SignalRTCService.rejectCall(widget.callerId, reason: 'Failed to handle offer');
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to handle offer: $e')),
            );
          }
          _isAccepting = false;
        }
      }, onError: (error, stackTrace) {
        print('[IncomingCallScreen] ERROR in offer stream listener: $error');
        print('[IncomingCallScreen] Stack Trace from offer stream listener: $stackTrace');
        _isAccepting = false;
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error in offer stream: $error')),
          );
        }
      }, onDone: () {
        print('[IncomingCallScreen] Offer stream listener completed.');
      });

      Future.delayed(const Duration(seconds: 15), () {
        if (_offerSubscription != null && mounted && _isAccepting && !_isNavigating) {
          print('[IncomingCallScreen] No offer received within timeout. Rejecting call.');
          _offerSubscription?.cancel();
          _offerSubscription = null;
          SignalRTCService.rejectCall(widget.callerId, reason: 'Offer timeout');
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Call failed: No offer received.')),
            );
          }
          _isAccepting = false;
        }
      });

    } catch (e) {
      print('Error accepting call: $e');
      print('[IncomingCallScreen] EXCEPTION in _acceptCall: $e');
      await SignalRTCService.rejectCall(widget.callerId, reason: 'Failed to initialize call setup');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept call: $e')),
        );
      }
      _isAccepting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/doctor.png'),
            ),
            const SizedBox(height: 20),
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Incoming Video Call...",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'reject_call',
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    print('[IncomingCallScreen] Reject button pressed for: ${widget.callerId}');
                    await SignalRTCService.rejectCall(widget.callerId, reason: 'Rejected by user');
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Icon(Icons.call_end, size: 30),
                ),
                const SizedBox(width: 40),
                FloatingActionButton(
                  heroTag: 'accept_call',
                  backgroundColor: Colors.green,
                  onPressed: _acceptCall,
                  child: const Icon(Icons.videocam, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}