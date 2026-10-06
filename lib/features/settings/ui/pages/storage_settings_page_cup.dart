import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/storage/media_disk_cache.dart';
import 'package:convetchat/core/storage/storage_quota_store.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const StorageSettingsPageCup({super.key}) extends StatefulWidget {
  @override
  State<StorageSettingsPageCup> createState() => _StorageSettingsPageCupState();
}

class _StorageSettingsPageCupState() extends State<StorageSettingsPageCup> {
  int _optionIndex = 0;
  int _usageBytes = 0;
  int _fileCount = 0;
  bool _loading = true;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final max = await getIt<StorageQuotaStore>().getMaxBytes();
      final usage = await getIt<MediaDiskCache>().totalSize();
      final count = await getIt<MediaDiskCache>().fileCount();
      if (!mounted) return;
      setState(() {
        _optionIndex = _indexFor(max);
        _usageBytes = usage;
        _fileCount = count;
        _loading = false;
      });
    } catch (e, s) {
      getIt<Talker>().error('[settings] read cache size failed', e, s);
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static int _indexFor(int bytes) {
    final idx = StorageQuotaStore.options.indexOf(bytes);
    return idx < 0 ? 0 : idx;
  }

  Future<void> _setOption(int index) async {
    setState(() => _optionIndex = index);
    try {
      final bytes = StorageQuotaStore.options[index];
      await getIt<StorageQuotaStore>().setMaxBytes(bytes);
      await getIt<MediaDiskCache>().enforceQuota(bytes);
      if (!mounted) return;
      final usage = await getIt<MediaDiskCache>().totalSize();
      final count = await getIt<MediaDiskCache>().fileCount();
      if (!mounted) return;
      setState(() {
        _usageBytes = usage;
        _fileCount = count;
      });
    } catch (e, s) {
      getIt<Talker>().error('[settings] save cache limit failed', e, s);
    }
  }

  Future<void> _clear() async {
    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: 'Очистить кэш?',
      message:
          'Удалятся сохранённые фото, видео, голосовые и аватары. '
          'Сообщения останутся — они загрузятся с сервера заново.',
      confirmLabel: 'Очистить',
      cancelLabel: 'Отмена',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _clearing = true);
    try {
      await getIt<MediaDiskCache>().clear();
    } catch (e, s) {
      getIt<Talker>().error('[settings] clear cache failed', e, s);
    }
    final usage = await getIt<MediaDiskCache>().totalSize();
    final count = await getIt<MediaDiskCache>().fileCount();
    if (!mounted) return;
    setState(() {
      _usageBytes = usage;
      _fileCount = count;
      _clearing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxBytes = StorageQuotaStore.options[_optionIndex];
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Данные и память'),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                children: [
                  CupertinoListSection.insetGrouped(
                    backgroundColor: CupertinoColors.transparent,
                    header: const Text('Использование'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.folder_fill),
                        title: const Text('Кэш медиа'),
                        subtitle: Text(
                          'Фото, видео, голосовые, аватары • $_fileCount файлов',
                        ),
                        trailing: Text(
                          StorageQuotaStore.formatBytes(_usageBytes),
                        ),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.trash_fill),
                        title: Text(
                          _clearing
                              ? 'Очистка…'
                              : 'Очистить кэш (${StorageQuotaStore.formatBytes(_usageBytes)})',
                        ),
                        onTap: _clearing ? null : _clear,
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    backgroundColor: CupertinoColors.transparent,
                    header: const Text('Максимальный размер'),
                    footer: const Text(
                      'Без лимита кэш не очищается автоматически. '
                      'При выборе лимита самые старые файлы удаляются сами.',
                    ),
                    children: [
                      CupertinoListTile(
                        title: Text(
                          StorageQuotaStore.formatOption(maxBytes),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Column(
                          children: [
                            CupertinoSlider(
                              value: _optionIndex.toDouble(),
                              min: 0,
                              max:
                                  (StorageQuotaStore.options.length - 1)
                                      .toDouble(),
                              divisions:
                                  StorageQuotaStore.options.length - 1,
                              onChanged: (v) => _setOption(v.round()),
                            ),
                            const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Без лимита'),
                                Text('10 ГБ'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
