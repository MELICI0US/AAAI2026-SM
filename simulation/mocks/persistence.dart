// ignore_for_file: avoid_as

import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import 'package:jhg_core/jhg_core.dart';

class MockBox<T> extends Mock implements Box<T> {
  MockBox(this._values);
  @override
  T? get(dynamic key, {T? defaultValue}) => _values[key];

  @override
  Future<T?> put(dynamic key, T value) async => _values[key as String] = value;
  final Map<String, T> _values;
}

class MockPersistentValueNotifier<T> extends StateNotifier<AsyncValue<T>>
    implements PersistentValueNotifier<T> {
  MockPersistentValueNotifier([T? initialValue])
      : super(initialValue == null
            ? const AsyncValue.loading()
            : AsyncValue.data(initialValue));

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  bool get isOpen => true;

  @override
  Future<void> setValue(T value, {bool update = false}) async {
    state = AsyncValue.data(value);
  }

  @override
  Future<void> updateValue(T Function(T p1) update) async {
    state = AsyncValue.data(update(state.value as T));
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }
}

class MockPersistentMapNotifier<T>
    extends StateNotifier<AsyncValue<Map<String, T>>>
    implements PersistentMapNotifier<T> {
  MockPersistentMapNotifier(this._values)
      : super(AsyncValue<Map<String, T>>.loading());

  @override
  Future<void> put(dynamic key, T value) async {
    if (!_values.containsKey(key)) {
      _values[key as String] = value;
      state = AsyncValue.data(_values);
    }
  }

  final Map<String, T> _values;

  @override
  Future<void> clear() async {
    _values.clear();
    state = AsyncValue.data(_values);
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
    state = AsyncValue.data(_values);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  bool get isOpen => true;

  @override
  Future<void> update(String key, T value) async {
    _values[key] = value;
    state = AsyncValue.data(_values);
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }
}

class MockChatNotificationStateNotifier
    extends MockPersistentMapNotifier<ChatNotificationState>
    implements ChatNotificationStateNotifier {
  MockChatNotificationStateNotifier(this.ref) : super({});
  @override
  final AutoDisposeStateNotifierProviderRef<MockChatNotificationStateNotifier,
      AsyncValue<Map<String, ChatNotificationState>>> ref;

  @override
  Future<void> startListening() async {
    ref.listen<AsyncValue<List<Conversation>>>(conversationsProvider,
        (old, current) {
      if (old != null) {
        if (current.hasValue && old.hasValue) {
          final oldConversations = old.value!;
          final currentConversations = current.value!;
          for (final conversation in currentConversations) {
            if (!oldConversations
                .any((c) => c.conversationId == conversation.conversationId)) {
              put(currentConversations.last.conversationId,
                  const ChatNotificationState(lastMessageRead: -1));
            }
          }
        }
      }
    });
  }

  @override
  Future<void> acknowledgeMessage(String conversationId, int message) async {
    await update(
        conversationId, ChatNotificationState(lastMessageRead: message));
  }
}
