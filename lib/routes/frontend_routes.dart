import 'package:eco_move_frontend/config.dart';

class FrontendRoutes {
  static String get apiBase => AppConfig.apiBase;

  // method to build full URLs
  static String build(String path) => '$apiBase$path';

  // Auth
  static const String token = '/token/';
  static const String tokenRefresh = '/token/refresh/';
  static const String register = '/register/';
  static const String me = '/me/';

  // User
  static const String users = '/api_punts_carrega/usuari/';
  static const String profilePhoto = '/profile/foto/';

  static String profilePhotoUsername(String username) =>'/profile/$username/';

  static const String price = '/api_punts_carrega/preu_kwh/';
  static String user(int id) => '/api_punts_carrega/usuari/$id/';

  // Charging Stations
  static const String chargingStations = '/api_punts_carrega/estacions/';
  static const String puntmesproper = '/api_punts_carrega/punt_mes_proper/';
  static String estacion(String station) =>
      '/api_punts_carrega/estacions/$station';
  static String valoracionesEstaciones = '/api_punts_carrega/valoraciones_estaciones/';

  // Filters
  static const String opcionsFiltres = '/api_punts_carrega/opcions_filtres/';
  static const String filtrarEstacions = '/api_punts_carrega/filtrar_estacions/';

  // Language
  static const String updateLanguage = '/api_punts_carrega/update_language/';
  static String usuariUpdateLanguage(int userId) =>
      '/api_punts_carrega/usuari/$userId/update-language/';

  // Reservations
  static const String reservas = '/api_punts_carrega/reservas/';
  static const String reservasCrear = '/api_punts_carrega/reservas/crear/';
  static String reservasModificar(int id) =>
      '/api_punts_carrega/reservas/$id/modificar/';
  static String reservasEliminar(int id) =>
      '/api_punts_carrega/reservas/$id/eliminar/';
  static String reservasDia(String date) =>
      '/api_punts_carrega/reservas/?dia=$date';

  // Shelters
  static const String refugios ='/api_punts_carrega/refugios_mas_cercanos/';
  static String refugio(String id) => '/api_punts_carrega/refugios/$id/';

  // Chat
  static const String messages = '/social/messages/';
  static String chatMessages(int id) => '/social/chat/$id/messages/';
  static const String myChats = '/social/chat/my_chats/';
  static const String createChat = '/social/chat/create_chat/';

  // Alerts
  static const String alerts = '/social/alerts/';
  static const String alertsPollingAlertes = '/social/alerts/polling_alertes/';

  static const String googleSignin = '/auth/social/google/';

  //Notificar Error
  static const String tiposErrorEstacion = '/api_punts_carrega/tipos_error_estacion/';
  static String reportarErrorEstacion(String id) => '/api_punts_carrega/estacions/$id/reportar_error/';

  static String reportChat = '/social/reports/report_from_chat/';

  //Bicis
  static const String biciDetailBase = '/api/bicing/estaciones/';
  static String biciDetailById(String id) => '/api/bicing/estaciones/$id';
  static const String biciReserva = '/api/bicing/reservas/';
  static const String biciReservasActivas = '/api/bicing/reservas/mis_reservas/';
  static const String biciReservasHistorial = '/api/bicing/reservas/historial/';
  static String biciReservaCancelar(String id) => '/api/bicing/reservas/$id/';

  // Throphies
  static String usuariGetPunts(int userId) => '/api_punts_carrega/usuari/$userId/getPunts/';
  static String usuariSumaPunts(int userId) => '/api_punts_carrega/usuari/$userId/sumaPunts/';
  static String usuariRestarPunts(int userId) => '/api_punts_carrega/usuari/$userId/restarPunts/';
  static String usuariTrofeos(int userId) => '/api_punts_carrega/usuari/$userId/trofeos/';

  static String addPoints(int id) => '/api_punts_carrega/usuari/$id/sumaPunts/';

}
