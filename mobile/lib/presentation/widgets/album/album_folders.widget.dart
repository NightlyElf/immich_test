import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/providers/infrastructure/remote_album.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/widgets/common/immich_toast.dart';

/// Fixed heights so the timeline's scroll math can account for this sliver.
class AlbumFolders {
  static const double headerHeight = 56;
  static const double stripHeight = 116;

  const AlbumFolders._();

  /// Height of [AlbumFoldersSliver] for the given album, to be passed as `topSliverWidgetHeight`.
  static double heightFor(List<RemoteAlbum> albums, RemoteAlbum album) {
    final hasChildren = albums.any((a) => a.parentId == album.id);
    return headerHeight + (hasChildren ? stripHeight : 0);
  }
}

/// Breadcrumbs, a "new folder" action and the subfolders of [album], shown above the album's assets.
class AlbumFoldersSliver extends ConsumerWidget {
  final RemoteAlbum album;
  final bool canCreate;

  const AlbumFoldersSliver({super.key, required this.album, required this.canCreate});

  List<RemoteAlbum> _breadcrumbs(List<RemoteAlbum> albums) {
    final byId = {for (final a in albums) a.id: a};
    final chain = <RemoteAlbum>[];
    final seen = <String>{album.id};
    var parentId = album.parentId;
    while (parentId != null && !seen.contains(parentId)) {
      final parent = byId[parentId];
      if (parent == null) {
        break;
      }
      seen.add(parent.id);
      chain.insert(0, parent);
      parentId = parent.parentId;
    }
    return chain;
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    try {
      final created = await ref
          .read(remoteAlbumProvider.notifier)
          .createAlbum(title: context.t.new_folder, parentId: album.id);
      if (created != null && context.mounted) {
        unawaited(context.router.push(RemoteAlbumRoute(album: created)));
      }
    } catch (_) {
      if (context.mounted) {
        ImmichToast.show(context: context, msg: context.t.errors.failed_to_create_album, toastType: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(remoteAlbumProvider.select((state) => state.albums));
    final children = albums.where((a) => a.parentId == album.id).toList();
    final breadcrumbs = _breadcrumbs(albums);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: AlbumFolders.headerHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _Crumb(label: context.t.albums, onTap: () => context.router.push(const AlbumsRoute())),
                          for (final crumb in breadcrumbs) ...[
                            const Icon(Icons.chevron_right_rounded, size: 18),
                            _Crumb(
                              label: crumb.name,
                              onTap: () => context.router.push(RemoteAlbumRoute(album: crumb)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (canCreate)
                    TextButton.icon(
                      onPressed: () => _createFolder(context, ref),
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: Text(context.t.new_folder),
                    ),
                ],
              ),
            ),
          ),
          if (children.isNotEmpty)
            SizedBox(
              height: AlbumFolders.stripHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: children.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final child = children[index];
                  return _FolderTile(
                    album: child,
                    onTap: () => context.router.push(RemoteAlbumRoute(album: child)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Crumb({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(label, style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.primary)),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final RemoteAlbum album;
  final VoidCallback onTap;

  const _FolderTile({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.folder_rounded, size: 36, color: context.colorScheme.primary),
            Text(album.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium),
            Text(
              '${album.assetCount}',
              style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
