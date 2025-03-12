import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:tca_flutter/tca_flutter.dart';

/// https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/CaseStudies/SwiftUICaseStudies/03-Effects-LongLiving.swift
/// This application demonstrates how to handle long-living effects, for example notifications from
/// platform services, and how to tie an effect's lifetime to the lifetime of the view.
///
/// Run this application on a device or simulator, and take a few screenshots by using the
/// screenshot gesture or menu option, and observe that the UI counts the number of times that
/// happens.
///
/// Then, navigate to another screen and take screenshots there, and observe that this screen does
/// not count those screenshots. The notifications effect is automatically cancelled when leaving
/// the screen, and restarted when entering the screen.

// MARK: - Feature domain

// State
class LongLivingEffectsState {
  int screenshotCount;

  LongLivingEffectsState({
    this.screenshotCount = 0,
  });

  @override
  String toString() =>
      'LongLivingEffectsState(screenshotCount: $screenshotCount)';
}

// Actions
sealed class LongLivingEffectsAction {
  const LongLivingEffectsAction();
}

final class TaskAction extends LongLivingEffectsAction {
  const TaskAction();
}

final class UserDidTakeScreenshotNotification extends LongLivingEffectsAction {
  const UserDidTakeScreenshotNotification();
}

// Cancel IDs for effects
enum CancelID {
  screenshots,
}

// Feature
class LongLivingEffects {
  static final reducer =
      Reducer<LongLivingEffectsState, LongLivingEffectsAction>((state, action) {
    switch (action) {
      case TaskAction():
        print("Starting screenshot effect");
        return Effect.publisher<LongLivingEffectsAction>((send) async {
          // Create a stream that listens for screenshot notifications
          final screenshotStream = ScreenshotService.screenshotStream();

          // Subscribe to the stream and send actions when screenshots are taken
          final subscription = screenshotStream.listen((_) {
            print("Screenshot detected, sending action");
            send(const UserDidTakeScreenshotNotification());
          });

          // Keep the effect alive until cancelled
          await Completer<void>().future;

          // This line will never be reached unless the effect is cancelled
          print("Screenshot effect cancelled");
          subscription.cancel();
        }).cancellable(id: CancelID.screenshots);

      case UserDidTakeScreenshotNotification():
        print(
            "Incrementing screenshot count from ${state.screenshotCount} to ${state.screenshotCount + 1}");
        state.screenshotCount = state.screenshotCount + 1;
        return Effect.none();
    }
  });
}

// Service to detect screenshots using the screenshot_callback package
class ScreenshotService {
  // Static instance to allow access from anywhere
  static final ScreenshotCallback _screenshotCallback = ScreenshotCallback();
  static final _controller = StreamController<void>.broadcast();
  static bool _isInitialized = false;
  static StreamSubscription<void>? _subscription;
  static final List<Function()> _listeners = [];

  static Stream<void> screenshotStream() {
    if (!_isInitialized) {
      print("Initializing screenshot service");
      // Initialize the screenshot callback
      _screenshotCallback.addListener(() {
        print("Real screenshot detected");
        // When a screenshot is detected, add an event to the stream
        _controller.add(null);
      });
      _isInitialized = true;
    }

    // Return the stream
    return _controller.stream;
  }

  // Method to simulate a screenshot for testing in simulators
  static void simulateScreenshot() {
    print("Simulating screenshot");
    _controller.add(null);
  }

  // Add a method to register a listener
  static void addListener(Function() listener) {
    _listeners.add(listener);
  }

  // Add a method to remove a listener
  static void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  // Clean up resources
  static void dispose() {
    _screenshotCallback.dispose();
    _subscription?.cancel();
    _controller.close();
    _isInitialized = false;
  }
}

// MARK: - Feature view

class LongLivingEffectsView extends StatefulWidget {
  final Store<LongLivingEffectsState, LongLivingEffectsAction> store;

  const LongLivingEffectsView({super.key, required this.store});

  @override
  State<LongLivingEffectsView> createState() => _LongLivingEffectsViewState();
}

class _LongLivingEffectsViewState extends State<LongLivingEffectsView> {
  @override
  void initState() {
    super.initState();
    // Start the task when the view appears
    print("Sending TaskAction");
    widget.store.send(const TaskAction());
  }

  @override
  void dispose() {
    // Clean up resources when the view is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Long-Living Effects')),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This application demonstrates how to handle long-living effects, for example '
                  'notifications from platform services, and how to tie an effect\'s lifetime to '
                  'the lifetime of the view.\n\n'
                  'Take a few screenshots by using the screenshot gesture or menu option, and '
                  'observe that the UI counts the number of times that happens.\n\n'
                  'Then, navigate to another screen and take screenshots there, and observe that '
                  'this screen does not count those screenshots. The notifications effect is '
                  'automatically cancelled when leaving the screen, and restarted when entering '
                  'the screen.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Text(
                  'A screenshot of this screen has been taken ${widget.store.state.screenshotCount} times.',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // // Simulate a screenshot for testing in simulators
                          // ScreenshotService.simulateScreenshot();
                          // Directly send the action to the store
                          print(
                              "Directly sending UserDidTakeScreenshotNotification");
                          widget.store
                              .send(const UserDidTakeScreenshotNotification());
                        },
                        child: const Text('Simulate Screenshot'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DetailView(),
                            ),
                          );
                        },
                        child: const Text('Navigate to another screen'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DetailView extends StatelessWidget {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Screen')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Take a screenshot of this screen a few times, and then go back to the previous '
            'screen to see that those screenshots were not counted.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
