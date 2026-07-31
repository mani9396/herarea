import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Terms & Conditions 📜'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HER AREA Partner O2O Agreement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.md),
                Text(
                  'By listing your bridal boutique or studio on HER AREA, you agree to the following standards:\n\n1. Authenticity of Craftsmanship\nAll listed products must accurately represent your studio\'s stitch quality and fabric grade.\n\n2. Prompt Communication\nVerified Gold badge status requires responding to customer trial requests within 4 hours during working times.\n\n3. Zero Commission Guarantee\nHER AREA guarantees zero transaction commission on orders generated via direct O2O connections.',
                  style: TextStyle(height: 1.6, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
