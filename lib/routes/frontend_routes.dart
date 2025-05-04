import 'package:eco_move_frontend/config.dart';

class FrontendRoutes {
  static String get apiBase => AppConfig.apiBase;

  // method to build full URLs
  static String build(String path) => '$apiBase$path';

  // Auth
  static const String login = 'token/';
  static const String refreshToken = 'token/refresh/';
  static const String register = 'register/';
  static const String me = 'me/';

  // Charging Stations
  static const String chargingStations = 'api_punts_carrega/estacions/';
  static const String nearestStation = 'api_punts_carrega/punt_mes_proper/';
  static const String chargingStationDetail =
      'api_punts_carrega/estacions/'; // + id
  static const String filterOptions = 'api_punts_carrega/opcions_filtres/';

  // Language
  static const String updateLanguage = 'api_punts_carrega/update_language/';
  static String updateUserLanguage(int userId) =>
      'api_punts_carrega/usuari/$userId/update-language/';

  // Reservations
  static const String listReservations = 'api_punts_carrega/reservas/';
  static const String createReservation = 'api_punts_carrega/reservas/crear/';
  static String editReservation(int id) =>
      'api_punts_carrega/reservas/$id/modificar/';
  static String deleteReservation(int id) =>
      'api_punts_carrega/reservas/$id/eliminar/';

  // Dynamic route builder for charging station detail
  static String stationById(String id) => 'api_punts_carrega/estacions/$id/';

  static const String nearestShelters =
      'api_punts_carrega/refugios_mas_cercanos/';
  static String shelterById(String id) => 'api_punts_carrega/refugios/$id/';
}
