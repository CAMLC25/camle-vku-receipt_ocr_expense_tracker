/// Domain error and failure abstractions.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
