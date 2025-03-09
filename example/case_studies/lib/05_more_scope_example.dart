import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Parent Feature Domain

class TodoListState {
  List<Todo> todos;
  CompletedCounterState counter;

  TodoListState({
    List<Todo>? todos,
    CompletedCounterState? counter,
  })  : todos = todos ?? [],
        counter = counter ?? CompletedCounterState();

  @override
  String toString() => 'TodoListState(todos: $todos, counter: $counter)';
}

class Todo {
  String title;
  bool isCompleted;

  Todo({required this.title, this.isCompleted = false});

  @override
  String toString() => 'Todo(title: $title, isCompleted: $isCompleted)';
}

sealed class TodoListAction {
  const TodoListAction();
}

class AddTodo extends TodoListAction {
  final String title;
  const AddTodo(this.title);
}

class ToggleTodo extends TodoListAction {
  final int index;
  const ToggleTodo(this.index);
}

class CounterAction extends TodoListAction {
  final CompletedCounterAction action;
  const CounterAction(this.action);
}

// MARK: - Child Feature Domain (Counter)

class CompletedCounterState {
  int count;
  CompletedCounterState({this.count = 0});

  @override
  String toString() => 'CompletedCounterState(count: $count)';
}

sealed class CompletedCounterAction {
  const CompletedCounterAction();
}

class IncrementCompleted extends CompletedCounterAction {
  const IncrementCompleted();
}

class DecrementCompleted extends CompletedCounterAction {
  const DecrementCompleted();
}

// MARK: - Features Implementation

class TodoList {
  static final counterReducer =
      Reducer<CompletedCounterState, CompletedCounterAction>(
    (state, action) {
      switch (action) {
        case IncrementCompleted():
          state.count++;
          return Effect.none();
        case DecrementCompleted():
          state.count--;
          return Effect.none();
      }
    },
  );

  static final reducer =
      Reducer<TodoListState, TodoListAction>((state, action) {
    switch (action) {
      case AddTodo(title: final title):
        state.todos.add(Todo(title: title));
        return Effect.none();

      case ToggleTodo(index: final index):
        if (index >= 0 && index < state.todos.length) {
          final todo = state.todos[index];
          final wasCompleted = todo.isCompleted;
          todo.isCompleted = !wasCompleted;

          // Send counter action based on completion state
          return Effect.send(CounterAction(
            wasCompleted
                ? const DecrementCompleted()
                : const IncrementCompleted(),
          ));
        }
        return Effect.none();

      case CounterAction(action: final counterAction):
        return Reducer.pullback<TodoListState, TodoListAction,
            CompletedCounterState, CompletedCounterAction>(
          child: counterReducer,
          toChildState: (state) => state.counter,
          fromChildState: (state, childState) => state.counter = childState,
          toChildAction: (action) => switch (action) {
            CounterAction(action: final action) => action,
            _ => null,
          },
        ).reduce(state, action).effect;
    }
  });
}

// MARK: - Feature View

class TodoListView extends StatelessWidget {
  final Store<TodoListState, TodoListAction> store;
  final _textController = TextEditingController();

  TodoListView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List with Counter'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Completed: ${store.state.counter.count}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Add a new todo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      store.send(AddTodo(_textController.text));
                      _textController.clear();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) => ListView.builder(
                itemCount: store.state.todos.length,
                itemBuilder: (context, index) {
                  final todo = store.state.todos[index];
                  return ListTile(
                    leading: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (_) => store.send(ToggleTodo(index)),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
