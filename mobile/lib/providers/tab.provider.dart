import 'package:hooks_riverpod/hooks_riverpod.dart';

enum TabEnum { albums, search, library }

/// Provides the currently active tab
final tabProvider = StateProvider<TabEnum>((ref) => TabEnum.albums);
