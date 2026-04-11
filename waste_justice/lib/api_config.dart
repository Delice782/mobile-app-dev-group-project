class ApiConfig {
  // Keep this aligned with the deployed web app API path.
  static const String baseUrl = 'https://wastejustice.com/WasteJustice/api';

  static String auth(String endpoint) => '$baseUrl/auth/$endpoint';
  static String pricing(String endpoint) => '$baseUrl/pricing/$endpoint';
  static String waste(String endpoint) => '$baseUrl/waste/$endpoint';
  static String payments(String endpoint) => '$baseUrl/payments/$endpoint';
  static String aggregators(String endpoint) => '$baseUrl/aggregators/$endpoint';
}
