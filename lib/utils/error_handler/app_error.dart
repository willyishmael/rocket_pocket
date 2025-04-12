import 'package:flutter/foundation.dart';
import 'package:rocket_pocket/utils/global.dart';

abstract class AppError implements Exception {
  final String message;
  final StackTrace? stackTrace;

  const AppError(this.message, this.stackTrace);

  void logError() {
    if (kDebugMode) {
      talker.handle(this, stackTrace, runtimeType);
    }
  }

  Never throwError() {
    logError();
    throw this;
  }

  @override
  String toString() => '$runtimeType: $message';
}

class DatabaseError extends AppError {
  const DatabaseError(super.message, super.stackTrace);
}

class NetworkError extends AppError {
  const NetworkError(super.message, super.stackTrace);
}

class ValidationError extends AppError {
  const ValidationError(super.message, super.stackTrace);
}

class AuthenticationError extends AppError {
  const AuthenticationError(super.message, super.stackTrace);
}

class PermissionError extends AppError {
  const PermissionError(super.message, super.stackTrace);
}

class NotFoundError extends AppError {
  const NotFoundError(super.message, super.stackTrace);
}

class UnknownError extends AppError {
  const UnknownError([
    super.message = "An unknown error occurred",
    super.stackTrace,
  ]);
}
