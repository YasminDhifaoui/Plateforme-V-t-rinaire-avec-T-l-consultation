// services/video_call_services/signalr_tc_service.dart
import 'dart:async'; // Import for StreamController
import 'package:flutter_webrtc/flutter_webrtc.dart'; // Keep this as RTCSessionDescription, RTCIceCandidate might be mapped to/from here
import 'package:signalr_core/signalr_core.dart';

import '../../utils/base_url.dart';

class SignalRTCService {
  static HubConnection? connection;
  static String? callerUserId; // Stored when an incoming call arrives or when accepting a call.
  static String? targetUserId; // Stored when initiating a call.

  // --- StreamControllers for different events ---
  static final _incomingCallStreamController = StreamController<String>.broadcast();
  static final _callAcceptedStreamController = StreamController<String>.broadcast(); // Pass calleeId or callerId
  static final _callRejectedStreamController = StreamController<String>.broadcast();
  static final _callEndedStreamController = StreamController<String>.broadcast(); // Pass reason
  static final _receiveOfferStreamController = StreamController<Map<String, dynamic>>.broadcast();
  static final _receiveAnswerStreamController = StreamController<Map<String, dynamic>>.broadcast();
  static final _receiveIceCandidateStreamController = StreamController<Map<String, dynamic>>.broadcast();

  // --- Public Streams to listen to ---
  static Stream<String> get incomingCallStream => _incomingCallStreamController.stream;
  static Stream<String> get callAcceptedStream => _callAcceptedStreamController.stream;
  static Stream<String> get callRejectedStream => _callRejectedStreamController.stream;
  static Stream<String> get callEndedStream => _callEndedStreamController.stream;
  static Stream<Map<String, dynamic>> get receiveOfferStream => _receiveOfferStreamController.stream;
  static Stream<Map<String, dynamic>> get receiveAnswerStream => _receiveAnswerStreamController.stream;
  static Stream<Map<String, dynamic>> get receiveIceCandidateStream => _receiveIceCandidateStreamController.stream;

  // Use a Completer to manage the asynchronous initialization state
  static Completer<void>? _initCompleter;

  static Future<void> init(String token) async {
    print('[SignalRTCService.init] - START. Token received: ${token.isNotEmpty ? 'YES' : 'NO'}');

    // If already connected, or init is already in progress, return the existing future
    if (connection != null && connection!.state == HubConnectionState.connected) {
      print('[SignalRTCService.init] - Already connected to SignalR. Skipping re-initialization.');
      return;
    }
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      print('[SignalRTCService.init] - Initialization already in progress, waiting for it to complete.');
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>(); // Create a new completer for this init attempt

    print('[SignalRTCService.init] - Building HubConnection...');
    try {
      connection = HubConnectionBuilder()
          .withUrl(
        '${BaseUrl.api}/rtchub',
        HttpConnectionOptions(
          accessTokenFactory: () => Future.value(token),
          logging: (level, message) => print('[SignalR_log] $message'),
        ),
      )
          .withAutomaticReconnect()
          .build();
      print('[SignalRTCService.init] - HubConnection built successfully. State: ${connection?.state}');

      // Register all handlers BEFORE starting the connection
      _registerHandlers();

      print('[SignalRTCService.init] - Attempting to start connection...');
      await connection!.start();
      print('[SignalRTCService.init] - Connection started successfully. ID: ${connection!.connectionId}, State: ${connection!.state}');

      if (connection!.state == HubConnectionState.connected) {
        _initCompleter!.complete(); // Mark init as successful
      } else {
        final errorMsg = 'SignalR connection failed to connect. Current state: ${connection!.state}';
        print('[SignalRTCService.init] - ERROR: $errorMsg');
        _initCompleter!.completeError(errorMsg); // Mark init as failed
      }

    } catch (e) {
      print('[SignalRTCService.init] - ERROR during init: $e');
      _initCompleter!.completeError(e); // Mark init as failed with the exception
      rethrow;
    }
    return _initCompleter!.future; // Return the future for the caller to await
  }

  static void _registerHandlers() {
    // IMPORTANT: Clear previous handlers to prevent duplicate subscriptions
    // if init() is called multiple times without a full app restart.
    connection!.off('ReceiveOffer');
    connection!.off('ReceiveAnswer');
    connection!.off('ReceiveIceCandidate');
    connection!.off('IncomingCall');
    connection!.off('CallAccepted');
    connection!.off('CallRejected');
    connection!.off('CallEnded');
    // Also clear the general connection state handlers


    connection!.on('ReceiveOffer', (args) {
      if (args != null && args.length >= 2) {
        final incomingCallerId = args[0].toString();
        final offerData = args[1] as Map<String, dynamic>;
        print('[SignalRTCService] Received Offer from: $incomingCallerId. Data: $offerData');

        _receiveOfferStreamController.add({
          'callerId': incomingCallerId,
          'offer': offerData,
        });
      } else {
        print('[SignalRTCService] ReceiveOffer - Invalid arguments received: $args');
      }
    });

    connection!.on('ReceiveAnswer', (args) {
      if (args != null && args.isNotEmpty) {
        final answerData = args[0] as Map<String, dynamic>;
        print('[SignalRTCService] Received Answer. Data: $answerData');
        _receiveAnswerStreamController.add(answerData);
      } else {
        print('[SignalRTCService] ReceiveAnswer - Invalid arguments received: $args');
      }
    });

    connection!.on('ReceiveIceCandidate', (args) {
      if (args != null && args.isNotEmpty) {
        final candidateData = args[0] as Map<String, dynamic>;
        print('[SignalRTCService] Received ICE Candidate. Data: $candidateData');
        _receiveIceCandidateStreamController.add(candidateData);
      } else {
        print('[SignalRTCService] ReceiveIceCandidate - Invalid arguments received: $args');
      }
    });

    connection!.on('IncomingCall', (args) {
      if (args != null && args.isNotEmpty) {
        final incomingCallerId = args[0].toString();
        print('[SignalRTCService] Incoming Call from: $incomingCallerId');
        callerUserId = incomingCallerId; // Store incoming callerId for callee
        _incomingCallStreamController.add(incomingCallerId);
      } else {
        print('[SignalRTCService] IncomingCall - Invalid arguments received: $args');
      }
    });

    connection!.on('CallAccepted', (args) {
      if (args != null && args.isNotEmpty) {
        final acceptedById = args[0].toString(); // The ID of the user who accepted
        print('[SignalRTCService] Call Accepted by: $acceptedById');
        _callAcceptedStreamController.add(acceptedById);
      } else {
        print('[SignalRTCService] CallAccepted - Invalid arguments received: $args');
      }
    });

    connection!.on('CallRejected', (args) {
      String reason = 'Call rejected';
      if (args != null && args.isNotEmpty) {
        reason = args[0].toString();
      }
      print('[SignalRTCService] Call Rejected: $reason');
      _callRejectedStreamController.add(reason);
      // Clear stored IDs immediately on rejection
      callerUserId = null;
      targetUserId = null;
    });

    connection!.on('CallEnded', (args) {
      String reason = 'Call ended';
      if (args != null && args.isNotEmpty) {
        reason = args[0].toString();
      }
      print('[SignalRTCService] Call Ended: $reason');
      _callEndedStreamController.add(reason);
      // This is crucial: Clear stored IDs when call ends
      callerUserId = null;
      targetUserId = null;
    });

    // Add logging for connection state changes
    connection!.onclose((error) {
      print('[SignalRTCService] Connection closed: $error');
    });

    connection!.onreconnecting((error) {
      print('[SignalRTCService] Connection reconnecting: $error');
    });

    connection!.onreconnected((connectionId) {
      print('[SignalRTCService] Connection reconnected with ID: $connectionId');
    });
  }

  // Call Management Methods
  static Future<void> initiateCall(String targetId) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Initiating call to: $targetId');
      targetUserId = targetId; // Set targetUserId when initiating
      await connection!.invoke('InitiateCall', args: [targetId]);
    } else {
      print('[SignalRTCService] Cannot initiate call: Not connected to SignalR hub.');
      throw Exception('Not connected to SignalR hub to initiate call.');
    }
  }

  static Future<void> acceptCall(String callerId) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Accepting call from: $callerId');
      // callerUserId should have been set by the 'IncomingCall' handler.
      await connection!.invoke('AcceptCall', args: [callerId]);
    } else {
      print('[SignalRTCService] Cannot accept call: Not connected to SignalR hub.');
      throw Exception('Not connected to SignalR hub to accept call.');
    }
  }

  static Future<void> rejectCall(String remoteUserId, {String? reason}) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Rejecting call for: $remoteUserId. Reason: ${reason ?? "Call rejected."}');
      await connection!.invoke('RejectCall', args: [remoteUserId, reason ?? 'Call rejected by user']);
    } else {
      print('[SignalRTCService] Cannot reject call: Not connected to SignalR hub.');
      throw Exception('Not connected to SignalR hub to reject call.');
    }
  }

  static Future<void> endCall({String? otherUserId}) async {
    if (connection?.state == HubConnectionState.connected) {
      String? userToSignal = otherUserId ?? callerUserId ?? targetUserId;
      if (userToSignal != null) {
        print('[SignalRTCService] Sending EndCall to: $userToSignal');
        await connection!.invoke('EndCall', args: [userToSignal, 'Call ended by user.']);
      } else {
        print('[SignalRTCService] No remote user ID to send EndCall signal to. Call state might be ambiguous.');
      }
    } else {
      print('[SignalRTCService] Cannot send end call signal: Not connected to SignalR hub.');
      // Allow call to proceed even if not connected, for local cleanup.
    }
    // Clear stored IDs regardless of SignalR connection state, as the call is considered ended locally.
    callerUserId = null;
    targetUserId = null;
  }

  // WebRTC Signaling Methods
  static Future<void> sendOffer(String targetId, Map<String, dynamic> offer) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Sending offer to: $targetId');
      await connection!.invoke('SendOffer', args: [targetId, offer]);
    } else {
      print('[SignalRTCService] Cannot send offer: Not connected to SignalR hub.');
      throw Exception('Not connected to SignalR hub to send offer.');
    }
  }

  static Future<void> sendAnswer(String callerId, Map<String, dynamic> answer) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Sending answer to: $callerId');
      await connection!.invoke('SendAnswer', args: [callerId, answer]);
    } else {
      print('[SignalRTCService] Cannot send answer: Not connected to SignalR hub.');
      throw Exception('Not connected to SignalR hub to send answer.');
    }
  }

  static Future<void> sendIceCandidate(String remoteUserId, Map<String, dynamic> candidate) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Sending ICE candidate to: $remoteUserId');
      await connection!.invoke('SendIceCandidate', args: [remoteUserId, candidate]);
    } else {
      print('[SignalRTCService] Cannot send ICE candidate: Not connected to SignalR hub.');
      // ICE candidates are often sent frequently, so logging and potentially ignoring might be acceptable
      // if the connection temporarily drops. Re-evaluate based on desired robustness.
    }
  }

  static Future<void> disconnect() async {
    if (connection != null && connection!.state != HubConnectionState.disconnected) {
      print('[SignalRTCService] Disconnecting SignalR connection...');
      try {
        await connection!.stop();
        print('[SignalRTCService] Connection stopped.');
      } catch (e) {
        print('[SignalRTCService] Error stopping connection: $e');
      }
    } else {
      print('[SignalRTCService] Connection was not active or initialized, skipping stop.');
    }
    // Clear stored IDs even if disconnection fails.
    callerUserId = null;
    targetUserId = null;
  }

  // Dispose all stream controllers
  static Future<void> dispose() async {
    print('[SignalRTCService] Disposing all StreamControllers and disconnecting.');

    await _incomingCallStreamController.close();
    await _callAcceptedStreamController.close();
    await _callRejectedStreamController.close();
    await _callEndedStreamController.close();
    await _receiveOfferStreamController.close();
    await _receiveAnswerStreamController.close();
    await _receiveIceCandidateStreamController.close();

    await disconnect(); // Ensure underlying hub connection is stopped

    connection = null; // Clear the static connection instance for a clean slate
    _initCompleter = null; // Clear the completer
    print('[SignalRTCService] SignalRTCService disposed completely.');
  }
}