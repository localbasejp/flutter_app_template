import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../entities/sample/developer.dart';
import '../../../../entities/sample/timeline/post.dart';
import '../../../../repositories/firebase_auth/firebase_auth_repository.dart';
import '../../../../repositories/firestore/document_repository.dart';
import '../fetch_timeline.dart';
import '../fetch_timeline_post_count.dart';
import 'fetch_post.dart';

part 'update_post.g.dart';

@Riverpod(keepAlive: true)
UpdatePost updatePost(UpdatePostRef ref) {
  return UpdatePost(ref);
}

class UpdatePost {
  UpdatePost(this._ref);
  final UpdatePostRef _ref;

  Future<void> call({
    required Post oldPost,
    required String text,
  }) async {
    /// 自身のユーザIDを取得
    final userId = _ref.read(firebaseAuthRepositoryProvider).loggedInUserId;
    if (userId == null) {
      return;
    }

    /// 更新する投稿データを設定
    final postId = oldPost.postId;
    final newPost = oldPost.copyWith(text: text);

    /// サーバーへ保存する
    await _ref.read(documentRepositoryProvider).update(
          Developer.postDocPath(
            userId: userId,
            docId: postId,
          ),
          data: newPost.toUpdateDoc(),
        );

    /// 更新したことを反映
    _ref
      ..invalidate(
        fetchPostProvider(
          FetchPostArgs(postId: postId, userId: userId),
        ),
      )
      ..invalidate(fetchTimelineProvider)
      ..invalidate(fetchTimelinePostCountProvider);
  }
}
