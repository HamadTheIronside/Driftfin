import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/screens/shared/fladder_icon.dart';
import 'package:driftfin/util/application_info.dart';
import 'package:driftfin/util/string_extensions.dart';
import 'package:driftfin/util/theme_extensions.dart';

class FladderLogo extends ConsumerWidget {
  const FladderLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Hero(
      tag: "Fladder_Logo_Tag",
      child: Wrap(
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          const FladderIcon(),
          Text(
            ref.read(applicationInfoProvider).name.capitalize(),
            style: context.textTheme.displayLarge,
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
