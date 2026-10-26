import 'package:flutter/material.dart';
import 'integration/pending_gateway.dart';
import 'ui/bloom_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Het's persisted adapter belongs here once reviewed and merged.
  runApp(BloomApp(gateway: PendingGateway()));
}
