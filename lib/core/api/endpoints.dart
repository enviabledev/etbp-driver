class Endpoints {
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String driverProfile = '/driver/profile';
  static const String driverTrips = '/driver/trips';
  static String driverTripDetail(String id) => '/driver/trips/$id';
  static String driverTripManifest(String id) => '/driver/trips/$id/manifest';
  static String driverTripStatus(String id) => '/driver/trips/$id/status';
  static String driverCheckin(String tripId, String bookingId) => '/driver/trips/$tripId/checkin/$bookingId';
  static String driverTripSummary(String id) => '/driver/trips/$id/summary';
  static String vehicleStatus(String id) => '/driver/trips/$id/vehicle-status';
  static const String conversations = '/messages/conversations';
  static String conversationMessages(String id) => '/messages/conversations/$id/messages';
  static String sendMessage(String id) => '/messages/conversations/$id/messages';
  static const String unreadCount = '/messages/unread-count';
  static String driverNavigation(String id) => '/driver/trips/$id/navigation';
  static const String registerDevice = '/notifications/register-device';
  static const String unregisterDevice = '/notifications/unregister-device';
}
