import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../pack/pack_provider.dart';

class JoinPackSheet extends ConsumerStatefulWidget {
  const JoinPackSheet({super.key});

  @override
  ConsumerState<JoinPackSheet> createState() => _JoinPackSheetState();
}

class _JoinPackSheetState extends ConsumerState<JoinPackSheet> {
  final _controller = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() => _joining = true);
    try {
      final pack = await ref.read(packServiceProvider).joinPack(code);
      ref.invalidate(myPacksProvider);
      if (mounted) {
        Navigator.of(context).pop();
        context.push('/pack/${pack.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Join a Pack',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Enter 6-character invite code',
              prefixText: '#',
            ),
            maxLength: 6,
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _joining ? null : _join,
              child: _joining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Join'),
            ),
          ),
        ],
      ),
    );
  }
}
