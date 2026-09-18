import 'package:flutter/material.dart';
import 'package:the_registry/core/widgets/registry_search_field.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return RegistryAuraSearchField(
      controller: controller,
      fieldKey: const ValueKey<String>('home-search'),
      clearKey: const ValueKey<String>('home-search-clear'),
    );
  }
}
