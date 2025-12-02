import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration helper
/// Loads sensitive data from .env file
class EnvConfig {
  EnvConfig._();

  /// Azure OpenAI endpoint URL
  static String get azureEndpoint => 
      dotenv.env['AZURE_OPENAI_ENDPOINT'] ?? '';

  /// Azure OpenAI API key
  static String get azureApiKey => 
      dotenv.env['AZURE_OPENAI_API_KEY'] ?? '';

  /// Azure deployment/model name (e.g., gpt-4, gpt-35-turbo)
  static String get azureDeploymentName => 
      dotenv.env['AZURE_DEPLOYMENT_NAME'] ?? 'gpt-4';

  /// Check if Azure credentials are configured
  static bool get isAzureConfigured =>
      azureEndpoint.isNotEmpty && azureApiKey.isNotEmpty;

  /// Debug: Print current configuration (masked)
  static void printConfig() {
    print('=== Environment Configuration ===');
    print('Azure Endpoint: ${azureEndpoint.isNotEmpty ? "${azureEndpoint.substring(0, 20)}..." : "NOT SET"}');
    print('Azure API Key: ${azureApiKey.isNotEmpty ? "****${azureApiKey.substring(azureApiKey.length - 4)}" : "NOT SET"}');
    print('Azure Deployment: $azureDeploymentName');
    print('Azure Configured: $isAzureConfigured');
    print('================================');
  }
}


