import 'package:convetchat/features/chat/domain/entities/pending_media.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const PendingMediaStripCup({
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
                        CupertinoIcons.xmark,
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
