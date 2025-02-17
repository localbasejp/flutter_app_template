import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../entities/sample/developer.dart';
import '../../../../entities/sample/timeline/post.dart';
import '../../../../repositories/firebase_auth/firebase_auth_repository.dart';
import '../../../../repositories/firestore/document.dart';
import '../../../../repositories/firestore/document_repository.dart';
import '../fetch_timeline.dart';
import '../fetch_timeline_post_count.dart';

part 'create_post.g.dart';

@Riverpod(keepAlive: true)
CreatePost createPost(CreatePostRef ref) {
  return CreatePost(ref);
}

class CreatePost {
  CreatePost(this._ref);
  final CreatePostRef _ref;

  Future<void> call({
    required String text,
  }) async {
    /// 自身のユーザIDを取得
    final userId = _ref.read(firebaseAuthRepositoryProvider).loggedInUserId;
    if (userId == null) {
      return;
    }

    /// 保存する投稿データを設定
    final postId = Document.docId(Post.collectionName);
    final post = Post(
      postId: postId,
      userId: userId,
      text: text,
    );

    /// サーバーへ保存する
    await _ref.read(documentRepositoryProvider).save(
          Developer.postDocPath(
            userId: userId,
            docId: postId,
          ),
          data: post.toCreateDoc(),
        );

    /// 作成したことを反映
    _ref
      ..invalidate(fetchTimelineProvider)
      ..invalidate(fetchTimelinePostCountProvider);
  }
}
