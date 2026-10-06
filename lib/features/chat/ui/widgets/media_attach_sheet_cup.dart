import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class const MediaAttachSheetCup({super.key}) extends StatefulWidget {
  static Future<List<AssetEntity>?> show(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    return showCupertinoModalPopup<List<AssetEntity>>(
      context: context,
      builder: (sheetContext) => BlocProvider<ChatCubit>.value(
        value: cubit,
        child: Container(
          height: MediaQuery.sizeOf(sheetContext).height * 0.7,
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(
              sheetContext,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey2.resolveFrom(
                      sheetContext,
                    ),
                    borderRadius: .circular(2.5),
                  ),
                ),
                const Expanded(child: MediaAttachSheetCup()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<MediaAttachSheetCup> createState() => _MediaAttachSheetCupState();
}

class _MediaAttachSheetCupState() extends State<MediaAttachSheetCup> {
  PermissionState? _permission;
  AssetPathEntity? _album;
  List<AssetEntity> _assets = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  final Set<String> _selected = {};

  static const _pageSize = 90;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (_scroll.offset >= max - 600) _loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ps = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;
      setState(() => _permission = ps);
      if (!ps.hasAccess) {
        setState(() {
          _loading = false;
          _assets = const [];
        });
        return;
      }
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: [const OrderOption(type: OrderOptionType.createDate)],
        ),
      );
      if (!mounted) return;
      if (albums.isEmpty) {
        setState(() {
          _loading = false;
          _assets = const [];
        });
        return;
      }
      _album = albums.first;
      final assets = await _album!.getAssetListPaged(page: 0, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _assets = assets;
        _hasMore = assets.length >= _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить галерею';
      });
    }
  }

  Future<void> _loadMore() async {
    final album = _album;
    if (album == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = _assets.length ~/ _pageSize;
      final next = await album.getAssetListPaged(page: page, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _assets = [..._assets, ...next];
        _hasMore = next.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _pickFiles() async {
    await context.read<ChatCubit>().pickFiles();
    if (mounted) Navigator.of(context).pop(<AssetEntity>[]);
  }

  void _toggle(AssetEntity asset) {
    setState(() {
      if (!_selected.remove(asset.id)) {
        _selected.add(asset.id);
      }
    });
  }

  void _confirm() {
    final picked = _assets
        .where((a) => _selected.contains(a.id))
        .toList(growable: false);
    Navigator.of(context).pop(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(child: _buildBody(context)),
        _buildBottomPanel(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Text(
            'Фото и видео',
            style: TextStyle(
              fontSize: 17,
              fontWeight: .w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const Spacer(),
          if (_selected.isNotEmpty) ...[
            Text(
              '${_selected.length}',
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _confirm,
              child: const Icon(CupertinoIcons.check_mark_circled_solid),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error != null) {
      return _Message(text: _error!, actionLabel: 'Повторить', onAction: _load);
    }
    if (_permission != null && !_permission!.hasAccess) {
      return _Message(
        text: _permission == .denied
            ? 'Нет доступа к галерее'
            : 'Доступ к галерее ограничен',
        actionLabel: 'Открыть настройки',
        onAction: PhotoManager.openSetting,
      );
    }
    if (_assets.isEmpty) {
      return const _Message(text: 'В галерее пока пусто');
    }
    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: _assets.length + (_loadingMore ? 3 : 0),
      itemBuilder: (context, index) {
        if (index >= _assets.length) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final asset = _assets[index];
        return _GalleryTile(
          asset: asset,
          selected: _selected.contains(asset.id),
          onTap: () => _toggle(asset),
        );
      },
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Center(
        child: CupertinoButton.filled(
          onPressed: _pickFiles,
          child: const Row(
            mainAxisSize: .min,
            children: [
              Icon(CupertinoIcons.folder_open),
              SizedBox(width: 8),
              Text('Файл'),
            ],
          ),
        ),
      ),
    );
  }
}

class const _GalleryTile({
  required final AssetEntity asset,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final blue = CupertinoColors.activeBlue.resolveFrom(context);
    final isVideo = asset.type == .video;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: .circular(12),
        child: Stack(
          fit: .expand,
          children: [
            AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(300),
              thumbnailFormat: .jpeg,
              fit: .cover,
            ),
            if (isVideo)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: .circular(8),
                  ),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      const Icon(
                        CupertinoIcons.play_fill,
                        size: 14,
                        color: Color(0xFFFFFFFF),
                      ),
                      Text(
                        _formatDuration(asset.videoDuration),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (selected) ...[
              Container(color: blue.withValues(alpha: 0.25)),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: blue,
                    shape: .circle,
                    border: .all(color: CupertinoColors.white, width: 2),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 16,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class const _Message({
  required final String text,
  final String? actionLabel,
  final Future<void> Function()? onAction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: .min,
          children: [
            Text(
              text,
              textAlign: .center,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () => onAction?.call(),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
