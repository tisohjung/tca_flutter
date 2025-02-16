sealed class FavoritesAction {
  const FavoritesAction();
}

final class FavoritesAddAction extends FavoritesAction {
  final int number;
  const FavoritesAddAction(this.number);
}

final class FavoritesRemoveAction extends FavoritesAction {
  final int number;
  const FavoritesRemoveAction(this.number);
}
