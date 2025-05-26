// views/video_call_pages/incoming_call_screen.dart
import 'dart:async'; // Required for StreamSubscription

import 'package:flutter/material.dart';
import 'package:veterinary_app/views/video_call_pages/video_call_screen.dart';
import '../../services/video_call_services/signalr_tc_service.dart';
import '../../services/video_call_services/rtc_peer_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerId;
  final String callerName; // Optional: Add caller details

  const IncomingCallScreen({
    Key? key,
    required this.callerId,
    this.callerName = "Unknown", // Default to Unknown if name isn't passed
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  // Use StreamSubscription to manage listeners
  late StreamSubscription _callEndedSubscription;
  late StreamSubscription _callRejectedSubscription;

  @override
  void initState() {
    super.initState();
    print('[IncomingCallScreen] initState: Setting up stream listeners.');
    // Subscribe to call ended stream
    _callEndedSubscription = SignalRTCService.callEndedStream.listen((reason) {
      _handleCallEnded(reason);
    });

    // Subscribe to call rejected stream
    _callRejectedSubscription = SignalRTCService.callRejectedStream.listen((reason) {
      _handleCallRejected(reason);
    });
  }

  // Listen for if the caller cancels before we accept
  void _handleCallEnded(String reason) {
    print('IncomingCallScreen: Call ended by caller. Reason: $reason');
    if (mounted) {
      Navigator.pop(context); // Pop this incoming call screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call ended by caller: $reason')),
      );
    }
  }

  void _handleCallRejected(String reason) {
    print('IncomingCallScreen: Rejected signal from caller. Reason: $reason');
    if (mounted) {
      Navigator.pop(context); // Pop this incoming call screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call status: $reason')),
      );
    }
  }

  @override
  void dispose() {
    print('[IncomingCallScreen] dispose: Cancelling stream subscriptions.');
    // Clean up subscriptions
    _callEndedSubscription.cancel();
    _callRejectedSubscription.cancel();
    super.dispose();
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
              backgroundImage: AssetImage('assets/profile_placeholder.png'), // Ensure this asset exists
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
                // Reject Button
                FloatingActionButton(
                  heroTag: 'reject_call', // Unique heroTag
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    print('[IncomingCallScreen] Reject button pressed for ${widget.callerId}');
                    await SignalRTCService.rejectCall(widget.callerId, reason: 'Rejected by user');
                    if (mounted) {
                      Navigator.pop(context); // Close incoming call screen
                    }
                  },
                  child: const Icon(Icons.call_end, size: 30),
                ),
                const SizedBox(width: 40),
                // Accept Button
                FloatingActionButton(
                  heroTag: 'accept_call', // Unique heroTag
                  backgroundColor: Colors.green,
                  onPressed: () async {
                    print('[IncomingCallScreen] Accept button pressed for ${widget.callerId}');
                    try {
                      // 1. Initialize WebRTC for the callee
                      // RTCPeerService().initRenderers() is crucial for video output
                      await RTCPeerService().initRenderers();
                      await RTCPeerService().initWebRTC(); // No longer needs `isCaller` param
                      print('[IncomingCallScreen] RTCPeerService initialized.');

                      // 2. Accept the call via SignalR
                      // SignalRTCService.callerUserId should be set by the 'IncomingCall' handler in HomePage
                      // However, explicitly passing widget.callerId here is safer.
                      await SignalRTCService.acceptCall(widget.callerId);
                      print('[IncomingCallScreen] SignalRTCService accepted call.');

                      // 3. Navigate to the Video Call Screen
                      if (mounted) {
                        // Use pushReplacement to replace this screen with VideoCallScreen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCallScreen(
                              targetUserId: widget.callerId, // For callee, target is the caller
                              isCaller: false, // Important: Set as receiver
                              isCallAcceptedImmediately: true, // Signal it's accepted
                            ),
                          ),
                        );
                        print('[IncomingCallScreen] Navigated to VideoCallScreen.');
                      }
                    } catch (e) {
                      print('Error accepting call: $e');
                      // If WebRTC init or SignalR accept fails, reject the call and pop
                      await SignalRTCService.rejectCall(widget.callerId, reason: 'Failed to initialize call setup');
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to accept call: $e')),
                        );
                      }
                    }
                  },
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