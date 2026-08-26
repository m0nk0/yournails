import 'dart:io';
import 'package:flutter/material.dart';
import '../models/nail_session.dart';

class PhotoViewScreen extends StatefulWidget {
  final File imageFile;
  final String title;
  final NailSession session;
  final String photoType; // 'before' | 'tryon' | 'after'
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onReplace;

  const PhotoViewScreen({
    super.key,
    required this.imageFile,
    required this.title,
    required this.session,
    required this.photoType,
    this.onDelete,
    this.onReplace,
  });

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  bool _isBusy = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить фото?', style: TextStyle(fontSize: 20)),
        content: const Text(
          'Фото будет удалено без возможности восстановления.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      setState(() => _isBusy = true);
      await widget.onDelete!();
      if (mounted) Navigator.pop(context, true); // сигнал обновления
    }
  }

  Future<void> _doReplace() async {
    if (widget.onReplace == null) return;
    setState(() => _isBusy = true);
    await widget.onReplace!();
    if (mounted) Navigator.pop(context, true);
  }

  bool get _canReplace => widget.photoType == 'before' || widget.photoType == 'after';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 22)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_canReplace && widget.onReplace != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 26),
              tooltip: 'Заменить из галереи',
              onPressed: _isBusy ? null : _doReplace,
            ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 26, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: _isBusy ? null : _confirmDelete,
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.file(widget.imageFile, fit: BoxFit.contain),
            ),
          ),
          if (_isBusy)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}