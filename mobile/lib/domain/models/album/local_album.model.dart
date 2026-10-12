import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_album.model.freezed.dart';

enum BackupSelection {
  // Used to sort albums based on the backupSelection
  // selected -> none -> excluded
  // Do not change the order of these values
  selected,
  none,
  excluded,
}

@freezed
abstract class LocalAlbum with _$LocalAlbum {
  const factory LocalAlbum({
    required String id,
    required String name,
    required DateTime updatedAt,
    @Default(0) int assetCount,
    @Default(BackupSelection.none) BackupSelection backupSelection,
    @Default(false) bool isIosSharedAlbum,
    String? linkedRemoteAlbumId,
  }) = _LocalAlbum;
}

/// Ids and names of the device-wide "all photos" album ("Recent"/"Recents"). It contains the whole gallery, so it is
/// never offered for backup: only real folders chosen by the user are backed up.
const String kAllPhotosAlbumId = 'isAll';
const List<String> kAllPhotosAlbumNames = ['Recent', 'Recents'];

extension LocalAlbumAllPhotos on LocalAlbum {
  bool get isAllPhotos => id == kAllPhotosAlbumId || kAllPhotosAlbumNames.contains(name);
}
