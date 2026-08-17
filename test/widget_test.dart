import 'package:flutter_test/flutter_test.dart';

import 'package:music_center/main.dart';

void main() {
  testWidgets('MusicApp builds and renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicApp());
    await tester.pump();
    expect(find.byType(MusicApp), findsOneWidget);
  });
}
