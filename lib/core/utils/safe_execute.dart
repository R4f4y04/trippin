import 'app_logger.dart';

typedef AsyncOperation<T> = Future<T> Function();
typedef ErrorHandler = void Function(Object error, StackTrace stackTrace);

typedef SyncOperation<T> = T Function();
typedef SyncErrorHandler = void Function(Object error, StackTrace stackTrace);

Future<T?> safeExecute<T>({
  required AsyncOperation<T> operation,
  ErrorHandler? onError,
}) async {
  try {
    return await operation();
  } catch (error, stackTrace) {
    if (onError != null) {
      onError(error, stackTrace);
    } else {
      AppLogger.error('Unhandled async error', error, stackTrace);
    }
    return null;
  }
}

T? safeExecuteSync<T>({
  required SyncOperation<T> operation,
  SyncErrorHandler? onError,
}) {
  try {
    return operation();
  } catch (error, stackTrace) {
    if (onError != null) {
      onError(error, stackTrace);
    } else {
      AppLogger.error('Unhandled sync error', error, stackTrace);
    }
    return null;
  }
}
