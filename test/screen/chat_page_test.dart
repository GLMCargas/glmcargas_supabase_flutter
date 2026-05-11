import 'package:app/screen/chat_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(initializeSupabaseForTests);

  testWidgets('chat mostra erro quando roomId nao foi informado', (
    tester,
  ) async {
    await pumpTestPage(tester, const ChatPage());
    await tester.pump();

    expect(find.textContaining('RoomId'), findsOneWidget);
  });
}
