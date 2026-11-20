import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:set_elkol_app/features/customer/presentation/screens/legal_screen.dart';

void main() {
  testWidgets('LegalScreen renders properly with all tabs and compliance content',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LegalScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('الشروط وسياسة الخصوصية'), findsOneWidget);
    expect(find.text('الخصوصية'), findsOneWidget);
    expect(find.text('الشروط'), findsOneWidget);
    expect(find.text('حذف البيانات'), findsOneWidget);
    expect(find.text('سياسة الخصوصية (Privacy Policy)'), findsOneWidget);
  });
}
