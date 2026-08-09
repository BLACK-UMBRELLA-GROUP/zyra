package com.example.app

// FlutterFragmentActivity, not FlutterActivity — changed 2026-08-07 for
// App Lock (local_auth).
//
// Android's BiometricPrompt is a Fragment, so it needs a FragmentActivity
// to attach to. On a plain FlutterActivity the Dart side compiles and runs
// perfectly and then throws at the moment the user first taps Unlock,
// which is the worst possible place to discover it. FlutterFragmentActivity
// is a drop-in replacement with no other behavioural difference.
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
