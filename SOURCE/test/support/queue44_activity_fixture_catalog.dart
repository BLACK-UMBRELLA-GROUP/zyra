// Code-only activity samples and delegates. No checklist or preview bar widgets.
import 'package:flutter/foundation.dart';
import 'package:zyra/dev/zyra_my_zyra_activity_preview.dart';

@immutable
class Queue44ActivityChoice {
  const Queue44ActivityChoice({
    required this.example,
    required this.selected,
    required this.reviewed,
    required this.select,
  });
  final ZyraMyZyraActivityExample? example;
  final bool selected, reviewed;
  final VoidCallback select;
}

@immutable
class Queue44ActivityCatalog {
  Queue44ActivityCatalog({
    required this.selected,
    required Iterable<ZyraMyZyraActivityExample> reviewed,
    required ValueChanged<ZyraMyZyraActivityExample?> onSelected,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
    VoidCallback? onChecklist,
    VoidCallback? onCurrent,
  }) : choices = List.unmodifiable([
         Queue44ActivityChoice(
           example: null,
           selected: selected == null,
           reviewed: false,
           select: () => onSelected(null),
         ),
         for (final example in ZyraMyZyraActivityExample.values)
           Queue44ActivityChoice(
             example: example,
             selected: selected == example,
             reviewed: reviewed.contains(example),
             select: () => onSelected(example),
           ),
       ]),
       commands = Map.unmodifiable({
         'previous': ?onPrevious,
         'next': ?onNext,
         'checklist': ?onChecklist,
         'current': ?onCurrent,
       });
  final ZyraMyZyraActivityExample? selected;
  final List<Queue44ActivityChoice> choices;
  final Map<String, VoidCallback> commands;
}
