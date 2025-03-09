import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

// State
class FavoritingState {
  List<String> items;
  Set<String> favorites;

  FavoritingState({
    List<String>? items,
    Set<String>? favorites,
  })  : items = items ?? List.generate(20, (i) => 'Item $i'),
        favorites = favorites ?? {};

  @override
  String toString() => 'FavoritingState(items: $items, favorites: $favorites)';
}

// Actions
sealed class FavoritingAction {
  const FavoritingAction();
}

final class ToggleFavorite extends FavoritingAction {
  final String item;
  const ToggleFavorite(this.item);
}

final class ClearFavorites extends FavoritingAction {
  const ClearFavorites();
}

// Feature
class Favoriting {
  static final reducer =
      Reducer<FavoritingState, FavoritingAction>((state, action) {
    switch (action) {
      case ToggleFavorite(item: final item):
        if (state.favorites.contains(item)) {
          state.favorites.remove(item);
        } else {
          state.favorites.add(item);
        }
        return Effect.none();
      case ClearFavorites():
        state.favorites.clear();
        return Effect.none();
    }
  });

  // Action creators
  static FavoritingAction toggleFavorite(String item) => ToggleFavorite(item);
  static const clearFavorites = ClearFavorites();
}

// MARK: - Feature view

class FavoritingView extends StatelessWidget {
  final Store<FavoritingState, FavoritingAction> store;

  const FavoritingView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriting Demo'),
        actions: [
          IconButton(
            onPressed: () => store.send(Favoriting.clearFavorites),
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return ListView.builder(
            itemCount: store.state.items.length,
            itemBuilder: (context, index) {
              final item = store.state.items[index];
              final isFavorite = store.state.favorites.contains(item);

              return ListTile(
                title: Text(item),
                trailing: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () => store.send(Favoriting.toggleFavorite(item)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
