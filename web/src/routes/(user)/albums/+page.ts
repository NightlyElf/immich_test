import { getAllAlbums } from '@immich/sdk';
import { authenticate } from '$lib/utils/auth';
import { getFormatter } from '$lib/utils/i18n';
import type { PageLoad } from './$types';

export const load = (async ({ url }) => {
  await authenticate(url);
  const allSharedAlbums = await getAllAlbums({ isShared: true });
  const allAlbums = await getAllAlbums({ isOwned: true });
  const $t = await getFormatter();

  // Folders: only show top-level ones here. A folder whose parent isn't visible to the user is treated as top-level.
  const visibleIds = new Set([...allAlbums, ...allSharedAlbums].map(({ id }) => id));
  const isTopLevel = ({ parentId }: { parentId: string | null }) => !parentId || !visibleIds.has(parentId);
  const albums = allAlbums.filter((album) => isTopLevel(album));
  const sharedAlbums = allSharedAlbums.filter((album) => isTopLevel(album));

  return {
    albums,
    sharedAlbums,
    meta: {
      title: $t('albums'),
    },
  };
}) satisfies PageLoad;
