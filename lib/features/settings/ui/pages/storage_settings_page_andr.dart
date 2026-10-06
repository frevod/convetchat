import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/storage/media_disk_cache.dart';
import 'package:convetchat/core/storage/storage_quota_store.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const StorageSettingsPageAndr({super.key}) extends StatefulWidget {
  @override
  State<StorageSettingsPageAndr> createState() =>
      _StorageSettingsPageAndrState();
}

class _StorageSettingsPageAndrState() extends State<StorageSettingsPageAndr> {
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
    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: const Text('Данные и память'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  M3EList(
                    itemCount: 1,
                    itemBuilder: (context, _) => M3EListItem(
                      leading: const Icon(Icons.folder_rounded),
                      headline: 'Кэш медиа',
                      supportingText:
                          'Фото, видео, голосовые, аватары • $_fileCount файлов',
                      trailing: Text(
                        StorageQuotaStore.formatBytes(_usageBytes),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  M3EList(
                    itemCount: 1,
                    itemBuilder: (context, _) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 16,
                            children: [
                              const Icon(Icons.storage_rounded),
                              Expanded(
                                child: Text(
                                  'Максимальный размер',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                StorageQuotaStore.formatOption(maxBytes),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Без лимита кэш не очищается автоматически. '
                            'При выборе лимита самые старые файлы удаляются сами.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          M3ESlider(
                            value: _optionIndex.toDouble(),
                            min: 0,
                            max: (StorageQuotaStore.options.length - 1)
                                .toDouble(),
                            divisions: StorageQuotaStore.options.length - 1,
                            label: StorageQuotaStore.formatOption(maxBytes),
                            onChanged: (v) => _setOption(v.round()),
                          ),
                          const Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [Text('Без лимита'), Text('10 ГБ')],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  M3EList(
                    itemCount: 1,
                    onTap: (_) {
                      if (!_clearing) _clear();
                    },
                    itemBuilder: (context, _) => M3EListItem(
                      leading: const Icon(Icons.delete_outline_rounded),
                      headline: _clearing
                          ? 'Очистка…'
                          : 'Очистить кэш (${StorageQuotaStore.formatBytes(_usageBytes)})',
                      onTap: _clearing ? null : _clear,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
