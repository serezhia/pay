/// Base class for the result of a quick payment operation.
sealed class QuickPayResult {
  const QuickPayResult();
}

/// Payment completed successfully.
class QuickPaySuccess extends QuickPayResult {
  const QuickPaySuccess();

  @override
  String toString() => 'QuickPaySuccess()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is QuickPaySuccess;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Payment failed.
class QuickPayFailure extends QuickPayResult {
  const QuickPayFailure();

  @override
  String toString() => 'QuickPayFailure()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is QuickPayFailure;

  @override
  int get hashCode => runtimeType.hashCode;
}

