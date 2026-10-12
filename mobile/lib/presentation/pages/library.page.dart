import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/widgets/images/local_album_thumbnail.widget.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/server_info.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/widgets/common/immich_sliver_app_bar.dart';

@RoutePage()
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomScrollView(
        slivers: [
          ImmichSliverAppBar(snap: false, floating: false, pinned: true, showUploadButton: false),
          _ActionButtonGrid(),
          _CollectionCards(),
          _QuickAccessButtonList(),
        ],
      ),
    );
  }
}

class _ActionButtonGrid extends ConsumerWidget {
  const _ActionButtonGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTrashEnable = ref.watch(serverInfoProvider.select((state) => state.serverFeatures.trash));

    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            Row(
              children: [
                _ActionButton(
                  icon: Icons.favorite_outline_rounded,
                  onTap: () => context.pushRoute(const FavoriteRoute()),
                  label: context.t.favorites,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.archive_outlined,
                  onTap: () => context.pushRoute(const ArchiveRoute()),
                  label: context.t.archived,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ActionButton(
                  icon: Icons.link_outlined,
                  onTap: () => context.pushRoute(const SharedLinkRoute()),
                  label: context.t.shared_links,
                ),
                isTrashEnable ? const SizedBox(width: 8) : const SizedBox.shrink(),
                isTrashEnable
                    ? _ActionButton(
                        icon: Icons.delete_outline_rounded,
                        onTap: () => context.pushRoute(const TrashRoute()),
                        label: context.t.trash,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap, required this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton.icon(
        onPressed: onTap,
        label: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(label, style: TextStyle(color: context.colorScheme.onSurface, fontSize: 15)),
        ),
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          backgroundColor: context.colorScheme.surfaceContainerLow,
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            side: BorderSide(color: context.colorScheme.onSurface.withAlpha(10), width: 1),
          ),
        ),
        icon: Icon(icon, color: context.primaryColor),
      ),
    );
  }
}

class _CollectionCards extends StatelessWidget {
  const _CollectionCards();

  @override
  Widget build(BuildContext context) {
    return const SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LocalAlbumsCollectionCard(),
          ],
        ),
      ),
    );
  }
}

class _LocalAlbumsCollectionCard extends ConsumerWidget {
  const _LocalAlbumsCollectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(localAlbumProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final widthFactor = isTablet ? 0.25 : 0.5;
        final size = context.width * widthFactor - 20.0;

        return GestureDetector(
          onTap: () => context.pushRoute(const LocalAlbumsRoute()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: size,
                width: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [context.colorScheme.primary.withAlpha(30), context.colorScheme.primary.withAlpha(25)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(12),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: albums.when(
                      data: (data) {
                        return data.take(4).map((album) {
                          return LocalAlbumThumbnail(albumId: album.id);
                        }).toList();
                      },
                      error: (error, _) {
                        return [Center(child: Text(context.t.error_saving_image(error: error.toString())))];
                      },
                      loading: () {
                        return [const Center(child: CircularProgressIndicator())];
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  context.t.on_this_device,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAccessButtonList extends StatelessWidget {
  const _QuickAccessButtonList();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 32),
      sliver: SliverToBoxAdapter(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: context.colorScheme.onSurface.withAlpha(10), width: 1),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            gradient: LinearGradient(
              colors: [
                context.colorScheme.primary.withAlpha(10),
                context.colorScheme.primary.withAlpha(15),
                context.colorScheme.primary.withAlpha(20),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListTile(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            leading: const Icon(Icons.lock_outline_rounded, size: 26),
            title: Text(
              context.t.locked_folder,
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            onTap: () => context.pushRoute(const LockedFolderRoute()),
          ),
        ),
      ),
    );
  }
}

