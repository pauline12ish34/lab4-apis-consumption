import 'package:flutter_test/flutter_test.dart';

import 'package:api_consumption/main.dart';

void main() {
  testWidgets('Welcome page renders on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const PostsManagerApp());

    expect(find.text('Welcome to Posts'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
