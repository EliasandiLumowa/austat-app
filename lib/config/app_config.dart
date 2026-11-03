class AppConfig {
  // Ubah IP di sini jika laptop berpindah jaringan
  static const String localIp = '192.168.1.24';
  static const int port = 8000;

  static String get baseUrl => 'http://$localIp:$port';
}