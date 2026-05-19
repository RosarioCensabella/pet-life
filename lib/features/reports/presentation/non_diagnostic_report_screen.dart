import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../documents/application/pet_document_controller.dart';
import '../../expenses/application/expense_controller.dart';
import '../../food/application/food_controller.dart';
import '../../health/application/health_controller.dart';
import '../../health/domain/health_entry.dart';
import '../../medications/application/medication_controller.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../visits/application/visit_controller.dart';
import '../../weight/application/weight_controller.dart';

class NonDiagnosticReportScreen extends ConsumerWidget {
  const NonDiagnosticReportScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = _ReportStrings.of(context);
    final petsState = ref.watch(petControllerProvider);

    final reminderState = ref.watch(reminderControllerProvider);
    final documentState = ref.watch(petDocumentControllerProvider);
    final weightState = ref.watch(weightControllerProvider);
    final healthState = ref.watch(healthControllerProvider);
    final foodState = ref.watch(foodControllerProvider);
    final medicationState = ref.watch(medicationControllerProvider);
    final visitState = ref.watch(visitControllerProvider);
    final expenseState = ref.watch(expenseControllerProvider);

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(strings.title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(strings.title)),
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
        final pet = _findPet(pets, petId);

        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: Text(strings.title)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(strings.petNotFound),
              ),
            ),
          );
        }

        final generatedAt = DateTime.now();

        final reminderCount = _countForPet(
          reminderState,
          (entry) => entry.petId == pet.id,
        );

        final documentCount = _countForPet(
          documentState,
          (entry) => entry.petId == pet.id,
        );

        final weightCount = _countForPet(
          weightState,
          (entry) => entry.petId == pet.id,
        );

        final healthDiaryCount = _countForPet(
          healthState,
          (entry) => entry.petId == pet.id && entry.type == HealthEntryType.diary,
        );

        final symptomCount = _countForPet(
          healthState,
          (entry) =>
              entry.petId == pet.id && entry.type == HealthEntryType.symptom,
        );

        final foodCount = _countForPet(
          foodState,
          (entry) => entry.petId == pet.id,
        );

        final medicationCount = _countForPet(
          medicationState,
          (entry) => entry.petId == pet.id,
        );

        final visitCount = _countForPet(
          visitState,
          (entry) => entry.petId == pet.id,
        );

        final petExpenses = expenseState.valueOrNull
                ?.where((entry) => entry.petId == pet.id)
                .toList(growable: false) ??
            const [];

        final expenseCount = petExpenses.length;
        final expenseTotals = _expenseTotals(petExpenses);
        final reportText = _buildReportText(
          context: context,
          strings: strings,
          pet: pet,
          generatedAt: generatedAt,
          reminderCount: reminderCount,
          documentCount: documentCount,
          weightCount: weightCount,
          healthDiaryCount: healthDiaryCount,
          symptomCount: symptomCount,
          foodCount: foodCount,
          medicationCount: medicationCount,
          visitCount: visitCount,
          expenseCount: expenseCount,
          expenseTotals: expenseTotals,
        );

        return Scaffold(
          appBar: AppBar(title: Text(strings.title)),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _DisclaimerCard(strings: strings),
              _ReportHeaderCard(
                pet: pet,
                generatedAt: generatedAt,
                strings: strings,
              ),
              _ReportSectionCard(
                title: strings.healthSection,
                children: [
                  _ReportMetricTile(
                    label: strings.reminders,
                    value: reminderCount.toString(),
                  ),
                  _ReportMetricTile(
                    label: strings.visits,
                    value: visitCount.toString(),
                  ),
                  _ReportMetricTile(
                    label: strings.medications,
                    value: medicationCount.toString(),
                  ),
                  _ReportMetricTile(
                    label: strings.healthDiary,
                    value: healthDiaryCount.toString(),
                  ),
                  _ReportMetricTile(
                    label: strings.symptoms,
                    value: symptomCount.toString(),
                  ),
                ],
              ),
              _ReportSectionCard(
                title: strings.organizationSection,
                children: [
                  _ReportMetricTile(
                    label: strings.documents,
                    value: documentCount.toString(),
                  ),
                  _ReportMetricTile(
                    label: strings.weight,
                    value: weightCount.toString(),
                  ),
                  _ReportMetricTile(
                    label: strings.food,
                    value: foodCount.toString(),
                  ),
                  _ReportMetricTile(
                    label: strings.expenses,
                    value: expenseCount.toString(),
                  ),
                  _ReportMetricTile(
                    label: strings.expenseTotals,
                    value: expenseTotals.isEmpty
                        ? strings.noExpenses
                        : expenseTotals,
                  ),
                ],
              ),
              _CopyReportCard(
                reportText: reportText,
                strings: strings,
              ),
            ],
          ),
        );
      },
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



  int _countForPet<T>(
    AsyncValue<List<T>> state,
    bool Function(T entry) matches,
 ) {
    final entries = state.valueOrNull ?? List<T>.empty(growable: false);

    return entries.where(matches).length;
 }



  String _expenseTotals(List<dynamic> expenses) {
    final totalsByCurrency = <String, double>{};

    for (final expense in expenses) {
      totalsByCurrency[expense.currency as String] =
          (totalsByCurrency[expense.currency as String] ?? 0) +
              (expense.amount as double);
    }

    if (totalsByCurrency.isEmpty) {
      return '';
    }

    return totalsByCurrency.entries
        .map((entry) => '${entry.value.toStringAsFixed(2)} ${entry.key}')
        .join(' · ');
  }

  String _buildReportText({
    required BuildContext context,
    required _ReportStrings strings,
    required Pet pet,
    required DateTime generatedAt,
    required int reminderCount,
    required int documentCount,
    required int weightCount,
    required int healthDiaryCount,
    required int symptomCount,
    required int foodCount,
    required int medicationCount,
    required int visitCount,
    required int expenseCount,
    required String expenseTotals,
  }) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final generatedAtLabel = DateFormat.yMMMd(locale).add_Hm().format(
          generatedAt,
        );

    return '''
${strings.title}
${strings.generatedFor}: ${pet.name}
${strings.generatedAt}: $generatedAtLabel

${strings.disclaimer}

${strings.healthSection}
- ${strings.reminders}: $reminderCount
- ${strings.visits}: $visitCount
- ${strings.medications}: $medicationCount
- ${strings.healthDiary}: $healthDiaryCount
- ${strings.symptoms}: $symptomCount

${strings.organizationSection}
- ${strings.documents}: $documentCount
- ${strings.weight}: $weightCount
- ${strings.food}: $foodCount
- ${strings.expenses}: $expenseCount
- ${strings.expenseTotals}: ${expenseTotals.isEmpty ? strings.noExpenses : expenseTotals}
''';
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({
    required this.strings,
  });

  final _ReportStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(strings.disclaimer),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportHeaderCard extends StatelessWidget {
  const _ReportHeaderCard({
    required this.pet,
    required this.generatedAt,
    required this.strings,
  });

  final Pet pet;
  final DateTime generatedAt;
  final _ReportStrings strings;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final generatedAtLabel = DateFormat.yMMMd(locale).add_Hm().format(
          generatedAt,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.pets,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text('${strings.generatedAt}: $generatedAtLabel'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  const _ReportSectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReportMetricTile extends StatelessWidget {
  const _ReportMetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _CopyReportCard extends StatelessWidget {
  const _CopyReportCard({
    required this.reportText,
    required this.strings,
  });

  final String reportText;
  final _ReportStrings strings;

  Future<void> _copyReport(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: reportText));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.reportCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FilledButton.icon(
          onPressed: () => _copyReport(context),
          icon: const Icon(Icons.copy_outlined),
          label: Text(strings.copyReport),
        ),
      ),
    );
  }
}

class _ReportStrings {
  const _ReportStrings({
    required this.title,
    required this.generatedFor,
    required this.generatedAt,
    required this.healthSection,
    required this.organizationSection,
    required this.reminders,
    required this.visits,
    required this.medications,
    required this.healthDiary,
    required this.symptoms,
    required this.documents,
    required this.weight,
    required this.food,
    required this.expenses,
    required this.expenseTotals,
    required this.noExpenses,
    required this.copyReport,
    required this.reportCopied,
    required this.petNotFound,
    required this.disclaimer,
  });

  final String title;
  final String generatedFor;
  final String generatedAt;
  final String healthSection;
  final String organizationSection;
  final String reminders;
  final String visits;
  final String medications;
  final String healthDiary;
  final String symptoms;
  final String documents;
  final String weight;
  final String food;
  final String expenses;
  final String expenseTotals;
  final String noExpenses;
  final String copyReport;
  final String reportCopied;
  final String petNotFound;
  final String disclaimer;

  static _ReportStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _ReportStrings(
        title: 'Non-diagnostic report',
        generatedFor: 'Generated for',
        generatedAt: 'Generated at',
        healthSection: 'Health organization',
        organizationSection: 'General organization',
        reminders: 'Reminders',
        visits: 'Visits',
        medications: 'Medications',
        healthDiary: 'Health diary',
        symptoms: 'Symptoms',
        documents: 'Documents',
        weight: 'Weight entries',
        food: 'Food entries',
        expenses: 'Expenses',
        expenseTotals: 'Expense totals',
        noExpenses: 'No expenses recorded',
        copyReport: 'Copy report',
        reportCopied: 'Report copied',
        petNotFound: 'Pet not found',
        disclaimer:
            'This report is only an organizational summary. Pet Life does not generate diagnoses, interpret symptoms, provide triage, prescribe treatments or replace your veterinarian.',
      );
    }

    return const _ReportStrings(
      title: 'Report non diagnostico',
      generatedFor: 'Generato per',
      generatedAt: 'Generato il',
      healthSection: 'Organizzazione salute',
      organizationSection: 'Organizzazione generale',
      reminders: 'Promemoria',
      visits: 'Visite',
      medications: 'Farmaci',
      healthDiary: 'Diario salute',
      symptoms: 'Sintomi',
      documents: 'Documenti',
      weight: 'Registrazioni peso',
      food: 'Registrazioni alimentazione',
      expenses: 'Spese',
      expenseTotals: 'Totali spese',
      noExpenses: 'Nessuna spesa registrata',
      copyReport: 'Copia report',
      reportCopied: 'Report copiato',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Questo report è solo un riepilogo organizzativo. Pet Life non genera diagnosi, non interpreta sintomi, non fa triage, non prescrive terapie e non sostituisce il veterinario.',
    );
  }
}