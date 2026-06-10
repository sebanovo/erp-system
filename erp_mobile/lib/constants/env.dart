import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String baseUrl = dotenv.get("BASE_URL") == ""
      ? "https://ninuwu5pf0.execute-api.us-east-1.amazonaws.com"
      : dotenv.get("BASE_URL");
  static String systemName = dotenv.get("SYSTEM_NAME") == ""
      ? "ERP IA"
      : dotenv.get("SYSTEM_NAME");
  static String openRouterApiKey = dotenv.maybeGet("OPEN_ROUTER_API_KEY") ?? "";
  static String aiModel = dotenv.maybeGet("AI_MODEL") ?? "openai/gpt-4o-mini";
}
