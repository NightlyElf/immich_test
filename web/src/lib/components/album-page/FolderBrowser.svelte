<script lang="ts">
  import { goto } from '$app/navigation';
  import AlbumCard from '$lib/components/album-page/AlbumCard.svelte';
  import { Route } from '$lib/route';
  import { createAlbumAndRedirect } from '$lib/utils/album-utils';
  import { handleError } from '$lib/utils/handle-error';
  import { getAllAlbums, updateAlbumInfo, type AlbumResponseDto } from '@immich/sdk';
  import { Button, Text, toastManager } from '@immich/ui';
  import { mdiChevronRight, mdiFolderPlusOutline } from '@mdi/js';
  import { t } from 'svelte-i18n';

  type Props = {
    album: AlbumResponseDto;
    isOwner: boolean;
    /** called after this folder was moved so the page can refresh */
    onMoved?: (album: AlbumResponseDto) => void;
  };

  let { album, isOwner, onMoved }: Props = $props();

  let allAlbums = $state<AlbumResponseDto[]>([]);

  const byId = $derived(new Map(allAlbums.map((a) => [a.id, a])));
  const children = $derived(allAlbums.filter((a) => a.parentId === album.id));

  // ancestors, root first (stops where a parent is not visible to the user)
  const breadcrumbs = $derived.by(() => {
    const chain: AlbumResponseDto[] = [];
    const seen = new Set<string>([album.id]);
    let parentId = album.parentId;
    while (parentId && !seen.has(parentId)) {
      const parent = byId.get(parentId);
      if (!parent) {
        break;
      }
      seen.add(parent.id);
      chain.unshift(parent);
      parentId = parent.parentId;
    }
    return chain;
  });

  // folders this one can be moved into: not itself and not one of its own descendants
  const moveTargets = $derived.by(() => {
    const blocked = new Set<string>([album.id]);
    let added = true;
    while (added) {
      added = false;
      for (const a of allAlbums) {
        if (a.parentId && blocked.has(a.parentId) && !blocked.has(a.id)) {
          blocked.add(a.id);
          added = true;
        }
      }
    }
    return allAlbums.filter((a) => !blocked.has(a.id));
  });

  const load = async () => {
    try {
      allAlbums = await getAllAlbums({});
    } catch (error) {
      handleError(error, $t('errors.unable_to_load_albums'));
    }
  };

  $effect(() => {
    void album.id;
    void load();
  });

  const handleNewFolder = async () => {
    await createAlbumAndRedirect($t('new_folder'), undefined, album.id);
  };

  const handleMove = async (event: Event) => {
    const value = (event.currentTarget as HTMLSelectElement).value;
    const parentId = value === '' ? null : value;
    try {
      const updated = await updateAlbumInfo({ id: album.id, updateAlbumDto: { parentId } });
      toastManager.primary($t('folder_moved'));
      onMoved?.(updated);
      await load();
    } catch (error) {
      handleError(error, $t('errors.unable_to_move_folder'));
    }
  };
</script>

<section class="mt-2 mb-6" data-testid="folder-browser">
  <nav class="flex flex-wrap items-center gap-1 text-sm dark:text-immich-dark-fg" aria-label={$t('folders')}>
    <a href={Route.albums()} class="hover:underline">{$t('albums')}</a>
    {#each breadcrumbs as crumb (crumb.id)}
      <svg class="size-4 shrink-0" viewBox="0 0 24 24" aria-hidden="true"
        ><path d={mdiChevronRight} fill="currentColor" /></svg
      >
      <a href={Route.viewAlbum(crumb)} class="hover:underline">{crumb.albumName}</a>
    {/each}
  </nav>

  {#if isOwner}
    <div class="mt-3 flex flex-wrap items-center gap-3">
      <Button size="small" shape="round" leadingIcon={mdiFolderPlusOutline} onclick={handleNewFolder}>
        {$t('new_folder')}
      </Button>

      <label class="flex items-center gap-2 text-sm dark:text-immich-dark-fg">
        <span>{$t('move_to_folder')}</span>
        <select
          class="rounded-lg border bg-subtle px-2 py-1 dark:border-gray-700"
          value={album.parentId ?? ''}
          onchange={handleMove}
        >
          <option value="">{$t('top_level')}</option>
          {#each moveTargets as target (target.id)}
            <option value={target.id}>{target.albumName}</option>
          {/each}
        </select>
      </label>
    </div>
  {/if}

  {#if children.length > 0}
    <Text size="small" class="mt-6 mb-1 uppercase dark:text-immich-dark-fg">{$t('subfolders')}</Text>
    <div class="grid grid-cols-[repeat(auto-fill,minmax(10rem,1fr))] gap-2">
      {#each children as child (child.id)}
        <a
          href={Route.viewAlbum(child)}
          data-sveltekit-preload-data="hover"
          onclick={() => goto(Route.viewAlbum(child))}
        >
          <AlbumCard album={child} showItemCount />
        </a>
      {/each}
    </div>
  {/if}
</section>
