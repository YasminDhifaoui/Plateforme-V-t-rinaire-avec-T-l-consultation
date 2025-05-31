import 'dart:async'; // Import for StreamController
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_core/signalr_core.dart';

import '../../utils/base_url.dart';

class SignalRTCService {
  static HubConnection? connection;
  static String? callerUserId;
  static String? targetUserId;

  static final _incomingCallStreamController = StreamController<String>.broadcast();
  static final _callAcceptedStreamController = StreamController<String>.broadcast(); // Pass calleeId or callerId
  static final _callRejectedStreamController = StreamController<String>.broadcast();
  static final _callEndedStreamController = StreamController<String>.broadcast(); // Pass reason
  static final _receiveOfferStreamController = StreamController<Map<String, dynamic>>.broadcast();
  static final _receiveAnswerStreamController = StreamController<Map<String, dynamic>>.broadcast();
  static final _receiveIceCandidateStreamController = StreamController<Map<String, dynamic>>.broadcast();

  static Stream<String> get incomingCallStream => _incomingCallStreamController.stream;
  static Stream<String> get callAcceptedStream => _callAcceptedStreamController.stream;
  static Stream<String> get callRejectedStream => _callRejectedStreamController.stream;
  static Stream<String> get callEndedStream => _callEndedStreamController.stream;
  static Stream<Map<String, dynamic>> get receiveOfferStream => _receiveOfferStreamController.stream;
  static Stream<Map<String, dynamic>> get receiveAnswerStream => _receiveAnswerStreamController.stream;
  static Stream<Map<String, dynamic>> get receiveIceCandidateStream => _receiveIceCandidateStreamController.stream;

  static Future<void> init(String token) async {
    print('[SignalRTCService.init] - START. Token received: ${token.isNotEmpty ? 'YES' : 'NO'}');

    if (connection != null && connection!.state == HubConnectionState.connected) {
      print('[SignalRTCService.init] - Already connected to SignalR. Skipping re-initialization.');
      return;
    }

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

    } catch (e) {
      print('[SignalRTCService.init] - ERROR during init: $e');
      rethrow;
    }
  }

  static void _registerHandlers() {
    connection!.on('ReceiveOffer', (args) {
      if (args != null && args.length >= 2) {
        // args[0] is the callerId, args[1] is the offer data
        callerUserId = args[0]; // Store callerId when offer received
        final offerData = args[1] as Map<String, dynamic>;
        print('[SignalRTCService] Received Offer from ${callerUserId}. Data: $offerData');
        _receiveOfferStreamController.add(offerData);
      }
    });

    connection!.on('ReceiveAnswer', (args) {
      if (args != null && args.isNotEmpty) {
        final answerData = args[0] as Map<String, dynamic>;
        print('[SignalRTCService] Received Answer. Data: $answerData');
        _receiveAnswerStreamController.add(answerData);
      }
    });

    connection!.on('ReceiveIceCandidate', (args) {
      if (args != null && args.isNotEmpty) {
        final candidateData = args[0] as Map<String, dynamic>;
        print('[SignalRTCService] Received ICE Candidate. Data: $candidateData');
        _receiveIceCandidateStreamController.add(candidateData);
      }
    });

    connection!.on('IncomingCall', (args) {
      if (args != null && args.isNotEmpty) {
        final incomingCallerId = args[0].toString();
        print('[SignalRTCService] Incoming Call from: $incomingCallerId');
        callerUserId = incomingCallerId; // Store incoming callerId
        _incomingCallStreamController.add(incomingCallerId);
      }
    });

    connection!.on('CallAccepted', (args) {
      if (args != null && args.isNotEmpty) {
        final acceptedById = args[0].toString(); // The ID of the user who accepted
        print('[SignalRTCService] Call Accepted by: $acceptedById');
        _callAcceptedStreamController.add(acceptedById);
      }
    });

    connection!.on('CallRejected', (args) {
      if (args != null && args.isNotEmpty) {
        final reason = args[0].toString();
        print('[SignalRTCService] Call Rejected: $reason');
        _callRejectedStreamController.add(reason);
      }
    });

    connection!.on('CallEnded', (args) {
      if (args != null && args.isNotEmpty) {
        final reason = args[0].toString();
        print('[SignalRTCService] Call Ended: $reason');
        _callEndedStreamController.add(reason);
      } else {
        print('[SignalRTCService] Call Ended (no specific reason)');
        _callEndedStreamController.add('Call ended');
      }
      // This is crucial: Clear stored IDs when call ends
      callerUserId = null;
      targetUserId = null;
    });

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

  static Future<void> initiateCall(String targetId) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Initiating call to: $targetId');
      targetUserId = targetId; // Set targetUserId when initiating
      await connection!.invoke('InitiateCall', args: [targetId]);
    } else {
      print('[SignalRTCService] Cannot initiate call: Not connected to SignalR hub.');
    }
  }

  static Future<void> acceptCall(String callerId) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Accepting call from: $callerId');
      callerUserId = callerId; // Set callerUserId when accepting
      await connection!.invoke('AcceptCall', args: [callerId]);
    } else {
      print('[SignalRTCService] Cannot accept call: Not connected to SignalR hub.');
    }
  }

  static Future<void> rejectCall(String remoteUserId, {String? reason}) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Rejecting call from/to: $remoteUserId. Reason: ${reason ?? "Call rejected."}');
      await connection!.invoke('RejectCall', args: [remoteUserId, reason ?? 'Call rejected']);
    } else {
      print('[SignalRTCService] Cannot reject call: Not connected to SignalR hub.');
    }
  }

  static Future<void> endCall({String? otherUserId}) async {
    if (connection?.state == HubConnectionState.connected) {
      String? userToSignal = otherUserId ?? callerUserId ?? targetUserId;
      if (userToSignal != null) {
        print('[SignalRTCService] Sending EndCall to: $userToSignal');
        await connection!.invoke('EndCall', args: [userToSignal, 'Call ended by user.']);
      } else {
        print('[SignalRTCService] No remote user ID to send EndCall signal to.');
      }
    } else {
      print('[SignalRTCService] Cannot send end call signal: Not connected to SignalR hub.');
    }

  }

  static Future<void> sendOffer(String targetId, Map<String, dynamic> offer) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Sending offer to: $targetId');
      await connection!.invoke('SendOffer', args: [targetId, offer]);
    } else {
      print('[SignalRTCService] Cannot send offer: Not connected to SignalR hub.');
    }
  }

  static Future<void> sendAnswer(String callerId, Map<String, dynamic> answer) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Sending answer to: $callerId');
      await connection!.invoke('SendAnswer', args: [callerId, answer]);
    } else {
      print('[SignalRTCService] Cannot send answer: Not connected to SignalR hub.');
    }
  }

  static Future<void> sendIceCandidate(String remoteUserId, Map<String, dynamic> candidate) async {
    if (connection?.state == HubConnectionState.connected) {
      print('[SignalRTCService] Sending ICE candidate to: $remoteUserId');
      await connection!.invoke('SendIceCandidate', args: [remoteUserId, candidate]);
    } else {
      print('[SignalRTCService] Cannot send ICE candidate: Not connected to SignalR hub.');
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
    callerUserId = null;
    targetUserId = null;
  }

  static Future<void> dispose() async {
    print('[SignalRTCService] Disposing all StreamControllers.');
    await _incomingCallStreamController.close();
    await _callAcceptedStreamController.close();
    await _callRejectedStreamController.close();
    await _callEndedStreamController.close();
    await _receiveOfferStreamController.close();
    await _receiveAnswerStreamController.close();
    await _receiveIceCandidateStreamController.close();
    await disconnect();
    print('[SignalRTCService] SignalRTCService disposed completely.');
  }
}