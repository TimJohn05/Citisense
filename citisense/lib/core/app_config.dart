const bool useFirebase = bool.fromEnvironment('USE_FIREBASE');

/// Demo login buttons ship the admin password inside the binary, so they are
/// only compiled in when explicitly requested. Mock mode keeps them, because
/// there is no live data behind those accounts to protect.
const bool demoAccountsEnabled =
    bool.fromEnvironment('DEMO_ACCOUNTS') || !useFirebase;
