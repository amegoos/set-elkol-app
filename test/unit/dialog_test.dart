import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:set_elkol_app/features/customer/presentation/screens/support_screen.dart';

void main() {
  testWidgets('SupportScreen renders properly with all channels and FAQs',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SupportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('مركز المساعدة والدعم الفني'), findsOneWidget);
    expect(find.text('setelkol.support@gmail.com'), findsOneWidget);
    expect(find.text('01067322605'), findsWidgets);
    expect(find.text('شات واتساب'), findsOneWidget);
    expect(find.text('اتصل الآن'), findsOneWidget);
    expect(find.text('إرسال الاستفسار'), findsOneWidget);
    expect(find.text('الأسئلة الشائعة 💡'), findsOneWidget);
  });
}
