import 'package:case_studies/01_gettingstarted_binding_basics.dart';
import 'package:case_studies/01_gettingstarted_binding_forms.dart';
import 'package:case_studies/01_gettingstarted_composition_two_counters.dart';
import 'package:case_studies/01_gettingstarted_counter.dart';
import 'package:case_studies/01_gettingstarted_focus_state.dart';
import 'package:case_studies/01_gettingstarted_shared_state.dart';
import 'package:case_studies/03_effects_basics.dart';
import 'package:case_studies/03_effects_cancellation.dart';
import 'package:case_studies/03_navigation_navigation_state.dart';
import 'package:case_studies/05_more_favoriting.dart';
import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  void _navigateToDemo<State, Action>(
    BuildContext context,
    Store<State, Action> store,
    Widget Function(Store<State, Action>) builder,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Demo(
          store: store,
          content: builder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case Studies')),
      body: ListView(
        children: [
          _buildGettingStartedSection(context),
          _buildSharedStateSection(context),
          _buildEffectsSection(context),
          _buildNavigationSection(context),
          _buildHigherOrderSection(context),
        ],
      ),
    );
  }

  Widget _buildGettingStartedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Getting Started',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: const Text('Basics'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: CounterState(),
              reducer: Counter.reducer,
            ),
            (store) => CounterDemoView(store: store),
          ),
        ),
        ListTile(
          title: const Text('Combining reducers'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: TwoCountersState(),
              reducer: TwoCounters.reducer,
            ),
            (store) => TwoCountersView(store: store),
          ),
        ),
        ListTile(
          title: const Text('Bindings'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: BindingBasicsState(),
              reducer: BindingBasics.reducer,
            ),
            (store) => BindingBasicsView(store: store),
          ),
        ),
        ListTile(
          title: const Text('Binding Forms'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: BindingFormState(),
              reducer: BindingForm.reducer,
            ),
            (store) => BindingFormView(store: store),
          ),
        ),
        ListTile(
          title: const Text('Focus State'),
          subtitle: const Text('Manage input focus with TCA'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: FocusFormState(),
              reducer: FocusForm.reducer,
            ),
            (store) => FocusFormView(store: store),
          ),
        ),
        // Add more getting started demos...
      ],
    );
  }

  Widget _buildSharedStateSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Shared State',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: const Text('Shared state'),
          subtitle: const Text('Pass data between child reducers'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: SharedStateState(),
              reducer: SharedState.reducer,
            ),
            (store) => SharedStateView(store: store),
          ),
        ),
      ],
    );
  }

  Widget _buildEffectsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Effects',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: const Text('Basics'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: EffectsBasicsState(),
              reducer: EffectsBasics.reducer,
            ),
            (store) => EffectsBasicsView(store: store),
          ),
        ),
        ListTile(
          title: const Text('Cancellation'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: EffectsCancellationState(),
              reducer: EffectsCancellation.reducer,
            ),
            (store) => EffectsCancellationView(store: store),
          ),
        ),
        // Add more effects demos...
      ],
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Navigation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: const Text('Navigation Stack'),
          subtitle: const Text('Present and dismiss sheets and alerts'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: NavigationStateState(),
              reducer: NavigationState.reducer,
            ),
            (store) => NavigationStateView(store: store),
          ),
        ),
      ],
    );
  }

  Widget _buildHigherOrderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Higher-Order Reducers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: const Text('Reusable favoriting'),
          subtitle: const Text('Reduce duplication in reducers'),
          onTap: () => _navigateToDemo(
            context,
            Store(
              initialState: FavoritingState(),
              reducer: Favoriting.reducer,
            ),
            (store) => FavoritingView(store: store),
          ),
        ),
      ],
    );
  }
}

/// This wrapper provides an "entry" point into an individual demo that can own a store.
class Demo<State, Action> extends StatelessWidget {
  final Store<State, Action> store;
  final Widget Function(Store<State, Action>) content;

  const Demo({
    super.key,
    required this.store,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return content(store);
  }
}
