import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

/// This file demonstrates how to handle focus state in the Composable Architecture.
///
/// In Flutter, focus is typically managed using FocusNode objects. This example shows
/// how to integrate FocusNode management with TCA's state management to create
/// a form that can programmatically control focus based on user actions.

// MARK: - Feature domain

// State
class FocusFormState {
  String username;
  String password;
  String? usernameError;
  String? passwordError;
  FocusField? focusedField;

  FocusFormState({
    this.username = '',
    this.password = '',
    this.usernameError,
    this.passwordError,
    this.focusedField,
  });

  FocusFormState copyWith({
    String? username,
    String? password,
    String? usernameError,
    String? passwordError,
    FocusField? focusedField,
    bool clearFocus = false,
  }) {
    return FocusFormState(
      username: username ?? this.username,
      password: password ?? this.password,
      usernameError: usernameError ?? this.usernameError,
      passwordError: passwordError ?? this.passwordError,
      focusedField: clearFocus ? null : (focusedField ?? this.focusedField),
    );
  }

  @override
  String toString() =>
      'FocusFormState(username: $username, password: $password, usernameError: $usernameError, passwordError: $passwordError, focusedField: $focusedField)';
}

// Focus field enum to track which field is focused
enum FocusField { username, password }

// Actions
sealed class FocusFormAction {
  const FocusFormAction();
}

final class UsernameChanged extends FocusFormAction {
  final String username;
  const UsernameChanged(this.username);
}

final class PasswordChanged extends FocusFormAction {
  final String password;
  const PasswordChanged(this.password);
}

final class FocusChanged extends FocusFormAction {
  final FocusField? field;
  const FocusChanged(this.field);
}

final class SignInButtonTapped extends FocusFormAction {
  const SignInButtonTapped();
}

final class ResetButtonTapped extends FocusFormAction {
  const ResetButtonTapped();
}

// Feature
class FocusForm {
  static final reducer =
      Reducer<FocusFormState, FocusFormAction>((state, action) {
    switch (action) {
      case UsernameChanged(username: final username):
        print("Reducer: Username changed to: $username");
        state.username = username;
        state.usernameError = null;
        return Effect.none();

      case PasswordChanged(password: final password):
        state.password = password;
        state.passwordError = null;
        return Effect.none();

      case FocusChanged(field: final field):
        state.focusedField = field;
        return Effect.none();

      case SignInButtonTapped():
        // Validate form
        final usernameError =
            state.username.isEmpty ? 'Username is required' : null;
        final passwordError =
            state.password.isEmpty ? 'Password is required' : null;

        // If there are errors, focus the first field with an error
        if (usernameError != null) {
          state.usernameError = usernameError;
          state.passwordError = passwordError;
          state.focusedField = FocusField.username;
          return Effect.none();
        } else if (passwordError != null) {
          state.usernameError = usernameError;
          state.passwordError = passwordError;
          state.focusedField = FocusField.password;
          return Effect.none();
        }

        // If no errors, show success and clear focus
        state.usernameError = null;
        state.passwordError = null;
        state.focusedField = null;
        return Effect.none();

      case ResetButtonTapped():
        state.focusedField = FocusField.username;
        return Effect.none();
    }
  });
}

// MARK: - Feature view

class FocusFormView extends StatefulWidget {
  final Store<FocusFormState, FocusFormAction> store;

  const FocusFormView({super.key, required this.store});

  @override
  State<FocusFormView> createState() => _FocusFormViewState();
}

class _FocusFormViewState extends State<FocusFormView> {
  // Create FocusNodes
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Track the last focused field from the state
  FocusField? _lastFocusedField;

  // Add a flag to track the source of state changes
  var _stateChangedExternally = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current state
    usernameController.text = widget.store.state.username;
    passwordController.text = widget.store.state.password;

    // Listen for focus changes from the UI and update the store
    usernameFocusNode.addListener(() {
      if (usernameFocusNode.hasFocus) {
        widget.store.send(const FocusChanged(FocusField.username));
      }
    });

    passwordFocusNode.addListener(() {
      if (passwordFocusNode.hasFocus) {
        widget.store.send(const FocusChanged(FocusField.password));
      }
    });

    // Set initial focus if needed
    _lastFocusedField = widget.store.state.focusedField;
    if (_lastFocusedField != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyFocus(_lastFocusedField);
      });
    }

    // Add listeners for text changes
    usernameController.addListener(_onUsernameChanged);
    passwordController.addListener(_onPasswordChanged);

    // Listen for store changes
    widget.store.addListener(_handleStoreChanges);
  }

  void _onUsernameChanged() {
    // Mark that this state change is from user input
    _stateChangedExternally = false;
    widget.store.send(UsernameChanged(usernameController.text));
  }

  void _onPasswordChanged() {
    // Mark that this state change is from user input
    _stateChangedExternally = false;
    widget.store.send(PasswordChanged(passwordController.text));
  }

  void _applyFocus(FocusField? field) {
    if (field == FocusField.username) {
      usernameFocusNode.requestFocus();
    } else if (field == FocusField.password) {
      passwordFocusNode.requestFocus();
    } else if (field == null && mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  void _updateControllersFromState() {
    final state = widget.store.state;
    // Update controllers if state changed
    if (usernameController.text != state.username) {
      final currentPosition = usernameController.selection.baseOffset;
      usernameController.text = state.username;

      // Try to maintain cursor position if possible
      if (currentPosition >= 0 && currentPosition <= state.username.length) {
        usernameController.selection = TextSelection.fromPosition(
          TextPosition(offset: currentPosition),
        );
      }
    }

    if (passwordController.text != state.password) {
      final currentPosition = passwordController.selection.baseOffset;
      passwordController.text = state.password;

      // Try to maintain cursor position if possible
      if (currentPosition >= 0 && currentPosition <= state.password.length) {
        passwordController.selection = TextSelection.fromPosition(
          TextPosition(offset: currentPosition),
        );
      }
    }
  }

  void _handleSignInButtonTapped() {
    _stateChangedExternally = true;
    widget.store.send(const SignInButtonTapped());
  }

  void _handleResetButtonTapped() {
    _stateChangedExternally = true;
    widget.store.send(const ResetButtonTapped());
  }

  void _handleStoreChanges() {
    final state = widget.store.state;

    // Only update controllers if the state change came from outside the text fields
    if (_stateChangedExternally) {
      _updateControllersFromState();
    }

    // Reset the flag
    _stateChangedExternally = false;

    // Handle focus changes
    if (state.focusedField != _lastFocusedField) {
      _lastFocusedField = state.focusedField;

      // Use post-frame callback to ensure the focus change happens after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyFocus(state.focusedField);
      });
    }
  }

  @override
  void dispose() {
    usernameController.removeListener(_onUsernameChanged);
    passwordController.removeListener(_onPasswordChanged);
    widget.store.removeListener(_handleStoreChanges);
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus State')),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, child) {
          final state = widget.store.state;
          print(state);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This example demonstrates how to manage focus state in TCA.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: const OutlineInputBorder(),
                    errorText: state.usernameError,
                  ),
                  focusNode: usernameFocusNode,
                  controller: usernameController,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    errorText: state.passwordError,
                  ),
                  focusNode: passwordFocusNode,
                  obscureText: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _handleSignInButtonTapped,
                      child: const Text('Sign In'),
                    ),
                    OutlinedButton(
                      onPressed: _handleResetButtonTapped,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// Debug Text Area
                Text(
                  'Current focus: ${state.focusedField?.toString().split('.').last ?? 'None'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Username: ${state.username}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Password: ${state.password.isNotEmpty ? '•' * state.password.length : '(empty)'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
