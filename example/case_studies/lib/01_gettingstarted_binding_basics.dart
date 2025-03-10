import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

// State
class BindingBasicsState {
  String text;
  bool toggle;
  double sliderValue;
  int stepCount;

  BindingBasicsState({
    this.text = '',
    this.toggle = false,
    this.sliderValue = 0.5,
    this.stepCount = 0,
  });

  @override
  String toString() =>
      'BindingBasicsState(text: $text, toggle: $toggle, sliderValue: $sliderValue, stepCount: $stepCount)';
}

// Actions
sealed class BindingBasicsAction {
  const BindingBasicsAction();
}

final class TextChanged extends BindingBasicsAction {
  final String text;
  const TextChanged(this.text);
}

final class ToggleChanged extends BindingBasicsAction {
  final bool value;
  const ToggleChanged(this.value);
}

final class SliderChanged extends BindingBasicsAction {
  final double value;
  const SliderChanged(this.value);
}

final class StepperIncrement extends BindingBasicsAction {
  const StepperIncrement();
}

final class StepperDecrement extends BindingBasicsAction {
  const StepperDecrement();
}

// Feature
class BindingBasics {
  static final reducer =
      Reducer<BindingBasicsState, BindingBasicsAction>((state, action) {
    switch (action) {
      case TextChanged(text: final text):
        state.text = text;
        return Effect.none();
      case ToggleChanged(value: final value):
        state.toggle = value;
        return Effect.none();
      case SliderChanged(value: final value):
        state.sliderValue = value;
        return Effect.none();
      case StepperIncrement():
        state.stepCount++;
        return Effect.none();
      case StepperDecrement():
        state.stepCount--;
        return Effect.none();
    }
  });

  // Action creators
  static BindingBasicsAction textChanged(String text) => TextChanged(text);
  static BindingBasicsAction toggleChanged(bool value) => ToggleChanged(value);
  static BindingBasicsAction sliderChanged(double value) =>
      SliderChanged(value);
  static const stepperIncrement = StepperIncrement();
  static const stepperDecrement = StepperDecrement();
}

// MARK: - Feature view

class BindingBasicsView extends StatelessWidget {
  final Store<BindingBasicsState, BindingBasicsAction> store;

  const BindingBasicsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bindings Demo')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                onChanged: (value) =>
                    store.send(BindingBasics.textChanged(value)),
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: store.state.text),
              ),
              Text('Text: ${store.state.text}'),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Toggle: ${store.state.toggle}'),
                value: store.state.toggle,
                onChanged: (value) =>
                    store.send(BindingBasics.toggleChanged(value)),
              ),
              const SizedBox(height: 16),
              Text('Slider: ${store.state.sliderValue.toStringAsFixed(2)}'),
              Slider(
                value: store.state.sliderValue,
                onChanged: (value) =>
                    store.send(BindingBasics.sliderChanged(value)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () => store.send(BindingBasics.stepperDecrement),
                    child: const Text('-'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${store.state.stepCount}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  FilledButton(
                    onPressed: () => store.send(BindingBasics.stepperIncrement),
                    child: const Text('+'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
