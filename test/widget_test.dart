import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_sheet_admin/main.dart';

void main() {
  testWidgets('SmartSheetAdminApp UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartSheetAdminApp());

    // Verify key UI elements exist
    expect(find.text('لوحة تحكم المشرف - Super Admin'), findsOneWidget);
    expect(find.text('المصنع المستهدف: '), findsOneWidget);
    expect(find.text('CP-2026'), findsOneWidget);
    expect(find.text('توليد'), findsOneWidget);
    expect(find.text('تفعيل وإرسال الكود'), findsOneWidget);

    // Tap the 'توليد' button to generate a random 6-digit code
    await tester.tap(find.text('توليد'));
    await tester.pump();

    // Verify the text field now contains a 6-digit number
    final textFormField = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(textFormField.controller?.text.length, equals(6));
    expect(int.tryParse(textFormField.controller!.text), isNotNull);
  });
}
