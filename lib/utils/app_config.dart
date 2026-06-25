// Simple runtime configuration for local development.
// Update the values below when testing on real devices.

class AppConfig {
  // IP or hostname of the machine running the Flask API (without protocol)
  static String apiHost = 'write your ip address';

  // Port where Flask API listens
  static int apiPort = 5000;

  // WebSocket signaling server URL for WebRTC (include ws:// or wss://)
  static String signalingUrl = 'ws://write your ip address:8081';

  // Derived base URL for HTTP API
  static String get apiBaseUrl => 'http://$apiHost:$apiPort';

  // Optional TURN/STUN servers for ICE. Add your TURN server(s) here
  // as maps with keys: 'urls' (string or list), and optionally 'username' and 'credential'.
  // Example:
  // static const List<Map<String, dynamic>> turnServers = [
  //   {
  //     'urls': ['stun:stun.l.google.com:19302'],
  //   },
  //   {
  //     'urls': ['turn:turn.example.com:3478?transport=udp'],
  //     'username': 'user',
  //     'credential': 'pass',
  //   },
  // ];
  // The entry below includes a public STUN server and a commonly-used
  // public TURN test server (numb.viagenie). The TURN credentials are
  // public test credentials and should only be used for debugging. For
  // production, deploy your own TURN server (coturn) and update these.
  // Public STUN servers are known to occasionally break WebRTC for devices
  // located on the exact same WiFi network if the router doesn't allow 'NAT Loopback'.
  // Setting this to an empty array forces the phones to connect to each other 
  // directly through their local 192.168.x.x addresses on the same WiFi!
  static const List<Map<String, dynamic>> turnServers = [];
}
