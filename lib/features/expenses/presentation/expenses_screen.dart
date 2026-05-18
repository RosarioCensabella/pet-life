import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../application/expense_controller.dart';
import '../domain/expense_entry.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.vet;
  String _selectedCurrency = 'EUR';
  DateTime _expenseDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectExpenseDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _expenseDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _expenseDate.hour,
        _expenseDate.minute,
      );
    });
  }

  Future<void> _saveEntry(Pet pet, _ExpenseStrings strings) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final now = DateTime.now();
    final normalizedAmount = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.parse(normalizedAmount);
    final vendor = _vendorController.text.trim();
    final notes = _notesController.text.trim();

    final entry = ExpenseEntry(
      id: 'expense-${now.microsecondsSinceEpoch}',
      petId: pet.id,
      petName: pet.name,
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      amount: amount,
      currency: _selectedCurrency,
      expenseDate: _expenseDate,
      createdAt: now,
      vendor: vendor.isEmpty ? null : vendor,
      notes: notes.isEmpty ? null : notes,
    );

    await ref.read(expenseControllerProvider.notifier).addEntry(entry);

    if (!mounted) {
      return;
    }

    _descriptionController.clear();
    _amountController.clear();
    _vendorController.clear();
    _notesController.clear();

    setState(() {
      _selectedCategory = ExpenseCategory.vet;
      _selectedCurrency = 'EUR';
      _expenseDate = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entrySaved)),
    );
  }

  Future<void> _confirmDelete(
    ExpenseEntry entry,
    _ExpenseStrings strings,
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

    if (shouldDelete != true || !mounted) {
      return;
    }

    await ref.read(expenseControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entryDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _ExpenseStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final expenseState = ref.watch(expenseControllerProvider);

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(strings.expensesTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(strings.expensesTitle)),
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
            appBar: AppBar(title: Text(strings.expensesTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(strings.petNotFound),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(strings.expensesTitle),
          ),
          body: expenseState.when(
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
                  .where((entry) => entry.petId == pet.id)
                  .toList(growable: false);

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _DisclaimerCard(strings: strings),
                  _ExpenseSummaryCard(
                    entries: petEntries,
                    strings: strings,
                  ),
                  _AddExpenseEntryCard(
                    formKey: _formKey,
                    descriptionController: _descriptionController,
                    amountController: _amountController,
                    vendorController: _vendorController,
                    notesController: _notesController,
                    selectedCategory: _selectedCategory,
                    selectedCurrency: _selectedCurrency,
                    expenseDate: _expenseDate,
                    strings: strings,
                    onCategoryChanged: (category) {
                      if (category == null) {
                        return;
                      }

                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    onCurrencyChanged: (currency) {
                      if (currency == null) {
                        return;
                      }

                      setState(() {
                        _selectedCurrency = currency;
                      });
                    },
                    onSelectExpenseDate: _selectExpenseDate,
                    onSave: () => _saveEntry(pet, strings),
                  ),
                  if (petEntries.isEmpty)
                    _EmptyExpenseCard(strings: strings)
                  else
                    ...petEntries.map(
                      (entry) => _ExpenseEntryCard(
                        entry: entry,
                        strings: strings,
                        onDelete: () => _confirmDelete(entry, strings),
                      ),
                    ),
                ],
              );
            },
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
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({
    required this.strings,
  });

  final _ExpenseStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
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

class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard({
    required this.entries,
    required this.strings,
  });

  final List<ExpenseEntry> entries;
  final _ExpenseStrings strings;

  @override
  Widget build(BuildContext context) {
    final totalsByCurrency = <String, double>{};

    for (final entry in entries) {
      totalsByCurrency[entry.currency] =
          (totalsByCurrency[entry.currency] ?? 0) + entry.amount;
    }

    final totalText = totalsByCurrency.isEmpty
        ? strings.noExpensesSummary
        : totalsByCurrency.entries
            .map(
              (entry) => '${_formatAmount(entry.value)} ${entry.key}',
            )
            .join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.totalTracked,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
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

class _AddExpenseEntryCard extends StatelessWidget {
  const _AddExpenseEntryCard({
    required this.formKey,
    required this.descriptionController,
    required this.amountController,
    required this.vendorController,
    required this.notesController,
    required this.selectedCategory,
    required this.selectedCurrency,
    required this.expenseDate,
    required this.strings,
    required this.onCategoryChanged,
    required this.onCurrencyChanged,
    required this.onSelectExpenseDate,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final TextEditingController vendorController;
  final TextEditingController notesController;
  final ExpenseCategory selectedCategory;
  final String selectedCurrency;
  final DateTime expenseDate;
  final _ExpenseStrings strings;
  final ValueChanged<ExpenseCategory?> onCategoryChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final VoidCallback onSelectExpenseDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final expenseDateLabel = DateFormat.yMMMd(locale).format(expenseDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.addEntry,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: strings.categoryLabel,
                  border: const OutlineInputBorder(),
                ),
                items: ExpenseCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(strings.categoryLabelFor(category)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onCategoryChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: strings.descriptionLabel,
                  hintText: strings.descriptionHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return strings.descriptionRequired;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: strings.amountLabel,
                  hintText: strings.amountHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                validator: (value) {
                  final normalized = value?.trim().replaceAll(',', '.') ?? '';

                  if (normalized.isEmpty) {
                    return strings.amountRequired;
                  }

                  final parsed = double.tryParse(normalized);

                  if (parsed == null || parsed < 0) {
                    return strings.amountInvalid;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCurrency,
                decoration: InputDecoration(
                  labelText: strings.currencyLabel,
                  border: const OutlineInputBorder(),
                ),
                items: const ['EUR', 'USD', 'GBP', 'CHF']
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onCurrencyChanged,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSelectExpenseDate,
                icon: const Icon(Icons.event_outlined),
                label: Text('${strings.expenseDate}: $expenseDateLabel'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: vendorController,
                decoration: InputDecoration(
                  labelText: strings.vendorLabel,
                  hintText: strings.vendorHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: strings.notesLabel,
                  hintText: strings.notesHint,
                  border: const OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_outlined),
                label: Text(strings.saveEntry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyExpenseCard extends StatelessWidget {
  const _EmptyExpenseCard({
    required this.strings,
  });

  final _ExpenseStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              strings.emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.emptyDescription,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseEntryCard extends StatelessWidget {
  const _ExpenseEntryCard({
    required this.entry,
    required this.strings,
    required this.onDelete,
  });

  final ExpenseEntry entry;
  final _ExpenseStrings strings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final expenseDateLabel = DateFormat.yMMMd(locale).format(entry.expenseDate);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(entry.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${strings.categoryLabelFor(entry.category)} · $expenseDateLabel',
            ),
            if (entry.vendor != null && entry.vendor!.trim().isNotEmpty)
              Text('${strings.vendorShort}: ${entry.vendor!}'),
            if (entry.notes != null && entry.notes!.trim().isNotEmpty)
              Text(entry.notes!),
          ],
        ),
        trailing: SizedBox(
          width: 156,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${_formatAmount(entry.amount)} ${entry.currency}',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              IconButton(
                tooltip: strings.delete,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatAmount(double value) {
  return value.toStringAsFixed(2);
}

class _ExpenseStrings {
  const _ExpenseStrings({
    required this.expensesTitle,
    required this.addEntry,
    required this.categoryLabel,
    required this.categoryVet,
    required this.categoryMedication,
    required this.categoryFood,
    required this.categoryGrooming,
    required this.categoryInsurance,
    required this.categoryDocuments,
    required this.categoryAccessories,
    required this.categoryOther,
    required this.descriptionLabel,
    required this.descriptionHint,
    required this.descriptionRequired,
    required this.amountLabel,
    required this.amountHint,
    required this.amountRequired,
    required this.amountInvalid,
    required this.currencyLabel,
    required this.expenseDate,
    required this.vendorLabel,
    required this.vendorHint,
    required this.vendorShort,
    required this.notesLabel,
    required this.notesHint,
    required this.saveEntry,
    required this.entrySaved,
    required this.totalTracked,
    required this.noExpensesSummary,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.deleteEntryTitle,
    required this.deleteEntryMessage,
    required this.entryDeleted,
    required this.delete,
    required this.cancel,
    required this.petNotFound,
    required this.disclaimer,
  });

  final String expensesTitle;
  final String addEntry;
  final String categoryLabel;
  final String categoryVet;
  final String categoryMedication;
  final String categoryFood;
  final String categoryGrooming;
  final String categoryInsurance;
  final String categoryDocuments;
  final String categoryAccessories;
  final String categoryOther;
  final String descriptionLabel;
  final String descriptionHint;
  final String descriptionRequired;
  final String amountLabel;
  final String amountHint;
  final String amountRequired;
  final String amountInvalid;
  final String currencyLabel;
  final String expenseDate;
  final String vendorLabel;
  final String vendorHint;
  final String vendorShort;
  final String notesLabel;
  final String notesHint;
  final String saveEntry;
  final String entrySaved;
  final String totalTracked;
  final String noExpensesSummary;
  final String emptyTitle;
  final String emptyDescription;
  final String deleteEntryTitle;
  final String deleteEntryMessage;
  final String entryDeleted;
  final String delete;
  final String cancel;
  final String petNotFound;
  final String disclaimer;

  String categoryLabelFor(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.vet => categoryVet,
      ExpenseCategory.medication => categoryMedication,
      ExpenseCategory.food => categoryFood,
      ExpenseCategory.grooming => categoryGrooming,
      ExpenseCategory.insurance => categoryInsurance,
      ExpenseCategory.documents => categoryDocuments,
      ExpenseCategory.accessories => categoryAccessories,
      ExpenseCategory.other => categoryOther,
    };
  }

  static _ExpenseStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _ExpenseStrings(
        expensesTitle: 'Expenses',
        addEntry: 'Add expense',
        categoryLabel: 'Category',
        categoryVet: 'Vet',
        categoryMedication: 'Medication',
        categoryFood: 'Food',
        categoryGrooming: 'Grooming',
        categoryInsurance: 'Insurance',
        categoryDocuments: 'Documents',
        categoryAccessories: 'Accessories',
        categoryOther: 'Other',
        descriptionLabel: 'Description',
        descriptionHint: 'E.g. Vet visit',
        descriptionRequired: 'Enter a description',
        amountLabel: 'Amount',
        amountHint: 'E.g. 49.90',
        amountRequired: 'Enter the amount',
        amountInvalid: 'Enter a valid amount',
        currencyLabel: 'Currency',
        expenseDate: 'Date',
        vendorLabel: 'Vendor / provider',
        vendorHint: 'Optional',
        vendorShort: 'Vendor',
        notesLabel: 'Notes',
        notesHint: 'Optional',
        saveEntry: 'Save expense',
        entrySaved: 'Expense saved',
        totalTracked: 'Total tracked',
        noExpensesSummary: 'No expenses recorded yet',
        emptyTitle: 'No expenses',
        emptyDescription: 'Add expenses to keep pet-related costs organized.',
        deleteEntryTitle: 'Delete this expense?',
        deleteEntryMessage: 'This removes the expense from the local history.',
        entryDeleted: 'Expense deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'Expense tracking is only for organization. Pet Life does not provide tax, insurance or financial advice.',
      );
    }

    return const _ExpenseStrings(
      expensesTitle: 'Spese',
      addEntry: 'Aggiungi spesa',
      categoryLabel: 'Categoria',
      categoryVet: 'Veterinario',
      categoryMedication: 'Farmaci',
      categoryFood: 'Alimentazione',
      categoryGrooming: 'Toelettatura',
      categoryInsurance: 'Assicurazione',
      categoryDocuments: 'Documenti',
      categoryAccessories: 'Accessori',
      categoryOther: 'Altro',
      descriptionLabel: 'Descrizione',
      descriptionHint: 'Es. Visita veterinaria',
      descriptionRequired: 'Inserisci una descrizione',
      amountLabel: 'Importo',
      amountHint: 'Es. 49,90',
      amountRequired: 'Inserisci importo',
      amountInvalid: 'Inserisci un importo valido',
      currencyLabel: 'Valuta',
      expenseDate: 'Data',
      vendorLabel: 'Fornitore / struttura',
      vendorHint: 'Opzionale',
      vendorShort: 'Fornitore',
      notesLabel: 'Note',
      notesHint: 'Opzionale',
      saveEntry: 'Salva spesa',
      entrySaved: 'Spesa salvata',
      totalTracked: 'Totale registrato',
      noExpensesSummary: 'Nessuna spesa registrata',
      emptyTitle: 'Nessuna spesa',
      emptyDescription:
          'Aggiungi spese per tenere ordinati i costi legati al pet.',
      deleteEntryTitle: 'Eliminare questa spesa?',
      deleteEntryMessage: 'La spesa verrà rimossa dallo storico locale.',
      entryDeleted: 'Spesa eliminata',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Il tracking delle spese serve solo per organizzazione. Pet Life non fornisce consulenza fiscale, assicurativa o finanziaria.',
    );
  }
}