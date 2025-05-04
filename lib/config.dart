class AppConfig {
  static const bool isLocalDev = true;

  static const String localBaseUrl = 'http://127.0.0.1:8000/';
  static const String prodBaseUrl = 'https://eco-move-backend.onrender.com';

  static String get apiBase => isLocalDev ? localBaseUrl : prodBaseUrl;

  static String baseUrl = 'http://127.0.0.1:8000'; // Change this as needed
}
