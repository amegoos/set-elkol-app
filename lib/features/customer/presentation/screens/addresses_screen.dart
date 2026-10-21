import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('عناوين التوصيل')),
      body: const AppEmptyWidget(
        message: 'لا توجد عناوين محفوظة',
        icon: Icons.location_on_outlined,
        actionLabel: 'إضافة عنوان',
      ),
    );
  }
}
