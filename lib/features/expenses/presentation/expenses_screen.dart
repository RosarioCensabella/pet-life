import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
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

    return Scaffold(
      body: SafeArea(
        child: petsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final pet = _findPet(pets, widget.petId);

            if (pet == null) {
              return _PetNotFoundState(
                title: strings.petNotFound,
                onBack: () => context.go('/home'),
              );
            }

            return expenseState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (entries) {
                final petEntries = entries
                    .where((entry) => entry.petId == pet.id)
                    .toList(growable: false)
                  ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _TopBar(
                      title: strings.expensesTitle,
                      onBack: () => context.go('/pets/${pet.id}'),
                    ),
                    const SizedBox(height: 12),
                    _HeroCard(
                      strings: strings,
                      entries: petEntries,
                    ),
                    const SizedBox(height: 12),
                    _DisclaimerCard(strings: strings),
                    const SizedBox(height: 12),
                    _ExpenseSummaryCard(
                      entries: petEntries,
                      strings: strings,
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: strings.historyTitle,
                      count: petEntries.length,
                    ),
                    const SizedBox(height: 8),
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
            );
          },
        ),
      ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final strings = _ExpenseStrings.of(context);

    return Row(
      children: [
        Material(
          color: PetLifeDesign.softSurface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: strings.back,
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
    required this.strings,
    required this.entries,
  });

  final _ExpenseStrings strings;
  final List<ExpenseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final totalText = entries.isEmpty ? strings.totalTracked : _totalText(entries, strings);

    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.primaryBrown,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        boxShadow: [PetLifeDesign.softShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.expensesTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.heroSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DarkPill(
                        icon: Icons.payments_outlined,
                        label: totalText,
                      ),
                      _DarkPill(
                        icon: Icons.list_alt_outlined,
                        label: '${entries.length} ${strings.entriesLabel}',
                      ),
                    ],
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

class _DarkPill extends StatelessWidget {
  const _DarkPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
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

  final _ExpenseStrings strings;

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

class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard({
    required this.entries,
    required this.strings,
  });

  final List<ExpenseEntry> entries;
  final _ExpenseStrings strings;

  @override
  Widget build(BuildContext context) {
    final totalText = _totalText(entries, strings);

    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF7A6B5B).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: Color(0xFF7A6B5B),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.totalTracked,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: PetLifeDesign.secondaryBrown,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    totalText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.totalSummarySubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
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

    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(
                icon: Icons.add_rounded,
                title: strings.addEntry,
                subtitle: strings.formSubtitle,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenseCategory>(
                key: ValueKey('expense-category-$selectedCategory'),
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: strings.categoryLabel,
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
                key: ValueKey('expense-currency-$selectedCurrency'),
                initialValue: selectedCurrency,
                decoration: InputDecoration(
                  labelText: strings.currencyLabel,
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
              _DateActionTile(
                icon: Icons.event_outlined,
                title: strings.expenseDate,
                value: expenseDateLabel,
                onTap: onSelectExpenseDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: vendorController,
                decoration: InputDecoration(
                  labelText: strings.vendorLabel,
                  hintText: strings.vendorHint,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: strings.notesLabel,
                  hintText: strings.notesHint,
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

class _DateActionTile extends StatelessWidget {
  const _DateActionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PetLifeDesign.softSurface.withValues(alpha: 0.76),
      borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: PetLifeDesign.secondaryBrown,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF7A6B5B).withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF7A6B5B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: PetLifeDesign.softSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: PetLifeDesign.secondaryBrown,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ],
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
    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF7A6B5B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: Color(0xFF7A6B5B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.emptyDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
    final accentColor = _colorForCategory(entry.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(PetLifeDesign.radiusLarge),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _iconForCategory(entry.category),
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _InfoPill(
                                color: accentColor,
                                icon: _iconForCategory(entry.category),
                                label: strings.categoryLabelFor(
                                  entry.category,
                                ),
                              ),
                              _InfoPill(
                                color: PetLifeDesign.secondaryBrown,
                                icon: Icons.schedule_outlined,
                                label: expenseDateLabel,
                              ),
                              _InfoPill(
                                color: accentColor,
                                icon: Icons.pets_outlined,
                                label: entry.petName,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_formatAmount(entry.amount)} ${entry.currency}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: PetLifeDesign.primaryBrown,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          if (entry.vendor != null &&
                              entry.vendor!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${strings.vendorShort}: ${entry.vendor!}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (entry.notes != null &&
                              entry.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              entry.notes!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
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
          ],
        ),
      ),
    );
  }

  Color _colorForCategory(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.vet => const Color(0xFF5A8BB8),
      ExpenseCategory.medication => const Color(0xFFC85B4A),
      ExpenseCategory.food => const Color(0xFFCC8E4A),
      ExpenseCategory.grooming => const Color(0xFF8F7AE5),
      ExpenseCategory.insurance => const Color(0xFF7A6B5B),
      ExpenseCategory.documents => const Color(0xFF9C6ADE),
      ExpenseCategory.accessories => const Color(0xFFE49D4F),
      ExpenseCategory.other => const Color(0xFF72A980),
    };
  }

  IconData _iconForCategory(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.vet => Icons.local_hospital_outlined,
      ExpenseCategory.medication => Icons.medication_outlined,
      ExpenseCategory.food => Icons.restaurant_outlined,
      ExpenseCategory.grooming => Icons.content_cut_outlined,
      ExpenseCategory.insurance => Icons.verified_user_outlined,
      ExpenseCategory.documents => Icons.folder_outlined,
      ExpenseCategory.accessories => Icons.shopping_bag_outlined,
      ExpenseCategory.other => Icons.receipt_long_outlined,
    };
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _PetNotFoundState extends StatelessWidget {
  const _PetNotFoundState({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _SoftCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onBack,
                  child: const Text('OK'),
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

String _formatAmount(double value) {
  return value.toStringAsFixed(2);
}

String _totalText(List<ExpenseEntry> entries, _ExpenseStrings strings) {
  final totalsByCurrency = <String, double>{};

  for (final entry in entries) {
    totalsByCurrency[entry.currency] =
        (totalsByCurrency[entry.currency] ?? 0) + entry.amount;
  }

  if (totalsByCurrency.isEmpty) {
    return strings.noExpensesSummary;
  }

  return totalsByCurrency.entries
      .map(
        (entry) => '${_formatAmount(entry.value)} ${entry.key}',
      )
      .join(' · ');
}

class _ExpenseStrings {
  const _ExpenseStrings({
    required this.back,
    required this.expensesTitle,
    required this.heroSubtitle,
    required this.entriesLabel,
    required this.historyTitle,
    required this.formSubtitle,
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
    required this.totalSummarySubtitle,
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

  final String back;
  final String expensesTitle;
  final String heroSubtitle;
  final String entriesLabel;
  final String historyTitle;
  final String formSubtitle;
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
  final String totalSummarySubtitle;
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
        back: 'Back',
        expensesTitle: 'Expenses',
        heroSubtitle:
            'Keep pet-related costs organized by category, date and provider.',
        entriesLabel: 'entries',
        historyTitle: 'Expense history',
        formSubtitle: 'Add a cost with category, amount and optional notes.',
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
        totalSummarySubtitle: 'Grouped by currency',
        noExpensesSummary: 'No expenses recorded yet',
        emptyTitle: 'No expenses',
        emptyDescription: 'Add expenses to keep pet-related costs organized.',
        deleteEntryTitle: 'Delete this expense?',
        deleteEntryMessage:
            'This removes the expense from the local history.',
        entryDeleted: 'Expense deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'Expense tracking is only for organization. Pet Life does not provide tax, insurance or financial advice.',
      );
    }

    return const _ExpenseStrings(
      back: 'Indietro',
      expensesTitle: 'Spese',
      heroSubtitle:
          'Tieni ordinati i costi del pet per categoria, data e fornitore.',
      entriesLabel: 'voci',
      historyTitle: 'Storico spese',
      formSubtitle: 'Aggiungi costo, categoria, importo e note opzionali.',
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
      totalSummarySubtitle: 'Raggruppato per valuta',
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