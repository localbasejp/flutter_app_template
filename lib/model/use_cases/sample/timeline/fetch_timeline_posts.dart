import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/entities/sample/timeline/post.dart';
import '../../../../model/use_cases/sample/timeline/post_operation_observer.dart';
import '../../../repositories/firestore/collection_paging_repository.dart';
import '../../../repositories/firestore/document.dart';

/// 投稿のタイムラインを取得
final fetchTimelinePostsAsyncProvider =
    AsyncNotifierProvider.autoDispose<FetchTimelinePosts, List<Post>>(
  FetchTimelinePosts.new,
);

class FetchTimelinePosts extends AutoDisposeAsyncNotifier<List<Post>> {
  late final CollectionPagingRepository<Post> _collectionPagingRepository;

  late final StreamSubscription<OperationData> _observerDisposer;

  @override
  FutureOr<List<Post>> build() async {
    /// クエリを設定したRepositoryを設定
    _collectionPagingRepository = ref.read(
      postCollectionPagingProvider(
        CollectionParam<Post>(
          query: Document.colRef(
            Post.collectionPath,
          ).orderBy('createdAt', descending: true),
          limit: 20,
          decode: Post.fromJson,
        ),
      ),
    );

    /// 投稿一覧を取得する
    final data = await _collectionPagingRepository.fetch(
      fromCache: (cache) async {
        /// キャッシュから取得して即時反映
        if (cache.isNotEmpty) {
          state = AsyncData(
            cache.map((e) => e.entity).whereType<Post>().toList(),
          );
        }
      },
    );

    /// 自身が投稿した情報を監視してstateに反映する
    _observerDisposer = ref.read(postOperationObserverProvider).listen((value) {
      final list = state.value ?? [];
      final target = value.post;
      if (value.type == OperationType.create) {
        /// 追加する
        state = AsyncData(
          [
            target,
            ...list,
          ],
        );
      } else if (value.type == OperationType.update) {
        /// 更新する
        state = AsyncData(
          list
              .map(
                (element) => element.postId == target.postId ? target : element,
              )
              .toList(),
        );
      } else if (value.type == OperationType.delete) {
        /// 削除する
        state = AsyncData(
          list.where((element) => element.postId != target.postId).toList(),
        );
      }
    });

    /// 破棄されたらobserverも破棄する
    ref.onDispose(() async {
      await _observerDisposer.cancel();
    });

    return data.map((e) => e.entity).whereType<Post>().toList();
  }

  /// 次ページの一覧を取得する
  Future<void> fetchMore() async {
    final data = await _collectionPagingRepository.fetchMore();
    final list = state.value ?? [];
    state = AsyncData(
      [
        ...list,
        ...data.map((e) => e.entity).whereType<Post>(),
      ],
    );
  }
}
