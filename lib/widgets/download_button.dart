import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../state/downloads.dart';
import '../theme.dart';
import 'cards.dart';

/// Avvia il download, chiedendo Premium se l'episodio è bloccato.
Future<void> downloadEpisode(BuildContext context, Episode episode) async {
  final state = context.read<AppState>();
  final downloads = context.read<DownloadManager>();
  if (state.isLocked(episode)) {
    await showPremiumSheet(context);
    if (state.isLocked(episode)) return;
  }
  downloads.enqueue(episode);
}

/// Icona di download per un episodio: scarica / avanzamento / scaricato.
class DownloadButton extends StatelessWidget {
  const DownloadButton({super.key, required this.episode});

  final Episode episode;

  @override
  Widget build(BuildContext context) {
    if (!DownloadManager.supported) return const SizedBox.shrink();
    final downloads = context.watch<DownloadManager>();
    final item = downloads.itemOf(episode.id);

    switch (item?.status) {
      case null:
        return IconButton(
          tooltip: 'Scarica',
          icon: const Icon(Icons.download_outlined),
          onPressed: () => downloadEpisode(context, episode),
        );
      case DownloadStatus.queued:
      case DownloadStatus.downloading:
        return IconButton(
          tooltip: 'Annulla download',
          onPressed: () => downloads.cancel(episode.id),
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: item!.status == DownloadStatus.queued
                      ? 0
                      : item.progress,
                  strokeWidth: 2.5,
                  backgroundColor: Colors.white12,
                  color: AppColors.accent2,
                ),
                const Icon(Icons.close, size: 12),
              ],
            ),
          ),
        );
      case DownloadStatus.done:
        return IconButton(
          tooltip: 'Scaricato',
          icon: const Icon(Icons.download_done, color: AppColors.accent2),
          onPressed: () => _confirmDelete(context, downloads),
        );
      case DownloadStatus.failed:
        return IconButton(
          tooltip: 'Download non riuscito: riprova',
          icon: const Icon(Icons.error_outline, color: Colors.redAccent),
          onPressed: () => downloads.retry(episode.id),
        );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DownloadManager downloads,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Eliminare il download?'),
        content: Text(
          '${episode.code} - ${episode.title} non sarà più disponibile offline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok ?? false) await downloads.delete(episode.id);
  }
}
