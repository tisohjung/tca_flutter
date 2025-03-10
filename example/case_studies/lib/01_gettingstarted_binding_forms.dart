import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

/// This file demonstrates how to handle two-way bindings in the Composable Architecture.
///
/// Bindable actions allow you to safely eliminate the boilerplate caused by needing to have a
/// unique action for every UI control. Instead, all UI bindings can be consolidated into a single
/// binding action, which the BindingReducer can automatically apply to state.
///
/// It is instructive to compare this case study to the "Binding Basics" case study.

// MARK: - Feature domain

// State
class BindingFormState {
  double sliderValue;
  int stepCount;
  String text;
  bool toggleIsOn;

  BindingFormState({
    this.sliderValue = 5.0,
    this.stepCount = 10,
    this.text = '',
    this.toggleIsOn = false,
  });

  @override
  String toString() =>
      'BindingFormState(sliderValue: $sliderValue, stepCount: $stepCount, text: $text, toggleIsOn: $toggleIsOn)';
}

// Actions
sealed class BindingFormAction {
  const BindingFormAction();
}

final class SliderValueChanged extends BindingFormAction {
  final double value;
  const SliderValueChanged(this.value);
}

final class StepCountChanged extends BindingFormAction {
  final int value;
  const StepCountChanged(this.value);
}

final class TextChanged extends BindingFormAction {
  final String value;
  const TextChanged(this.value);
}

final class ToggleChanged extends BindingFormAction {
  final bool value;
  const ToggleChanged(this.value);
}

final class ResetButtonTapped extends BindingFormAction {
  const ResetButtonTapped();
}

// Feature
class BindingForm {
  static final reducer =
      Reducer<BindingFormState, BindingFormAction>((state, action) {
    switch (action) {
      case SliderValueChanged(value: final value):
        state.sliderValue = value;
        return Effect.none();

      case StepCountChanged(value: final value):
        state.stepCount = value;
        // Ensure slider value doesn't exceed step count
        state.sliderValue = state.sliderValue.clamp(0, value.toDouble());
        return Effect.none();

      case TextChanged(value: final value):
        state.text = value;
        return Effect.none();

      case ToggleChanged(value: final value):
        state.toggleIsOn = value;
        return Effect.none();

      case ResetButtonTapped():
        // Reset to initial state
        state.sliderValue = 5.0;
        state.stepCount = 10;
        state.text = '';
        state.toggleIsOn = false;
        return Effect.none();
    }
  });

  // Action creators
  static const resetButtonTapped = ResetButtonTapped();
}

// MARK: - Feature view

class BindingFormView extends StatelessWidget {
  final Store<BindingFormState, BindingFormAction> store;

  const BindingFormView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bindings Form')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This example demonstrates how to handle two-way bindings in the Composable Architecture.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Type here',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !store.state.toggleIsOn,
                  style: TextStyle(
                    color: store.state.toggleIsOn ? Colors.grey : Colors.black,
                  ),
                  onChanged: (value) {
                    store.send(TextChanged(value));
                  },
                  controller: TextEditingController(text: store.state.text),
                ),
                Text(alternateCase(store.state.text)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Disable other controls'),
                  value: store.state.toggleIsOn,
                  onChanged: (value) {
                    store.send(ToggleChanged(value));
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Max slider value: '),
                    Text(
                      '${store.state.stepCount}',
                      style: const TextStyle(fontFeatures: [
                        FontFeature.tabularFigures(),
                      ]),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: store.state.toggleIsOn
                          ? null
                          : () {
                              if (store.state.stepCount > 1) {
                                store.send(StepCountChanged(
                                    store.state.stepCount - 1));
                              }
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: store.state.toggleIsOn
                          ? null
                          : () {
                              store.send(
                                  StepCountChanged(store.state.stepCount + 1));
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Slider value: ${store.state.sliderValue.toInt()}',
                      style: const TextStyle(fontFeatures: [
                        FontFeature.tabularFigures(),
                      ]),
                    ),
                  ],
                ),
                Slider(
                  value: store.state.sliderValue,
                  min: 0,
                  max: store.state.stepCount.toDouble(),
                  divisions: store.state.stepCount,
                  onChanged: store.state.toggleIsOn
                      ? null
                      : (value) {
                          store.send(SliderValueChanged(value));
                        },
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      store.send(BindingForm.resetButtonTapped);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset'),
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

/// Alternates the case of each character in the string.
String alternateCase(String input) {
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (i % 2 == 0) {
      buffer.write(char.toUpperCase());
    } else {
      buffer.write(char.toLowerCase());
    }
  }
  return buffer.toString();
}
