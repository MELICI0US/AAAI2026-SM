import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';

import 'package:jhg_core/jhg_core.dart';

class StorageNotifierMock extends StateNotifier<StorageStatus>
    implements StorageNotifier {
  StorageNotifierMock(super.state);

  @override
  Future<void> clear() {
    return Future.value();
  }

  @override
  Future<void> initialized(Box<int> box) {
    return Future.value();
  }
}
