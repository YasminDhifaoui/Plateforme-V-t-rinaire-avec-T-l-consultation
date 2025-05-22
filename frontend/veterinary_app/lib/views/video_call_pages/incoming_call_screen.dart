import 'package:flutter/material.dart';
import 'package:veterinary_app/views/video_call_pages/video_call_screen.dart';

import '../../services/video_call_services/signalr_tc_service.dart'; // Your existing video call screen

class IncomingCallScreen extends StatelessWidget {
  final String callerId;
  final String callerName; // Optional: Add caller details

  const IncomingCallScreen({
    Key? key,
    required this.callerId,
    this.callerName = "Unknown",
  }) : super(key: key);

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
              backgroundImage: AssetImage('assets/profile_placeholder.png'),
            ),
            const SizedBox(height: 20),
            Text(
              callerName,
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
                  heroTag: 'reject',
                  backgroundColor: Colors.red,
                  onPressed: () {
                    SignalRTCService.rejectCall(callerId);
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.call_end, size: 30),
                ),
                const SizedBox(width: 40),
                // Accept Button
                FloatingActionButton(
                  heroTag: 'accept',
                  backgroundColor: Colors.green,
                  onPressed: () {
                    Navigator.pop(context); // Close incoming call screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoCallScreen(
                          targetUserId: callerId,
                          isCaller: false, // Important: Set as receiver
                        ),
                      ),
                    );
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