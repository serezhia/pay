enum QuickPayEnvironment {
  /// Testing environment for debug builds.
  ///
  /// This environment is the same as sandbox
  /// but only supported for debug builds.
  testing,

  /// Sandbox environment for testing and development.
  ///
  /// Use this environment during development and testing phases.
  /// No real payments will be processed.
  sandbox,

  /// Production environment for real payments.
  ///
  /// Use this environment in release versions of your app.
  /// Real payments will be processed.
  production,
}

