import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../utils/logger.dart';
import '../../../entities/sample/developer.dart';
import '../../../repositories/firebase_auth/firebase_auth_repository.dart';
import '../../../repositories/firestore/document_repository.dart';
import '../auth/auth_state_controller.dart';

part 'fetch_my_profile.g.dart';

@riverpod
class FetchMyProfile extends _$FetchMyProfile {
  @override
  Stream<Developer?> build() {
    final authState = ref.watch(authStateControllerProvider);
    if (authState == AuthState.noSignIn) {
      return Stream.value(null);
    }
    final userId = ref.watch(firebaseAuthRepositoryProvider).loggedInUserId;
    if (userId == null) {
      return Stream.value(null);
    }
    logger.info('userId: $userId');
    return ref
        .watch(documentRepositoryProvider)
        .snapshots(Developer.docPath(userId))
        .map((event) {
      final data = event.data();
      return data != null ? Developer.fromJson(data) : null;
    });
  }
}
