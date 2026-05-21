import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../application/health_controller.dart';
import '../domain/health_entry.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({
    required this.petId,
    required this.initialType,
    super.key,
  });

  final String petId;
  final HealthEntryType initialType;

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  static const List<String> _itSuggestedSymptoms = <String>[
    'Letargia',
    'Vomito',
    'Diarrea',
    'Inappetenza',
    'Prurito',
    'Tosse',
    'Starnuti',
    'Zoppia',
    'Sete eccessiva',
  ];

  static const List<String> _enSuggestedSymptoms = <String>[
    'Lethargy',
    'Vomiting',
    'Diarrhea',
    'Loss of appetite',
    'Itching',
    'Cough',
    'Sneezing',
    'Limping',
    'Excessive thirst',
  ];

  Future<void> _openEntrySheet({
    required Pet pet,
    required _HealthStrings strings,
    HealthEntry? entry,
  }) async {
    final result = await showModalBottomSheet<_HealthEntryEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _HealthEntryEditorSheet(
          strings: strings,
          entryType: widget.initialType,
          entry: entry,
          suggestedSymptoms: Localizations.localeOf(context).languageCode == 'en'
              ? _enSuggestedSymptoms
              : _itSuggestedSymptoms,
        );
      },
    );

    if (result == null) {
      return;
    }

    switch (result.action) {
      case _HealthEntryEditorAction.save:
        await _saveEntry(
          pet: pet,
          strings: strings,
          previousEntry: entry,
          payload: result.payload!,
        );
      case _HealthEntryEditorAction.delete:
        if (entry != null) {
          await _deleteEntry(entry, strings);
        }
    }
  }

  Future<void> _saveEntry({
    required Pet pet,
    required _HealthStrings strings,
    required HealthEntry? previousEntry,
    required _HealthEntryPayload payload,
  }) async {
    final now = DateTime.now();

    final entry = HealthEntry(
      id: previousEntry?.id ?? 'health-${now.microsecondsSinceEpoch}',
      petId: pet.id,
      petName: pet.name,
      type: widget.initialType,
      title: payload.title,
      recordedAt: previousEntry?.recordedAt ?? now,
      createdAt: previousEntry?.createdAt ?? now,
      notes: payload.notes,
      symptomIntensity:
          widget.initialType == HealthEntryType.symptom ? payload.intensity : null,
    );

    if (previousEntry == null) {
      await ref.read(healthControllerProvider.notifier).addEntry(entry);
    } else {
      await ref.read(healthControllerProvider.notifier).updateEntry(entry);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          previousEntry == null ? strings.entrySaved : strings.entryUpdated,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    HealthEntry entry,
    _HealthStrings strings,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.deleteEntryTitle),
          content: Text(strings.deleteEntryMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _deleteEntry(entry, strings);
  }

  Future<void> _deleteEntry(
    HealthEntry entry,
    _HealthStrings strings,
  ) async {
    await ref.read(healthControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entryDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _HealthStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final healthState = ref.watch(healthControllerProvider);

    return petsState.when(
      loading: () => Scaffold(
        backgroundColor: _HealthPalette.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: _HealthPalette.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (pets) {
        final pet = _findPet(pets, widget.petId);

        if (pet == null) {
          return Scaffold(
            backgroundColor: _HealthPalette.background,
            appBar: _buildAppBar(context, strings, null),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(strings.petNotFound),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _HealthPalette.background,
          appBar: _buildAppBar(
            context,
            strings,
            () => _openEntrySheet(
              pet: pet,
              strings: strings,
            ),
          ),
          body: healthState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (entries) {
              final petEntries = entries
                  .where(
                    (entry) =>
                        entry.petId == pet.id && entry.type == widget.initialType,
                  )
                  .toList(growable: false);

              return ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                children: [
                  Text(
                    strings.registeredTitle(widget.initialType),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _HealthPalette.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.screenSubtitle(widget.initialType),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _HealthPalette.textSecondary,
                          height: 1.3,
                        ),
                  ),
                  const SizedBox(height: 18),
                  if (petEntries.isEmpty)
                    _EmptyEntriesCard(strings: strings, type: widget.initialType)
                  else
                    ...petEntries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _HealthEntryCard(
                          entry: entry,
                          petColor: Color(pet.colorValue),
                          strings: strings,
                          onEdit: () => _openEntrySheet(
                            pet: pet,
                            strings: strings,
                            entry: entry,
                          ),
                          onDelete: () => _confirmDelete(entry, strings),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _HealthDisclaimerCard(strings: strings),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    _HealthStrings strings,
    VoidCallback? onAdd,
  ) {
    return AppBar(
      backgroundColor: _HealthPalette.background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 88,
      automaticallyImplyLeading: false,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: 18, top: 18, bottom: 10),
        child: _CircleActionButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              strings.screenTitle(widget.initialType),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _HealthPalette.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              strings.headerCaption(widget.initialType),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _HealthPalette.textMuted,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18, top: 18, bottom: 10),
          child: _CircleActionButton(
            icon: Icons.add,
            onTap: onAdd,
          ),
        ),
      ],
    );
  }

  Pet? _findPet(List<Pet> pets, String petId) {
    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HealthPalette.chipBackground,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 20,
            color: _HealthPalette.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _HealthEntryCard extends StatelessWidget {
  const _HealthEntryCard({
    required this.entry,
    required this.petColor,
    required this.strings,
    required this.onEdit,
    required this.onDelete,
  });

  final HealthEntry entry;
  final Color petColor;
  final _HealthStrings strings;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('d MMM · HH:mm', locale).format(entry.recordedAt);
    final notes = entry.notes?.trim();

    return GestureDetector(
      onTap: onEdit,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: _HealthPalette.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _HealthPalette.cardBorder,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: notes != null && notes.isNotEmpty ? 92 : 64,
                decoration: BoxDecoration(
                  color: petColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: _HealthPalette.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                          ),
                        ),
                        if (entry.symptomIntensity != null)
                          _IntensityBadge(
                            label:
                                strings.intensityLabelFor(entry.symptomIntensity!),
                            intensity: entry.symptomIntensity!,
                          ),
                        _HealthEntryMenuButton(
                          editLabel: strings.edit,
                          deleteLabel: strings.delete,
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: petColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${entry.petName}  ·  $dateLabel',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _HealthPalette.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _HealthPalette.noteBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          notes,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _HealthPalette.textPrimary,
                                height: 1.3,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthEntryMenuButton extends StatelessWidget {
  const _HealthEntryMenuButton({
    required this.editLabel,
    required this.deleteLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final String editLabel;
  final String deleteLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HealthEntryMenuAction>(
      tooltip: 'Azioni',
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (action) {
        switch (action) {
          case _HealthEntryMenuAction.edit:
            onEdit();
          case _HealthEntryMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: _HealthEntryMenuAction.edit,
            child: Text(editLabel),
          ),
          PopupMenuItem(
            value: _HealthEntryMenuAction.delete,
            child: Text(deleteLabel),
          ),
        ];
      },
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 6),
        decoration: const BoxDecoration(
          color: _HealthPalette.chipBackground,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          '⋯',
          style: TextStyle(
            color: _HealthPalette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

enum _HealthEntryMenuAction {
  edit,
  delete,
}

class _IntensityBadge extends StatelessWidget {
  const _IntensityBadge({
    required this.label,
    required this.intensity,
  });

  final String label;
  final SymptomIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final activeBars = switch (intensity) {
      SymptomIntensity.mild => 1,
      SymptomIntensity.moderate => 2,
      SymptomIntensity.high => 3,
    };

    final color = switch (intensity) {
      SymptomIntensity.mild => _HealthPalette.mild,
      SymptomIntensity.moderate => _HealthPalette.moderate,
      SymptomIntensity.high => _HealthPalette.high,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(
            3,
            (index) => Container(
              width: 5,
              height: 12,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 3),
              decoration: BoxDecoration(
                color: index < activeBars ? color : color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _HealthDisclaimerCard extends StatelessWidget {
  const _HealthDisclaimerCard({
    required this.strings,
  });

  final _HealthStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _HealthPalette.disclaimerBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _HealthPalette.disclaimerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: _HealthPalette.disclaimerIcon,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'i',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.disclaimer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _HealthPalette.textSecondary,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEntriesCard extends StatelessWidget {
  const _EmptyEntriesCard({
    required this.strings,
    required this.type,
  });

  final _HealthStrings strings;
  final HealthEntryType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _HealthPalette.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _HealthPalette.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            type == HealthEntryType.symptom
                ? Icons.health_and_safety_outlined
                : Icons.note_alt_outlined,
            size: 36,
            color: _HealthPalette.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            strings.emptyTitle(type),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _HealthPalette.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.emptyDescription(type),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _HealthPalette.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _HealthEntryEditorSheet extends StatefulWidget {
  const _HealthEntryEditorSheet({
    required this.strings,
    required this.entryType,
    required this.suggestedSymptoms,
    this.entry,
  });

  final _HealthStrings strings;
  final HealthEntryType entryType;
  final List<String> suggestedSymptoms;
  final HealthEntry? entry;

  @override
  State<_HealthEntryEditorSheet> createState() => _HealthEntryEditorSheetState();
}

class _HealthEntryEditorSheetState extends State<_HealthEntryEditorSheet> {
  static const String _customSymptomValue = '__custom_symptom__';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late SymptomIntensity _selectedIntensity;
  String? _selectedSuggestion;
  String? _selectionError;

  bool get _isSymptom => widget.entryType == HealthEntryType.symptom;
  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;

    _selectedIntensity = entry?.symptomIntensity ?? SymptomIntensity.mild;
    _notesController.text = entry?.notes ?? '';

    if (entry == null) {
      return;
    }

    if (_isSymptom) {
      final title = entry.title.trim();
      final isSuggested = widget.suggestedSymptoms.contains(title);

      if (isSuggested) {
        _selectedSuggestion = title;
      } else {
        _selectedSuggestion = _customSymptomValue;
        _customTitleController.text = title;
      }
    } else {
      _customTitleController.text = entry.title;
    }
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();

    String finalTitle = '';

    if (_isSymptom) {
      if (_selectedSuggestion == null) {
        final customText = _customTitleController.text.trim();

        if (customText.isEmpty) {
          setState(() {
            _selectionError = widget.strings.symptomRequired;
          });

          return;
        }

        finalTitle = customText;
      } else if (_selectedSuggestion == _customSymptomValue) {
        final customText = _customTitleController.text.trim();

        if (customText.isEmpty) {
          setState(() {
            _selectionError = widget.strings.symptomRequired;
          });

          return;
        }

        finalTitle = customText;
      } else {
        finalTitle = _selectedSuggestion!;
      }
    } else {
      final isValid = _formKey.currentState?.validate() ?? false;

      if (!isValid) {
        return;
      }

      finalTitle = _customTitleController.text.trim();
    }

    final notes = _notesController.text.trim();

    Navigator.of(context).pop(
      _HealthEntryEditorResult.save(
        _HealthEntryPayload(
          title: finalTitle,
          notes: notes.isEmpty ? null : notes,
          intensity: _selectedIntensity,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(widget.strings.deleteEntryTitle),
          content: Text(widget.strings.deleteEntryMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(widget.strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(widget.strings.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      Navigator.of(context).pop(_HealthEntryEditorResult.delete());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    return Padding(
      padding: EdgeInsets.only(
        left: 0,
        right: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: _HealthPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _HealthPalette.cardBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _sheetTitle(strings),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: _HealthPalette.textPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      _CircleActionButton(
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_isSymptom) ...[
                    Text(
                      strings.whatDidYouNotice,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _HealthPalette.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ...widget.suggestedSymptoms.map(
                          (symptom) => _SelectablePill(
                            label: symptom,
                            selected: _selectedSuggestion == symptom,
                            onTap: () {
                              setState(() {
                                _selectedSuggestion = symptom;
                                _selectionError = null;
                              });
                            },
                          ),
                        ),
                        _SelectablePill(
                          label: strings.otherSymptomChip,
                          selected: _selectedSuggestion == _customSymptomValue,
                          onTap: () {
                            setState(() {
                              _selectedSuggestion = _customSymptomValue;
                              _selectionError = null;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_selectedSuggestion == _customSymptomValue) ...[
                      const SizedBox(height: 12),
                      _TextFieldShell(
                        child: TextFormField(
                          controller: _customTitleController,
                          decoration: InputDecoration(
                            hintText: strings.customSymptomHint,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                    if (_selectionError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectionError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      strings.intensityLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _HealthPalette.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _IntensitySelectorCard(
                            label: strings.intensityMild,
                            selected: _selectedIntensity == SymptomIntensity.mild,
                            activeColor: _HealthPalette.mild,
                            onTap: () {
                              setState(() {
                                _selectedIntensity = SymptomIntensity.mild;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _IntensitySelectorCard(
                            label: strings.intensityModerate,
                            selected:
                                _selectedIntensity == SymptomIntensity.moderate,
                            activeColor: _HealthPalette.moderate,
                            onTap: () {
                              setState(() {
                                _selectedIntensity = SymptomIntensity.moderate;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _IntensitySelectorCard(
                            label: strings.intensityHigh,
                            selected: _selectedIntensity == SymptomIntensity.high,
                            activeColor: _HealthPalette.high,
                            onTap: () {
                              setState(() {
                                _selectedIntensity = SymptomIntensity.high;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _TextFieldShell(
                      child: TextFormField(
                        controller: _customTitleController,
                        decoration: InputDecoration(
                          labelText: strings.diaryTitleLabel,
                          hintText: strings.diaryTitleHint,
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return strings.titleRequired;
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    strings.notesLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _HealthPalette.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _TextFieldShell(
                    child: TextFormField(
                      controller: _notesController,
                      minLines: 4,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: strings.notesHint,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _HealthPalette.disclaimerBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _HealthPalette.disclaimerBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: _HealthPalette.disclaimerIcon,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'i',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            strings.sheetDisclaimer,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _HealthPalette.textSecondary,
                                      height: 1.35,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: _HealthPalette.cardBackground,
                            side: const BorderSide(
                              color: _HealthPalette.cardBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            strings.cancel,
                            style: const TextStyle(
                              color: _HealthPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: _HealthPalette.actionPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _isEditing ? strings.update : strings.save,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(strings.delete),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: _HealthPalette.disclaimerIcon,
                        side: const BorderSide(
                          color: _HealthPalette.disclaimerBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _sheetTitle(_HealthStrings strings) {
    if (_isEditing) {
      return _isSymptom ? strings.editSymptomTitle : strings.editDiaryTitle;
    }

    return _isSymptom ? strings.addSymptomTitle : strings.addDiaryTitle;
  }
}

class _TextFieldShell extends StatelessWidget {
  const _TextFieldShell({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _HealthPalette.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _HealthPalette.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: child,
    );
  }
}

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        selected ? _HealthPalette.actionPrimary : _HealthPalette.chipBackground;
    final foreground = selected ? Colors.white : _HealthPalette.textPrimary;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _IntensitySelectorCard extends StatelessWidget {
  const _IntensitySelectorCard({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? activeColor.withValues(alpha: 0.12) : _HealthPalette.chipBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? activeColor : _HealthPalette.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? activeColor : _HealthPalette.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class _HealthEntryPayload {
  const _HealthEntryPayload({
    required this.title,
    required this.notes,
    required this.intensity,
  });

  final String title;
  final String? notes;
  final SymptomIntensity intensity;
}

enum _HealthEntryEditorAction {
  save,
  delete,
}

class _HealthEntryEditorResult {
  const _HealthEntryEditorResult._({
    required this.action,
    this.payload,
  });

  factory _HealthEntryEditorResult.save(_HealthEntryPayload payload) {
    return _HealthEntryEditorResult._(
      action: _HealthEntryEditorAction.save,
      payload: payload,
    );
  }

  factory _HealthEntryEditorResult.delete() {
    return const _HealthEntryEditorResult._(
      action: _HealthEntryEditorAction.delete,
    );
  }

  final _HealthEntryEditorAction action;
  final _HealthEntryPayload? payload;
}

class _HealthPalette {
  static const Color background = Color(0xFFF7F1E3);
  static const Color cardBackground = Color(0xFFFFFCF8);
  static const Color cardBorder = Color(0xFFE5D8BF);
  static const Color chipBackground = Color(0xFFF0E7D4);
  static const Color noteBackground = Color(0xFFF1E7D6);
  static const Color actionPrimary = Color(0xFF2E2416);
  static const Color textPrimary = Color(0xFF2F271C);
  static const Color textSecondary = Color(0xFF867B68);
  static const Color textMuted = Color(0xFFA69881);
  static const Color disclaimerBackground = Color(0xFFF8EADF);
  static const Color disclaimerBorder = Color(0xFFE5C5B2);
  static const Color disclaimerIcon = Color(0xFFC56E4C);

  static const Color mild = Color(0xFF8FC49C);
  static const Color moderate = Color(0xFFF0B24A);
  static const Color high = Color(0xFFE28268);
}

class _HealthStrings {
  const _HealthStrings({
    required this.healthDiaryTitle,
    required this.symptomsTitle,
    required this.diaryHeaderCaption,
    required this.symptomHeaderCaption,
    required this.diarySubtitle,
    required this.symptomSubtitle,
    required this.registeredSymptoms,
    required this.registeredDiary,
    required this.addSymptomTitle,
    required this.editSymptomTitle,
    required this.addDiaryTitle,
    required this.editDiaryTitle,
    required this.whatDidYouNotice,
    required this.otherSymptomChip,
    required this.customSymptomHint,
    required this.symptomRequired,
    required this.diaryTitleLabel,
    required this.diaryTitleHint,
    required this.titleRequired,
    required this.intensityLabel,
    required this.intensityMild,
    required this.intensityModerate,
    required this.intensityHigh,
    required this.notesLabel,
    required this.notesHint,
    required this.save,
    required this.update,
    required this.entrySaved,
    required this.entryUpdated,
    required this.emptySymptomsTitle,
    required this.emptySymptomsDescription,
    required this.emptyDiaryTitle,
    required this.emptyDiaryDescription,
    required this.deleteEntryTitle,
    required this.deleteEntryMessage,
    required this.entryDeleted,
    required this.edit,
    required this.delete,
    required this.cancel,
    required this.petNotFound,
    required this.disclaimer,
    required this.sheetDisclaimer,
  });

  final String healthDiaryTitle;
  final String symptomsTitle;
  final String diaryHeaderCaption;
  final String symptomHeaderCaption;
  final String diarySubtitle;
  final String symptomSubtitle;
  final String registeredSymptoms;
  final String registeredDiary;
  final String addSymptomTitle;
  final String editSymptomTitle;
  final String addDiaryTitle;
  final String editDiaryTitle;
  final String whatDidYouNotice;
  final String otherSymptomChip;
  final String customSymptomHint;
  final String symptomRequired;
  final String diaryTitleLabel;
  final String diaryTitleHint;
  final String titleRequired;
  final String intensityLabel;
  final String intensityMild;
  final String intensityModerate;
  final String intensityHigh;
  final String notesLabel;
  final String notesHint;
  final String save;
  final String update;
  final String entrySaved;
  final String entryUpdated;
  final String emptySymptomsTitle;
  final String emptySymptomsDescription;
  final String emptyDiaryTitle;
  final String emptyDiaryDescription;
  final String deleteEntryTitle;
  final String deleteEntryMessage;
  final String entryDeleted;
  final String edit;
  final String delete;
  final String cancel;
  final String petNotFound;
  final String disclaimer;
  final String sheetDisclaimer;

  String screenTitle(HealthEntryType type) {
    return type == HealthEntryType.symptom ? symptomsTitle : healthDiaryTitle;
  }

  String headerCaption(HealthEntryType type) {
    return type == HealthEntryType.symptom
        ? symptomHeaderCaption
        : diaryHeaderCaption;
  }

  String screenSubtitle(HealthEntryType type) {
    return type == HealthEntryType.symptom ? symptomSubtitle : diarySubtitle;
  }

  String registeredTitle(HealthEntryType type) {
    return type == HealthEntryType.symptom ? registeredSymptoms : registeredDiary;
  }

  String emptyTitle(HealthEntryType type) {
    return type == HealthEntryType.symptom
        ? emptySymptomsTitle
        : emptyDiaryTitle;
  }

  String emptyDescription(HealthEntryType type) {
    return type == HealthEntryType.symptom
        ? emptySymptomsDescription
        : emptyDiaryDescription;
  }

  String intensityLabelFor(SymptomIntensity intensity) {
    return switch (intensity) {
      SymptomIntensity.mild => intensityMild,
      SymptomIntensity.moderate => intensityModerate,
      SymptomIntensity.high => intensityHigh,
    };
  }

  static _HealthStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _HealthStrings(
        healthDiaryTitle: 'Health diary',
        symptomsTitle: 'Symptoms',
        diaryHeaderCaption: 'Track health notes',
        symptomHeaderCaption: 'Track what you notice',
        diarySubtitle: 'Keep your notes organized for future vet visits.',
        symptomSubtitle: 'Track what you notice',
        registeredSymptoms: 'Recorded',
        registeredDiary: 'Saved notes',
        addSymptomTitle: 'Add a symptom',
        editSymptomTitle: 'Edit symptom',
        addDiaryTitle: 'Add a note',
        editDiaryTitle: 'Edit note',
        whatDidYouNotice: 'What did you notice',
        otherSymptomChip: 'Other',
        customSymptomHint: 'Write a different symptom',
        symptomRequired: 'Select or write a symptom',
        diaryTitleLabel: 'Title',
        diaryTitleHint: 'E.g. General note',
        titleRequired: 'Enter a title',
        intensityLabel: 'Intensity',
        intensityMild: 'Mild',
        intensityModerate: 'Medium',
        intensityHigh: 'High',
        notesLabel: 'Notes (optional)',
        notesHint: 'When did it happen, duration, context...',
        save: 'Save',
        update: 'Update',
        entrySaved: 'Entry saved',
        entryUpdated: 'Entry updated',
        emptySymptomsTitle: 'No symptoms recorded',
        emptySymptomsDescription:
            'Use the + button to save the first symptom you notice.',
        emptyDiaryTitle: 'No notes saved',
        emptyDiaryDescription:
            'Use the + button to save the first health note.',
        deleteEntryTitle: 'Delete this entry?',
        deleteEntryMessage: 'This entry will be removed from the local history.',
        entryDeleted: 'Entry deleted',
        edit: 'Edit',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'The symptoms you note help you and your veterinarian reconstruct the history. Pet Life does not interpret them clinically.',
        sheetDisclaimer:
            'For severe or persistent symptoms, contact your veterinarian immediately.',
      );
    }

    return const _HealthStrings(
      healthDiaryTitle: 'Diario salute',
      symptomsTitle: 'Sintomi',
      diaryHeaderCaption: 'Tieni traccia delle note di salute',
      symptomHeaderCaption: 'Tieni traccia di quello che noti',
      diarySubtitle:
          'Conserva le note in modo ordinato per le prossime visite veterinarie.',
      symptomSubtitle: 'Tieni traccia di quello che noti',
      registeredSymptoms: 'Registrati',
      registeredDiary: 'Note salvate',
      addSymptomTitle: 'Annota un sintomo',
      editSymptomTitle: 'Modifica sintomo',
      addDiaryTitle: 'Aggiungi una nota',
      editDiaryTitle: 'Modifica nota',
      whatDidYouNotice: 'Cosa hai notato',
      otherSymptomChip: 'Altro',
      customSymptomHint: 'Scrivi un sintomo diverso',
      symptomRequired: 'Seleziona o scrivi un sintomo',
      diaryTitleLabel: 'Titolo',
      diaryTitleHint: 'Es. Nota controllo generale',
      titleRequired: 'Inserisci un titolo',
      intensityLabel: 'Intensità',
      intensityMild: 'Lieve',
      intensityModerate: 'Medio',
      intensityHigh: 'Forte',
      notesLabel: 'Note (opzionale)',
      notesHint: 'Quando è successo, durata, contesto...',
      save: 'Salva',
      update: 'Aggiorna',
      entrySaved: 'Voce salvata',
      entryUpdated: 'Voce aggiornata',
      emptySymptomsTitle: 'Nessun sintomo registrato',
      emptySymptomsDescription:
          'Usa il tasto + per registrare il primo sintomo che noti.',
      emptyDiaryTitle: 'Nessuna nota salvata',
      emptyDiaryDescription:
          'Usa il tasto + per salvare la prima nota di salute.',
      deleteEntryTitle: 'Eliminare questa voce?',
      deleteEntryMessage: 'La voce verrà rimossa dallo storico locale.',
      entryDeleted: 'Voce eliminata',
      edit: 'Modifica',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'I sintomi che annoti aiutano te e il veterinario a ricostruire la storia. Pet Life non li interpreta clinicamente.',
      sheetDisclaimer:
          'Per sintomi gravi o persistenti, contatta subito il veterinario.',
    );
  }
}