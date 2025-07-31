import 'package:riverpod/riverpod.dart';

import 'package:jhg_core/jhg_core.dart';
import 'mocks/persistence.dart';
import 'mocks/storage_notifier.dart';

final persistenceTestOverrides = [
  persistenceVersionProvider.overrideWith((ref) => MockBox({})),
  roundInfoBoxProvider.overrideWith((ref) => MockPersistentMapNotifier({})),
  gameInfoBoxProvider.overrideWith((ref) => MockPersistentMapNotifier({})),
  lobbyInfoBoxProvider.overrideWith((ref) => MockPersistentValueNotifier()),
  // ignore: deprecated_member_use
  conversationNotificationStateProvider.overrideWithProvider(
      StateNotifierProvider.autoDispose<MockChatNotificationStateNotifier,
              AsyncValue<Map<String, ChatNotificationState>>>(
          MockChatNotificationStateNotifier.new)),
  featureFlagsProvider.overrideWith((ref) =>
      MockPersistentValueNotifier(const FeatureFlags(enableMultiplayer: true))),
  clearStorageProvider
      .overrideWith((ref) => StorageNotifierMock(StorageStatus.loaded))
];
