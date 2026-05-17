import 'package:dio/dio.dart';
import '../../constants/env.dart';

class ApiClient {
  late final Dio dio;
  String? token;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          // "Content-Type": "application/json",
          // "Accept": "application/json",
          "x-tenant-id": "demo",
          "User-Agent": "Dart Dio Client",
          // Si Postman usaba otra, agrégala:
          // "Authorization": "Bearer ${Env.apiToken}",
          // "x-api-key": Env.apiKey,
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        responseBody: true,
        requestBody: true,
      ), // Super útil para ver fallos en la Lambda
    );
  }

  void setToken(String token) {
    this.token = token;
  }

  void clearToken() {
    token = null;
  }

  Future<Response> post(String path, dynamic data) async {
    return await dio.post(path, data: data);
  }

  Future<Response> get(String path) async {
    return await dio.get(path);
  }

  Future<Response> patch(String path, dynamic data) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }
}
