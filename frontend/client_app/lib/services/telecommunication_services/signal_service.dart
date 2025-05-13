import 'package:signalr_core/signalr_core.dart';

class SignalService {
  late HubConnection _connection;
  Function(String from, String message)? onMessageReceived;

  Future<void> connect(String jwtToken) async {
    _connection = HubConnectionBuilder()
        .withUrl(
      'http://10.0.2.2:5000/chathub?access_token=$jwtToken',
      HttpConnectionOptions(
        transport: HttpTransportType.webSockets,
      ),
    )
        .build();

    _connection.on("ReceiveMessage", (args) {
      final from = args![0] as String;
      final message = args[1] as String;
      onMessageReceived?.call(from, message);
    });

    await _connection.start();
  }

  Future<void> sendMessage(String toUserId, String message) async {
    await _connection.invoke("SendMessage", args: [toUserId, message]);
  }

  void disconnect() {
    _connection.stop();
  }
}
