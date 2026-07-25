// lib/core/failures/app_failure.dart

/// Sealed class hierarchy for typed error handling
/// Every Supabase call should catch exceptions and map to these types
sealed class AppFailure {
  final String message;
  const AppFailure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([String message = 'No internet connection. Please check your network.'])
      : super(message);
}

class AuthFailure extends AppFailure {
  const AuthFailure([String message = 'Authentication failed. Please sign in again.'])
      : super(message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([String message = 'The requested resource was not found.'])
      : super(message);
}

class PermissionFailure extends AppFailure {
  const PermissionFailure([String message = 'You do not have permission to perform this action.'])
      : super(message);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class ServerFailure extends AppFailure {
  const ServerFailure([String message = 'An unexpected server error occurred. Please try again.'])
      : super(message);
}

class StorageFailure extends AppFailure {
  const StorageFailure([String message = 'Failed to upload or retrieve file.'])
      : super(message);
}
