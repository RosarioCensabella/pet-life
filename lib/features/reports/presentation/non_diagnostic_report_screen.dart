import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../documents/application/pet_document_controller.dart';
import '../../documents/domain/pet_document.dart';
import '../../expenses/application/expense_controller.dart';
import '../../expenses/domain/expense_entry.dart';
import '../../food/application/food_controller.dart';
import '../../food/domain/food_entry.dart';
import '../../health/application/health_controller.dart';
import '../../health/domain/health_entry.dart';
import '../../medications/application/medication_controller.dart';
import '../../medications/domain/medication_entry.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../reminders/domain/reminder.dart';
import '../../visits/application/visit_controller.dart';
import '../../visits/domain/visit_entry.dart';
import '../../weight/application/weight_controller.dart';
import '../../weight/domain/weight_entry.dart';

class NonDiagnosticReportScreen extends ConsumerWidget {
  const NonDiagnosticReportScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final strings = _ReportStrings.of(context);

    final petsState = ref.watch(petControllerProvider);
    final remindersState = ref.watch(reminderControllerProvider);
    final documentsState = ref.watch(petDocumentControllerProvider);
    final weightState = ref.watch(weightControllerProvider);
    final healthState = ref.watch(healthControllerProvider);
    final foodState = ref.watch(foodControllerProvider);
    final medicationsState = ref.watch(medicationControllerProvider);
    final visitsState = ref.watch(visitControllerProvider);
    final expensesState = ref.watch(expenseControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: petsState.when(
          loading: () => Center(child: Text(l10n.loadingPets)),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final pet = _findPet(pets, petId);

            if (pet == null) {
              return _PetNotFoundState(
                title: l10n.petNotFound,
                buttonLabel: l10n.backToHome,
              );
            }

            final reminders = _filterByPet(
              remindersState.valueOrNull ?? const <Reminder>[],
              (reminder) => reminder.petId,
            );
            final documents = _filterByPet(
              documentsState.valueOrNull ?? const <PetDocument>[],
              (document) => document.petId,
            );
            final weightEntries = _filterByPet(
              weightState.valueOrNull ?? const <WeightEntry>[],
              (entry) => entry.petId,
            );
            final healthEntries = _filterByPet(
              healthState.valueOrNull ?? const <HealthEntry>[],
              (entry) => entry.petId,
            );
            final foodEntries = _filterByPet(
              foodState.valueOrNull ?? const <FoodEntry>[],
              (entry) => entry.petId,
            );
            final medicationEntries = _filterByPet(
              medicationsState.valueOrNull ?? const <MedicationEntry>[],
              (entry) => entry.petId,
            );
            final visitEntries = _filterByPet(
              visitsState.valueOrNull ?? const <VisitEntry>[],
              (entry) => entry.petId,
            );
            final expenseEntries = _filterByPet(
              expensesState.valueOrNull ?? const <ExpenseEntry>[],
              (entry) => entry.petId,
            );

            final reportText = _buildReportText(
              context: context,
              strings: strings,
              pet: pet,
              reminders: reminders,
              documents: documents,
              weightEntries: weightEntries,
              healthEntries: healthEntries,
              foodEntries: foodEntries,
              medicationEntries: medicationEntries,
              visitEntries: visitEntries,
              expenseEntries: expenseEntries,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _TopBar(
                  title: strings.title,
                  onBack: () => context.go('/pets/${pet.id}'),
                ),
                const SizedBox(height: 12),
                _HeroCard(
                  pet: pet,
                  strings: strings,
                ),
                const SizedBox(height: 12),
                _DisclaimerCard(strings: strings),
                const SizedBox(height: 12),
                _CopyReportCard(
                  strings: strings,
                  reportText: reportText,
                ),
                const SizedBox(height: 12),
                _ReportSection(
                  title: strings.petSummary,
                  icon: Icons.pets_outlined,
                  color: Color(pet.colorValue),
                  children: [
                    _ReportRow(label: strings.name, value: pet.name),
                    _ReportRow(
                      label: strings.species,
                      value: pet.species.name,
                    ),
                    _ReportRow(
                      label: strings.age,
                      value: pet.estimatedAgeYears.toString(),
                    ),
                    if (pet.breed != null && pet.breed!.trim().isNotEmpty)
                      _ReportRow(label: strings.breed, value: pet.breed!),
                    _ReportRow(label: strings.sex, value: pet.sex.name),
                    if (pet.microchip != null &&
                        pet.microchip!.trim().isNotEmpty)
                      _ReportRow(
                        label: strings.microchip,
                        value: pet.microchip!,
                      ),
                    if (pet.vetName != null && pet.vetName!.trim().isNotEmpty)
                      _ReportRow(label: strings.vet, value: pet.vetName!),
                  ],
                ),
                _ReportSection(
                  title: strings.reminders,
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFFE49D4F),
                  children: _buildReminderRows(context, reminders, strings),
                ),
                _ReportSection(
                  title: strings.health,
                  icon: Icons.favorite_border_outlined,
                  color: const Color(0xFF8F7AE5),
                  children: _buildHealthRows(context, healthEntries, strings),
                ),
                _ReportSection(
                  title: strings.weight,
                  icon: Icons.monitor_weight_outlined,
                  color: const Color(0xFF72A980),
                  children: _buildWeightRows(context, weightEntries, strings),
                ),
                _ReportSection(
                  title: strings.food,
                  icon: Icons.restaurant_outlined,
                  color: const Color(0xFFCC8E4A),
                  children: _buildFoodRows(context, foodEntries, strings),
                ),
                _ReportSection(
                  title: strings.medications,
                  icon: Icons.medication_outlined,
                  color: const Color(0xFFC85B4A),
                  children: _buildMedicationRows(
                    context,
                    medicationEntries,
                    strings,
                  ),
                ),
                _ReportSection(
                  title: strings.visits,
                  icon: Icons.local_hospital_outlined,
                  color: const Color(0xFF5A8BB8),
                  children: _buildVisitRows(context, visitEntries, strings),
                ),
                _ReportSection(
                  title: strings.expenses,
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF7A6B5B),
                  children: _buildExpenseRows(context, expenseEntries, strings),
                ),
                _ReportSection(
                  title: strings.documents,
                  icon: Icons.folder_outlined,
                  color: const Color(0xFF9C6ADE),
                  children: _buildDocumentRows(context, documents, strings),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Pet? _findPet(List<Pet> pets, String petId) {
    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }

  List<T> _filterByPet<T>(
    List<T> items,
    String Function(T item) petIdSelector,
  ) {
    return items
        .where((item) => petIdSelector(item) == petId)
        .toList(growable: false);
  }

  List<Widget> _buildReminderRows(
    BuildContext context,
    List<Reminder> reminders,
    _ReportStrings strings,
  ) {
    if (reminders.isEmpty) {
      return [_EmptyReportRow(label: strings.noData)];
    }

    final sorted = [...reminders]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return sorted.take(8).map((reminder) {
      return _ReportRow(
        label: reminder.title,
        value:
            '${_formatDateTime(context, reminder.scheduledAt)} · ${reminder.status.name}',
      );
    }).toList(growable: false);
  }

  List<Widget> _buildHealthRows(
    BuildContext context,
    List<HealthEntry> entries,
    _ReportStrings strings,
  ) {
    if (entries.isEmpty) {
      return [_EmptyReportRow(label: strings.noData)];
    }

    final sorted = [...entries]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return sorted.take(8).map((entry) {
      final notes = entry.notes == null || entry.notes!.trim().isEmpty
          ? entry.type.name
          : '${entry.type.name} · ${entry.notes!}';

      return _ReportRow(
        label: entry.title,
        value: '${_formatDateTime(context, entry.recordedAt)} · $notes',
      );
    }).toList(growable: false);
  }

  List<Widget> _buildWeightRows(
    BuildContext context,
    List<WeightEntry> entries,
    _ReportStrings strings,
  ) {
    if (entries.isEmpty) {
      return [_EmptyReportRow(label: strings.noData)];
    }

    final sorted = [...entries]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return sorted.take(6).map((entry) {
      return _ReportRow(
        label: '${entry.weightKg.toStringAsFixed(1)} kg',
        value: _formatDateTime(context, entry.recordedAt),
      );
    }).toList(growable: false);
  }

  List<Widget> _buildFoodRows(
    BuildContext context,
    List<FoodEntry> entries,
    _ReportStrings strings,
  ) {
    if (entries.isEmpty) {
      return [_EmptyReportRow(label: strings.noData)];
    }

    final sorted = [...entries]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return sorted.take(8).map((entry) {
      final quantity = entry.quantity == null || entry.quantity!.trim().isEmpty
          ? ''
          : ' · ${entry.quantity!}';

      return _ReportRow(
        label: entry.foodName,
        value:
            '${_formatDateTime(context, entry.recordedAt)} · ${entry.mealType.name}$quantity',
      );
    }).toList(growable: false);
  }

  List<Widget> _buildMedicationRows(
    BuildContext context,
    List<MedicationEntry> entries,
    _ReportStrings strings,
  ) {
    if (entries.isEmpty) {
      return [_EmptyReportRow(label: strings.noData)];
    }

    final sorted = [...entries]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return sorted.take(8).map((entry) {
      final times = entry.reminderTimes
          .map(
            (time) =>
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          )
          .join(', ');

      final dateRange = entry.endDate == null
          ? _formatDate(context, entry.startDate)
          : '${_formatDate(context, entry.startDate)} - ${_formatDate(context, entry.endDate!)}';

      return _ReportRow(
        label: entry.name,
        value: '$dateRange · ${entry.status.name}${times.isEmpty ? '' : ' · $times'}',
      );
    }).toList(growable: false);
  }

  List<Widget> _buildVisitRows(
    BuildContext context,
    List<VisitEntry> entries,
    _ReportStrings strings,
  ) {
    if (entries.isEmpty) {
      return [_EmptyReportRow(label: strings.noData)];
    }

    final sorted = [...entries]
      ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

    return sorted.take(8).map((entry) {
      final clinic = entry.clinicName == null || entry.clinicName!.trim().isEmpty
          ? ''
          : ' · ${entry.clinicName!}';

      return _ReportRow(
        label: entry.reason,
        value:
            '${_formatDateTime(context, entry.visitDate)} · ${entry.visitType.name}$clinic',
      );
    }).toList(growable: false);
  }

  List<Widget> _buildExpenseRows(
    BuildContext context,
    List<ExpenseEntry> entries,
    _ReportStrings strings,
  ) {
    if (entries.isEmpty) {
      return [_EmptyReportRow(label: strings.noData)];
    }

    final sorted = [...entries]
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    return sorted.take(8).map((entry) {
      return _ReportRow(
        label: entry.description,
        value:
            '${_formatDate(context, entry.expenseDate)} · ${entry.amount.toStringAsFixed(2)} ${entry.currency}',
      );
    }).toList(growable: false);
  }

  List<Widget> _buildDocumentRows(
    BuildContext context,
    List<PetDocument> documents,
    _ReportStrings strings,
  ) {
    if (documents.isEmpty) {
      return [_EmptyReportRow(label: strings.noData)];
    }

    final sorted = [...documents]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted.take(8).map((document) {
      return _ReportRow(
        label: document.title,
        value:
            '${_formatDate(context, document.createdAt)} · ${document.category.name}',
      );
    }).toList(growable: false);
  }

  String _buildReportText({
    required BuildContext context,
    required _ReportStrings strings,
    required Pet pet,
    required List<Reminder> reminders,
    required List<PetDocument> documents,
    required List<WeightEntry> weightEntries,
    required List<HealthEntry> healthEntries,
    required List<FoodEntry> foodEntries,
    required List<MedicationEntry> medicationEntries,
    required List<VisitEntry> visitEntries,
    required List<ExpenseEntry> expenseEntries,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(strings.title);
    buffer.writeln(strings.disclaimer);
    buffer.writeln('');
    buffer.writeln('${strings.petSummary}: ${pet.name}');
    buffer.writeln('${strings.species}: ${pet.species.name}');
    buffer.writeln('${strings.age}: ${pet.estimatedAgeYears}');
    if (pet.breed != null && pet.breed!.trim().isNotEmpty) {
      buffer.writeln('${strings.breed}: ${pet.breed}');
    }
    if (pet.microchip != null && pet.microchip!.trim().isNotEmpty) {
      buffer.writeln('${strings.microchip}: ${pet.microchip}');
    }
    if (pet.vetName != null && pet.vetName!.trim().isNotEmpty) {
      buffer.writeln('${strings.vet}: ${pet.vetName}');
    }

    buffer.writeln('');
    buffer.writeln('${strings.reminders}: ${reminders.length}');
    buffer.writeln('${strings.health}: ${healthEntries.length}');
    buffer.writeln('${strings.weight}: ${weightEntries.length}');
    buffer.writeln('${strings.food}: ${foodEntries.length}');
    buffer.writeln('${strings.medications}: ${medicationEntries.length}');
    buffer.writeln('${strings.visits}: ${visitEntries.length}');
    buffer.writeln('${strings.expenses}: ${expenseEntries.length}');
    buffer.writeln('${strings.documents}: ${documents.length}');

    return buffer.toString();
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();

    return DateFormat.yMMMd(locale).format(date);
  }

  String _formatDateTime(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();

    return DateFormat.yMMMd(locale).add_Hm().format(date);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: PetLifeDesign.softSurface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Indietro',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.pet,
    required this.strings,
  });

  final Pet pet;
  final _ReportStrings strings;

  @override
  Widget build(BuildContext context) {
    return _SoftContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Color(pet.colorValue).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.summarize_outlined,
                color: Color(pet.colorValue),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pet.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({
    required this.strings,
  });

  final _ReportStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: const Color(0xFFF0D6BF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFB87841),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.disclaimer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7B5537),
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyReportCard extends StatelessWidget {
  const _CopyReportCard({
    required this.strings,
    required this.reportText,
  });

  final _ReportStrings strings;
  final String reportText;

  @override
  Widget build(BuildContext context) {
    return _SoftContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.copyDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: reportText),
                );

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.reportCopied)),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: Text(strings.copyReport),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _SoftContainer(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReportRow extends StatelessWidget {
  const _EmptyReportRow({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _PetNotFoundState extends StatelessWidget {
  const _PetNotFoundState({
    required this.title,
    required this.buttonLabel,
  });

  final String title;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _SoftContainer(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error.toString(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SoftContainer extends StatelessWidget {
  const _SoftContainer({
    required this.child,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: child,
    );
  }
}

class _ReportStrings {
  const _ReportStrings({
    required this.title,
    required this.disclaimer,
    required this.copyDescription,
    required this.copyReport,
    required this.reportCopied,
    required this.petSummary,
    required this.name,
    required this.species,
    required this.age,
    required this.breed,
    required this.sex,
    required this.microchip,
    required this.vet,
    required this.reminders,
    required this.documents,
    required this.weight,
    required this.health,
    required this.food,
    required this.medications,
    required this.visits,
    required this.expenses,
    required this.noData,
  });

  final String title;
  final String disclaimer;
  final String copyDescription;
  final String copyReport;
  final String reportCopied;
  final String petSummary;
  final String name;
  final String species;
  final String age;
  final String breed;
  final String sex;
  final String microchip;
  final String vet;
  final String reminders;
  final String documents;
  final String weight;
  final String health;
  final String food;
  final String medications;
  final String visits;
  final String expenses;
  final String noData;

  static _ReportStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _ReportStrings(
        title: 'Non-diagnostic report',
        disclaimer:
            'This report is only an organizational summary of data entered by you. It does not provide diagnosis, triage, medical advice or treatment recommendations and does not replace your veterinarian.',
        copyDescription:
            'Copy this summary to prepare notes before a veterinary visit.',
        copyReport: 'Copy report',
        reportCopied: 'Report copied',
        petSummary: 'Pet summary',
        name: 'Name',
        species: 'Species',
        age: 'Age',
        breed: 'Breed',
        sex: 'Sex',
        microchip: 'Microchip',
        vet: 'Vet',
        reminders: 'Reminders',
        documents: 'Documents',
        weight: 'Weight',
        health: 'Health',
        food: 'Food',
        medications: 'Medications',
        visits: 'Visits',
        expenses: 'Expenses',
        noData: 'No data recorded yet.',
      );
    }

    return const _ReportStrings(
      title: 'Report non diagnostico',
      disclaimer:
          'Questo report è solo un riepilogo organizzativo dei dati inseriti da te. Non fornisce diagnosi, triage, consigli medici o raccomandazioni terapeutiche e non sostituisce il veterinario.',
      copyDescription:
          'Copia questo riepilogo per preparare le note prima di una visita veterinaria.',
      copyReport: 'Copia report',
      reportCopied: 'Report copiato',
      petSummary: 'Riepilogo pet',
      name: 'Nome',
      species: 'Specie',
      age: 'Età',
      breed: 'Razza',
      sex: 'Sesso',
      microchip: 'Microchip',
      vet: 'Vet',
      reminders: 'Promemoria',
      documents: 'Documenti',
      weight: 'Peso',
      health: 'Salute',
      food: 'Alimentazione',
      medications: 'Farmaci',
      visits: 'Visite',
      expenses: 'Spese',
      noData: 'Nessun dato registrato.',
    );
  }
}