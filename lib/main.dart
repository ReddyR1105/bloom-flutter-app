import 'package:flutter/material.dart';
import 'dart:async';
import 'data/bloom_repository.dart';
import 'integration/bloom_gateway.dart';
import 'ui/bloom_app.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BloomBootstrap());
}

/// Opens the actual repository once, surfaces startup failures, and permits a
/// deliberate retry without replacing failures with an empty database.
class BloomBootstrap extends StatefulWidget {
  const BloomBootstrap({super.key, this.open});
  final Future<BloomGateway> Function()? open;
  @override
  State<BloomBootstrap> createState() => _BloomBootstrapState();
}

class _BloomBootstrapState extends State<BloomBootstrap> {
  BloomGateway? _repository;
  Object? _error;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final repository = await (widget.open?.call() ?? BloomRepository.open());
      if (!mounted) {
        await repository.close();
        return;
      }
      setState(() {
        _repository = repository;
        _opening = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _opening = false;
        });
      }
    }
  }

  // Once attached, BloomApp owns close(). An open completing after disposal
  // closes itself above, so no repository is leaked or closed twice here.
  @override
  Widget build(BuildContext context) {
    final repository = _repository;
    if (repository != null) return BloomApp(gateway: repository);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bloom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: forest),
        scaffoldBackgroundColor: const Color(0xFFFAF8F2),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('bloom.')),
        body: _opening
            ? const Center(child: CircularProgressIndicator())
            : ContentColumn(
                children: [
                  const Text(
                    'Your local storage could not be opened',
                    style: heading,
                  ),
                  Text(readableError(_error ?? 'Unknown storage error.')),
                  const Text(
                    'Your saved records have not been deleted. Retry opening local storage.',
                  ),
                  FilledButton(
                    onPressed: _open,
                    child: const Text('Retry opening Bloom'),
                  ),
                ],
              ),
      ),
    );
  }
}
