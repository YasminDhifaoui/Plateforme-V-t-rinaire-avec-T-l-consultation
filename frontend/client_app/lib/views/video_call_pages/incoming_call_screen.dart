import 'dart:async'; // Import for StreamSubscription

import 'package:client_app/views/video_call_pages/video_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    print('[IncomingCallScreen] initState: Setting up stream listeners.');
    // Set the caller ID in SignalRTCService for the
    // callee path immediately
    // This is crucial for sending back the answer and ICE candidates.
    SignalRTCService.callerUserId = widget.callerId;
    print('[IncomingCallScreen] Set SignalRTCService.callerUserId to ${widget.callerId}');

    _callEndedSubscription = SignalRTCService.callEndedStream.listen(_handleCallEnded);
    _callRejectedSubscription = SignalRTCService.callRejectedStream.listen(_handleCallRejected);
  }

  void _handleCallEnded(String reason) {
    print('IncomingCallScreen: Call ended by caller. Reason: $reason');
    if (mounted) {
      // If the VideoCallScreen is on top, let it handle the pop via its own _rtcService.onPeerConnectionStateChange
      // Otherwise, pop this incoming call screen
      if (Navigator.of(context).canPop()) {
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
      if (Navigator.of(context).canPop()) {
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
    // Clear the callerId in SignalRTCService when this screen is disposed,
    // as it's no longer handling a specific incoming call.
    //SignalRTCService.callerUserId = null;
    print('[IncomingCallScreen] Cleared SignalRTCService.callerUserId....');
    super.dispose();
  }

  // Inside _IncomingCallScreenState class

  Future<void> _acceptCall() async {
    if (_isAccepting) {
      print('..................................................[IncomingCallScreen] _acceptCall: Already in acceptance process, returning.');
      return;
    }
    _isAccepting = true; // Set flag at the very beginning
    print('[IncomingCallScreen] Accept button pressed for ${widget.callerId}');

    try {
      // --- STEP 1: Request Permissions ---
      print('[IncomingCallScreen] Requesting camera and microphone permissions...');
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
        print('Camera and microphone permissions are required to accept the call.');
        _isAccepting = false; // Reset flag on failure
        if (mounted) Navigator.pop(context);
        return;
      }
      print('[IncomingCallScreen] Permissions granted.');


      // --- STEP 2: Initialize WebRTC Service ---
      print('[IncomingCallScreen] Initializing RTCPeerService...');
      await RTCPeerService().initWebRTC(); // This should now handle renderers internally
      print('[IncomingCallScreen] RTCPeerService initialized and renderers set up.');

      // --- STEP 3: Accept Call via SignalR ---
      print('[IncomingCallScreen] Sending accept call signal via SignalRTCService...');
      await SignalRTCService.acceptCall(widget.callerId);
      print('[IncomingCallScreen] SignalRTCService accepted call. Waiting for offer...');

      // --- STEP 4: Listen for Offer ---
      // Make sure we cancel previous subscriptions if any are lingering (though dispose should handle)
      _offerSubscription?.cancel();
      print('[IncomingCallScreen] Attaching offer stream listener.');

      _offerSubscription = SignalRTCService.receiveOfferStream.listen((offerData) async {
        print('[IncomingCallScreen] Received offer: $offerData');
        _offerSubscription?.cancel(); // Cancel subscription after receiving the first offer
        _offerSubscription = null;

        try {
          // --- STEP 5: Set Remote Description and Create Answer ---
          print('[IncomingCallScreen] Setting remote description (offer)...');
          await RTCPeerService().setRemoteDescription(
            RTCSessionDescription(offerData['sdp'], offerData['type']),
          );
          print('[IncomingCallScreen] Remote Description (Offer) set. Creating Answer...');

          final answer = await RTCPeerService().createAnswer();
          if (answer != null) {
            // --- STEP 6: Send Answer ---
            print('[IncomingCallScreen] Sending answer to caller...');
            await SignalRTCService.sendAnswer(widget.callerId, {
              'sdp': answer.sdp,
              'type': answer.type,
            });
            print('[IncomingCallScreen] Answer sent to caller.');

            // --- STEP 7: Navigate to VideoCallScreen ---
            if (mounted) {
              print('[IncomingCallScreen] Navigating to VideoCallScreen...');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoCallScreen(
                    targetUserId: widget.callerId,
                    isCaller: false,
                    isCallAcceptedImmediately: true,
                    callerUserId: widget.callerId, // Pass callerUserId for callee side
                  ),
                ),
              );
              print('[IncomingCallScreen] Navigation complete.');
            } else {
              print('[IncomingCallScreen] Widget not mounted, cannot navigate.');
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
        } finally {
          _isAccepting = false; // Reset flag
        }
      }, onError: (error, stackTrace) { // Add onError to catch stream errors
        print('[IncomingCallScreen] ERROR in offer stream listener: $error');
        print('[IncomingCallScreen] Stack Trace from offer stream listener: $stackTrace');
        print('Error in offer stream: $error');
      }, onDone: () {
        print('[IncomingCallScreen] Offer stream listener completed.'); // Log when stream is done
      });

      // --- STEP 8: Add a timeout for receiving the offer ---
      Future.delayed(const Duration(seconds: 15), () {
        if (_offerSubscription != null && mounted) {
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
      _isAccepting = false; // Reset flag on error
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
                    print('[IncomingCallScreen] Reject button pressed for ${widget.callerId}');
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