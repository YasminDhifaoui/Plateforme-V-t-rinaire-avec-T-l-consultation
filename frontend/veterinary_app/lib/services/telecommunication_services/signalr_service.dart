import 'package:signalr_core/signalr_core.dart';

class SignalRService {
  late HubConnection _connection;
  final String baseUrl;
  final String userToken; // Optional if using auth
  final String userId;

  SignalRService({
    required this.baseUrl,
    required this.userId,
    this.userToken = '',
  });

  Future<void> initConnection() async {
    _connection = HubConnectionBuilder()
        .withUrl(
      '$baseUrl/webrtchub',
      HttpConnectionOptions(
        accessTokenFactory: () async => userToken,
        transport: HttpTransportType.webSockets,
      ),
    )
        .build();

    _registerHandlers();

    await _connection.start();
    print('SignalR Connected');
  }

  void _registerHandlers() {
    _connection.on('ReceiveOffer', (message) {
      print('Received Offer: $message');
      // handle incoming offer
    });

    _connection.on('ReceiveAnswer', (message) {
      print('Received Answer: $message');
      // handle incoming answer
    });

    _connection.on('ReceiveIceCandidate', (message) {
      print('Received ICE Candidate: $message');
      // handle ICE candidate
    });

    _connection.on('CallAccepted', (args) {
      print('Call Accepted');
    });

    _connection.on('CallRejected', (args) {
      print('Call Rejected');
    });
  }

  Future<void> sendOffer(String toUserId, Map<String, dynamic> offer) async {
    await _connection.invoke('SendOffer', args: [toUserId, offer]);
  }

  Future<void> sendAnswer(String toUserId, Map<String, dynamic> answer) async {
    await _connection.invoke('SendAnswer', args: [toUserId, answer]);
  }

  Future<void> sendIceCandidate(String toUserId, Map<String, dynamic> candidate) async {
    await _connection.invoke('SendIceCandidate', args: [toUserId, candidate]);
  }

  Future<void> acceptCall(String toUserId) async {
    await _connection.invoke('AcceptCall', args: [toUserId]);
  }

  Future<void> rejectCall(String toUserId) async {
    await _connection.invoke('RejectCall', args: [toUserId]);
  }

  Future<void> disconnect() async {
    await _connection.stop();
    print('SignalR Disconnected');
  }

  bool isConnected() {
    return _connection.state == HubConnectionState.connected;
  }
}
