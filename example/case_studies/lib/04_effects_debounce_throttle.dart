import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

// State
class DebounceThrottleState {
  String searchQuery;
  List<String> searchResults;
  bool isSearching;
  int throttledCount;
  int debouncedCount;

  DebounceThrottleState({
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
    this.throttledCount = 0,
    this.debouncedCount = 0,
  });

  @override
  String toString() =>
      'DebounceThrottleState(searchQuery: $searchQuery, searchResults: $searchResults, isSearching: $isSearching, throttledCount: $throttledCount, debouncedCount: $debouncedCount)';
}

// Actions
sealed class DebounceThrottleAction {
  const DebounceThrottleAction();
}

// Cancel IDs for effects
enum CancelID {
  search,
  debounce,
  throttle,
}

final class SearchQueryChanged extends DebounceThrottleAction {
  final String query;
  const SearchQueryChanged(this.query);
}

final class SearchResponse extends DebounceThrottleAction {
  final List<String> results;
  const SearchResponse(this.results);
}

final class ThrottleButtonTapped extends DebounceThrottleAction {
  const ThrottleButtonTapped();
}

final class ThrottledAction extends DebounceThrottleAction {
  const ThrottledAction();
}

final class DebounceButtonTapped extends DebounceThrottleAction {
  const DebounceButtonTapped();
}

final class DebouncedAction extends DebounceThrottleAction {
  const DebouncedAction();
}

// Feature
class DebounceThrottle {
  static final reducer =
      Reducer<DebounceThrottleState, DebounceThrottleAction>((state, action) {
    switch (action) {
      case SearchQueryChanged(query: final query):
        state.searchQuery = query;

        // If the query is empty, clear results and don't perform a search
        if (query.isEmpty) {
          state.searchResults = [];
          state.isSearching = false;
          return Effect.cancel(CancelID.search);
        }

        state.isSearching = true;

        // Debounce the search request to avoid making too many API calls
        return Effect.publisher<DebounceThrottleAction>((send) async {
          // Simulate debouncing by waiting before executing the search
          await Future.delayed(const Duration(milliseconds: 300));

          // Simulate a search API call
          await Future.delayed(const Duration(milliseconds: 500));

          // Generate mock results
          final results = List.generate(
            5,
            (index) => '${query.toUpperCase()} result ${index + 1}',
          );

          send(SearchResponse(results));
        }).cancellable(id: CancelID.search);

      case SearchResponse(results: final results):
        state.searchResults = results;
        state.isSearching = false;
        return Effect.none();

      case ThrottleButtonTapped():
        // Throttle the action - only allow it to execute at most once every 1 second
        return Effect.publisher<DebounceThrottleAction>((send) async {
          send(const ThrottledAction());

          // Keep the effect alive for the throttle duration to prevent
          // additional actions from being processed
          await Future.delayed(const Duration(seconds: 1));
        }).cancellable(id: CancelID.throttle);

      case ThrottledAction():
        state.throttledCount++;
        return Effect.none();

      case DebounceButtonTapped():
        // Cancel any pending debounced action and start a new one
        return Effect.publisher<DebounceThrottleAction>((send) async {
          // Wait for the debounce period
          await Future.delayed(const Duration(milliseconds: 500));

          // Send the debounced action
          send(const DebouncedAction());
        }).cancellable(id: CancelID.debounce);

      case DebouncedAction():
        state.debouncedCount++;
        return Effect.none();
    }
  });

  // Action creators
  static const throttleButtonTapped = ThrottleButtonTapped();
  static const debounceButtonTapped = DebounceButtonTapped();
}

// MARK: - Feature view

class DebounceThrottleView extends StatelessWidget {
  final Store<DebounceThrottleState, DebounceThrottleAction> store;

  const DebounceThrottleView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debounce & Throttle Demo')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debounced Search',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    hintText: 'Enter search term...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: store.state.isSearching
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    store.send(SearchQueryChanged(value));
                  },
                ),
                const SizedBox(height: 16),
                if (store.state.searchResults.isNotEmpty) ...[
                  const Text('Results:'),
                  const SizedBox(height: 8),
                  ...store.state.searchResults.map((result) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(result),
                      )),
                ],
                const Divider(height: 32),
                const Text(
                  'Throttle vs Debounce',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Throttled: ${store.state.throttledCount}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () =>
                              store.send(DebounceThrottle.throttleButtonTapped),
                          child: const Text('Throttle Button'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Limits frequency\nto once per second',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Debounced: ${store.state.debouncedCount}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () =>
                              store.send(DebounceThrottle.debounceButtonTapped),
                          child: const Text('Debounce Button'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Waits until activity stops\nfor 500ms before triggering',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
