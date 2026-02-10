/// API configuration
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://nifty-paper-trading-api.onrender.com',
  );

  // Endpoints
  static const String signalsCurrent = '/api/signals/current';
  static const String signalsHistory = '/api/signals/history';
  static String trades(String version) => '/api/trades/$version';
  static String delayAnalysis(String version) =>
      '/api/trades/$version/delay-analysis';
  static String returns(String version) => '/api/trades/$version/returns';
  static const String chartNifty = '/api/chart-data/nifty';
  static String chartEquity(String version) =>
      '/api/chart-data/equity/$version';
  static const String chartDrawdownComparison =
      '/api/chart-data/drawdown-comparison';
  static const String indicators = '/api/indicators';
}
