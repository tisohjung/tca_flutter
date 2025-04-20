import 'package:dart_custom_dump_test/dart_custom_dump_test.dart';
import 'package:test/test.dart';

class Counter {
  int count;
  bool isOdd;

  Counter({this.count = 0, this.isOdd = false});

  void increment() {
    count++;
    isOdd = !isOdd;
  }

  Counter copy() => Counter(count: count, isOdd: isOdd);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Counter &&
          runtimeType == other.runtimeType &&
          count == other.count &&
          isOdd == other.isOdd;

  @override
  int get hashCode => count.hashCode ^ isOdd.hashCode;

  @override
  String toString() => 'Counter(count: $count, isOdd: $isOdd)';
}

void main() {
  group('expectNoDifference', () {
    test('passes when values are equal', () {
      expectNoDifference(1, 1);
      expectNoDifference('hello', 'hello');
      expectNoDifference([1, 2, 3], [1, 2, 3]);
      expectNoDifference({'a': 1}, {'a': 1});
    });

    test('fails with detailed diff when values are different', () {
      expect(
        () => expectNoDifference(1, 2),
        throwsA(
          predicate(
            (e) =>
                e is TestFailure &&
                e.message?.contains('Expected values to be equal') == true &&
                e.message?.contains('- 1') == true &&
                e.message?.contains('+ 2') == true,
          ),
        ),
      );
    });

    test('includes reason in failure message', () {
      expect(
        () => expectNoDifference(1, 2, reason: 'Test reason'),
        throwsA(
          predicate(
            (e) =>
                e is TestFailure &&
                e.message?.contains('Test reason') == true &&
                e.message?.contains('Expected values to be equal') == true,
          ),
        ),
      );
    });
  });

  group('expectDifference', () {
    test('passes when value changes as expected', () {
      final counter = Counter();
      final expected = Counter(count: 1, isOdd: true);
      expectDifference(counter.copy(), () {
        counter.increment();
        return counter;
      }, changes: (counter) => expected);
    });

    test('fails when value does not change', () {
      final counter = Counter();
      expect(
        () => expectDifference(
          counter.copy(),
          () => counter,
          changes: (counter) => Counter(count: 1),
        ),
        throwsA(
          predicate(
            (e) =>
                e is TestFailure &&
                e.message?.contains('Expected values to be different') == true,
          ),
        ),
      );
    });

    test('fails when value changes unexpectedly', () {
      final counter = Counter();
      expect(
        () => expectDifference(counter.copy(), () {
          counter.increment();
          counter.increment(); // Extra increment
          return counter;
        }, changes: (counter) => Counter(count: 1, isOdd: true)),
        throwsA(
          predicate(
            (e) =>
                e is TestFailure &&
                e.message?.contains('Unexpected difference') == true &&
                e.message?.contains('count') == true,
          ),
        ),
      );
    });

    test('includes reason in failure message', () {
      final counter = Counter();
      final modified = counter.copy()..increment();
      expect(
        () => expectDifference(
          counter.copy(),
          () => counter,
          changes: (counter) => modified,
          reason: 'Test reason',
        ),
        throwsA(
          predicate(
            (e) =>
                e is TestFailure &&
                e.message?.contains('Test reason') == true &&
                e.message?.contains('Expected values to be different') == true,
          ),
        ),
      );
    });
  });
}
