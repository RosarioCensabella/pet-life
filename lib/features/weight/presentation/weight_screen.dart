import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../application/weight_controller.dart';
import '../domain/weight_entry.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  @override
  Widget build(BuildContext context) {
    final petsState = ref.watch(petControllerProvider);
    final weightState = ref.watch(weightControllerProvider);

    return Scaffold(
      backgroundColor: _WeightPalette.background,
      body: SafeArea(
        child: petsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final pet = _findPet(pets, widget.petId);

            if (pet == null) {
              return _PetNotFoundState(
                onBack: () => context.go('/home'),
              );
            }

            return weightState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (entries) {
                final petEntries = entries
                    .where((entry) => entry.petId == pet.id)
                    .toList(growable: false)
                  ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    _Header(
                      petName: pet.name,
                      onBack: () => context.go('/pets/${pet.id}'),
                      onAdd: () => _openWeightEditor(pet: pet),
                    ),
                    const SizedBox(height: 18),
                    _WeightOverviewCard(
                      entries: petEntries,
                    ),
                    const SizedBox(height: 14),
                    _DisclaimerCard(),
                    const SizedBox(height: 14),
                    Text(
                      'Storico',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: _WeightPalette.darkText,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (petEntries.isEmpty)
                      _EmptyWeightCard(
                        onAdd: () => _openWeightEditor(pet: pet),
                      )
                    else
                      _HistoryList(
                        entries: petEntries,
                        onEdit: (entry) => _openWeightEditor(
                          pet: pet,
                          entry: entry,
                        ),
                        onDelete: _confirmDelete,
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

  Future<void> _openWeightEditor({
    required Pet pet,
    WeightEntry? entry,
  }) async {
    final result = await showModalBottomSheet<_WeightEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WeightEditorSheet(
          pet: pet,
          entry: entry,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    switch (result.action) {
      case _WeightEditorAction.save:
        await _saveWeight(
          pet: pet,
          previousEntry: entry,
          draft: result.draft!,
        );
      case _WeightEditorAction.delete:
        if (entry != null) {
          await _deleteWeight(entry);
        }
    }
  }

  Future<void> _saveWeight({
    required Pet pet,
    required WeightEntry? previousEntry,
    required _WeightDraft draft,
  }) async {
    final now = DateTime.now();

    final entry = WeightEntry(
      id: previousEntry?.id ?? 'weight-${now.microsecondsSinceEpoch}',
      petId: pet.id,
      petName: pet.name,
      weightKg: draft.weightKg,
      recordedAt: draft.recordedAt,
      createdAt: previousEntry?.createdAt ?? now,
      notes: draft.notes.trim().isEmpty ? null : draft.notes.trim(),
    );

    if (previousEntry == null) {
      await ref.read(weightControllerProvider.notifier).addEntry(entry);
    } else {
      await ref.read(weightControllerProvider.notifier).updateEntry(entry);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          previousEntry == null ? 'Peso salvato' : 'Peso aggiornato',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(WeightEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare questa misurazione?'),
          content: const Text(
            'La misurazione verrà rimossa dallo storico del peso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteWeight(entry);
    }
  }

  Future<void> _deleteWeight(WeightEntry entry) async {
    await ref.read(weightControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peso eliminato')),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.petName,
    required this.onBack,
    required this.onAdd,
  });

  final String petName;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.chevron_left_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peso',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                        color: _WeightPalette.darkText,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  petName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _WeightPalette.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.add_rounded,
          onTap: onAdd,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _WeightPalette.chip,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 21,
            color: _WeightPalette.darkText,
          ),
        ),
      ),
    );
  }
}

class _WeightOverviewCard extends StatelessWidget {
  const _WeightOverviewCard({
    required this.entries,
  });

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    final latest = entries.isEmpty ? null : entries.first;
    final previous = entries.length > 1 ? entries[1] : null;
    final delta = latest == null || previous == null
        ? null
        : latest.weightKg - previous.weightKg;

    return Container(
      decoration: BoxDecoration(
        color: _WeightPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _WeightPalette.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: latest == null
                    ? _NoWeightSummary()
                    : _CurrentWeightSummary(entry: latest),
              ),
              if (delta != null)
                _DeltaSummary(
                  delta: delta,
                ),
            ],
          ),
          const SizedBox(height: 20),
          _WeightChart(entries: entries),
          const SizedBox(height: 14),
          _RangeMessage(latest: latest),
        ],
      ),
    );
  }
}

class _NoWeightSummary extends StatelessWidget {
  const _NoWeightSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATTUALE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _WeightPalette.mutedText,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
        ),
        const SizedBox(height: 7),
        Text(
          'Nessun peso',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _WeightPalette.darkText,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
              ),
        ),
      ],
    );
  }
}

class _CurrentWeightSummary extends StatelessWidget {
  const _CurrentWeightSummary({
    required this.entry,
  });

  final WeightEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATTUALE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _WeightPalette.mutedText,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatWeight(entry.weightKg),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 34,
                    color: _WeightPalette.darkText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                    height: 1,
                  ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                'kg',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _WeightPalette.secondaryText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeltaSummary extends StatelessWidget {
  const _DeltaSummary({
    required this.delta,
  });

  final double delta;

  @override
  Widget build(BuildContext context) {
    final sign = delta >= 0 ? '+' : '';
    final color = delta >= 0 ? _WeightPalette.purple : _WeightPalette.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${delta >= 0 ? '↑' : '↓'} $sign${_formatSignedWeight(delta)} kg',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'vs. precedente',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _WeightPalette.mutedText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({
    required this.entries,
  });

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    final chartEntries = entries.reversed.take(8).toList(growable: false);

    return SizedBox(
      height: 145,
      child: CustomPaint(
        painter: _WeightChartPainter(entries: chartEntries),
        child: chartEntries.isEmpty
            ? Center(
                child: Text(
                  'Aggiungi un peso per vedere il grafico',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _WeightPalette.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter({
    required this.entries,
  });

  final List<WeightEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = _WeightPalette.outline
      ..strokeWidth = 1;

    final gridPaint = Paint()
      ..color = _WeightPalette.outline.withValues(alpha: 0.65)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    final left = 30.0;
    final right = size.width - 8;
    final top = 10.0;
    final bottom = size.height - 28;

    canvas.drawLine(
      Offset(left, top),
      Offset(right, top),
      gridPaint,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(right, bottom),
      gridPaint,
    );

    if (entries.isEmpty) {
      return;
    }

    final weights = entries.map((entry) => entry.weightKg).toList();
    final minWeight = weights.reduce(math.min);
    final maxWeight = weights.reduce(math.max);
    final padding = math.max((maxWeight - minWeight) * 0.25, 0.3);
    final low = minWeight - padding;
    final high = maxWeight + padding;
    final range = high - low == 0 ? 1.0 : high - low;

    void paintLabel(String text, Offset offset) {
      labelPainter.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: _WeightPalette.mutedText,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(canvas, offset);
    }

    paintLabel('${_formatAxisWeight(high)} kg', Offset(0, top - 4));
    paintLabel('${_formatAxisWeight(low)} kg', Offset(0, bottom - 6));

    final points = <Offset>[];

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final x = entries.length == 1
          ? (left + right) / 2
          : left + ((right - left) / (entries.length - 1)) * index;

      final normalized = (entry.weightKg - low) / range;
      final y = bottom - (bottom - top) * normalized;

      points.add(Offset(x, y));
    }

    final fillPath = Path()
      ..moveTo(points.first.dx, bottom);

    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }

    fillPath
      ..lineTo(points.last.dx, bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _WeightPalette.purple.withValues(alpha: 0.24),
          _WeightPalette.purple.withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(left, top, right, bottom));

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final linePaint = Paint()
      ..color = _WeightPalette.purple
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = _WeightPalette.card
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = _WeightPalette.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawCircle(point, 3.2, dotPaint);
      canvas.drawCircle(point, 3.2, dotBorderPaint);
    }

    canvas.drawCircle(points.last, 5.2, Paint()..color = _WeightPalette.purple);

    final firstMonth = DateFormat('MMM', 'it').format(entries.first.recordedAt);
    final middleMonth = DateFormat('MMM', 'it').format(
      entries[entries.length ~/ 2].recordedAt,
    );
    final lastMonth = DateFormat('MMM', 'it').format(entries.last.recordedAt);

    paintLabel(_capitalize(firstMonth), Offset(left - 12, bottom + 13));
    paintLabel(_capitalize(middleMonth), Offset((left + right) / 2 - 10, bottom + 13));
    paintLabel(_capitalize(lastMonth), Offset(right - 14, bottom + 13));

    canvas.drawLine(
      Offset(left, bottom),
      Offset(right, bottom),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

class _RangeMessage extends StatelessWidget {
  const _RangeMessage({
    required this.latest,
  });

  final WeightEntry? latest;

  @override
  Widget build(BuildContext context) {
    final text = latest == null
        ? 'Registra il primo peso per iniziare a seguire l’andamento.'
        : 'Nel range ideale (3.8–4.5 kg). Continua così.';

    return Container(
      decoration: BoxDecoration(
        color: _WeightPalette.lightPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_rounded,
            color: _WeightPalette.purple,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _WeightPalette.secondaryText,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _WeightPalette.warningBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _WeightPalette.warningBorder),
      ),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _WeightPalette.warningIcon,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Pet Life registra i dati inseriti da te e non interpreta variazioni di peso. Per dubbi consulta il veterinario.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _WeightPalette.warningText,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });

  final List<WeightEntry> entries;
  final ValueChanged<WeightEntry> onEdit;
  final ValueChanged<WeightEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _WeightPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _WeightPalette.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              _HistoryRow(
                entry: entries[index],
                previousEntry:
                    index + 1 < entries.length ? entries[index + 1] : null,
                onEdit: () => onEdit(entries[index]),
                onDelete: () => onDelete(entries[index]),
              ),
              if (index != entries.length - 1)
                const Divider(
                  height: 1,
                  color: _WeightPalette.outline,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.previousEntry,
    required this.onEdit,
    required this.onDelete,
  });

  final WeightEntry entry;
  final WeightEntry? previousEntry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final delta = previousEntry == null
        ? 0.0
        : entry.weightKg - previousEntry!.weightKg;

    final deltaColor = delta > 0
        ? _WeightPalette.purple
        : delta < 0
            ? _WeightPalette.blue
            : _WeightPalette.mutedText;

    final deltaLabel = previousEntry == null
        ? '0.0 kg vs. precedente'
        : '${delta >= 0 ? '+' : ''}${_formatSignedWeight(delta)} kg vs. precedente';

    return Material(
      color: _WeightPalette.card,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              _DateBadge(date: entry.recordedAt),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatWeight(entry.weightKg)} kg',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _WeightPalette.darkText,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      deltaLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: deltaColor,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                    ),
                    if (entry.notes != null &&
                        entry.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.notes!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _WeightPalette.secondaryText,
                              height: 1.2,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Modifica',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: _WeightPalette.secondaryText,
                ),
              ),
              IconButton(
                tooltip: 'Elimina',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: _WeightPalette.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = DateFormat('MMM', locale).format(date);
    final day = DateFormat('d', locale).format(date);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _WeightPalette.chip,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _capitalize(month.replaceAll('.', '')),
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _WeightPalette.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            day,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _WeightPalette.darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWeightCard extends StatelessWidget {
  const _EmptyWeightCard({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _WeightPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _WeightPalette.outline),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.monitor_weight_outlined,
            size: 42,
            color: _WeightPalette.secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            'Nessuna misurazione',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _WeightPalette.darkText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi il primo peso per creare lo storico.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _WeightPalette.secondaryText,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Aggiungi peso'),
          ),
        ],
      ),
    );
  }
}

class _WeightEditorSheet extends StatefulWidget {
  const _WeightEditorSheet({
    required this.pet,
    this.entry,
  });

  final Pet pet;
  final WeightEntry? entry;

  @override
  State<_WeightEditorSheet> createState() => _WeightEditorSheetState();
}

class _WeightEditorSheetState extends State<_WeightEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _recordedAt;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;

    _weightController.text =
        entry == null ? '' : _formatWeight(entry.weightKg);
    _notesController.text = entry?.notes ?? '';
    _recordedAt = entry?.recordedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _recordedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _recordedAt.hour,
        _recordedAt.minute,
      );
    });
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final normalizedWeight = _weightController.text.trim().replaceAll(',', '.');
    final weightKg = double.parse(normalizedWeight);

    Navigator.of(context).pop(
      _WeightEditorResult.save(
        _WeightDraft(
          weightKg: weightKg,
          recordedAt: _recordedAt,
          notes: _notesController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare questa misurazione?'),
          content: const Text(
            'La misurazione verrà rimossa dallo storico del peso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      Navigator.of(context).pop(_WeightEditorResult.delete());
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateLabel = DateFormat.yMMMd(locale).format(_recordedAt);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _WeightPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Modifica peso' : 'Nuovo peso',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _WeightPalette.darkText,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Misurazione personale di ${widget.pet.name}.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _WeightPalette.secondaryText,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Peso in kg',
                      hintText: 'Es. 4.2',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final normalized =
                          value?.trim().replaceAll(',', '.') ?? '';

                      if (normalized.isEmpty) {
                        return 'Inserisci il peso';
                      }

                      final parsed = double.tryParse(normalized);

                      if (parsed == null || parsed <= 0) {
                        return 'Inserisci un peso valido';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _DateSelector(
                    label: 'Data',
                    value: dateLabel,
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Opzionale',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(_isEditing ? 'Aggiorna peso' : 'Salva peso'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Elimina peso'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _WeightPalette.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _WeightPalette.outline),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: Row(
            children: [
              const Icon(
                Icons.event_outlined,
                color: _WeightPalette.purple,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _WeightPalette.darkText,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _WeightPalette.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetNotFoundState extends StatelessWidget {
  const _PetNotFoundState({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: _WeightPalette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _WeightPalette.outline),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pet non trovato'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onBack,
                child: const Text('OK'),
              ),
            ],
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

enum _WeightEditorAction {
  save,
  delete,
}

class _WeightEditorResult {
  const _WeightEditorResult._({
    required this.action,
    this.draft,
  });

  factory _WeightEditorResult.save(_WeightDraft draft) {
    return _WeightEditorResult._(
      action: _WeightEditorAction.save,
      draft: draft,
    );
  }

  factory _WeightEditorResult.delete() {
    return const _WeightEditorResult._(
      action: _WeightEditorAction.delete,
    );
  }

  final _WeightEditorAction action;
  final _WeightDraft? draft;
}

class _WeightDraft {
  const _WeightDraft({
    required this.weightKg,
    required this.recordedAt,
    required this.notes,
  });

  final double weightKg;
  final DateTime recordedAt;
  final String notes;
}

class _WeightPalette {
  const _WeightPalette._();

  static const background = Color(0xFFF8F1E2);
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF0E6D0);
  static const outline = Color(0xFFE3D2B4);

  static const darkText = Color(0xFF2D2418);
  static const secondaryText = Color(0xFF8B7A63);
  static const mutedText = Color(0xFFB4A48F);

  static const purple = Color(0xFFB084E8);
  static const lightPurple = Color(0xFFF4EFFB);
  static const blue = Color(0xFF5C9CE6);

  static const warningBackground = Color(0xFFFFF4E8);
  static const warningBorder = Color(0xFFF0D6BF);
  static const warningIcon = Color(0xFFB87841);
  static const warningText = Color(0xFF7B5537);
}

String _formatWeight(double value) {
  return value.toStringAsFixed(1);
}

String _formatSignedWeight(double value) {
  return value.abs().toStringAsFixed(1);
}

String _formatAxisWeight(double value) {
  return value.toStringAsFixed(1);
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value[0].toUpperCase() + value.substring(1);
}