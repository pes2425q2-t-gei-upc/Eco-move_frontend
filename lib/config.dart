class AppConfig {
  static const bool isLocalDev = false;

  static const String localBaseUrl = 'http://127.0.0.1:8000/';
  static const String prodBaseUrl = 'http://nattech.fib.upc.edu:40502';

  static String get apiBase => isLocalDev ? localBaseUrl : prodBaseUrl;
  
}
