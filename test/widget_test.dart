import 'package:flutter_test/flutter_test.dart';
import 'package:cord_card/main.dart';

void main() {
  testWidgets('early preview makes no feature claims', (tester) async {
    await tester.pumpWidget(const CordCardApp());
    expect(find.text('Cord Card\nInventory coming soon'), findsOneWidget);
  });
}
