import 'package:convetchat/core/utils/file_format.dart';
import 'package:convetchat/features/chat/domain/entities/pending_media.dart';
import 'package:material_ui/material_ui.dart';

class const PendingMediaStripAndr({
  required final List<PendingMedia> items,
  required final Future<void> Function(String id) onRemove,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: .horizontal,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isFile) {
            return _FilePendingTile(item: item, onRemove: onRemove);
          }
          return SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: .expand,
              children: [
                ClipRRect(
                  borderRadius: .circular(16),
                  child: item.thumbBytes.isEmpty
                      ? Container(color: const Color(0xFF000000))
                      : Image.memory(item.thumbBytes, fit: .cover),
                ),
                if (item.isVideo)
                  Positioned(
                    left: 5,
                    bottom: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC000000),
                        borderRadius: .circular(7),
                      ),
                      child: Text(
                        _formatDuration(item.durationMs ?? 0),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => onRemove(item.id),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xB3000000),
                        shape: .circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class const _FilePendingTile({
  required final PendingMedia item,
  required final Future<void> Function(String id) onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: .circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            size: 28,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .start,
              children: [
                Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(fontSize: 13, color: scheme.onSurface),
                ),
                Text(
                  formatFileSize(item.size),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onRemove(item.id),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
