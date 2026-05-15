import 'package:flutter/material.dart';

class PetModuleGrid extends StatelessWidget {
  const PetModuleGrid({
    required this.title,
    required this.modules,
    super.key,
  });

  final String title;
  final List<PetModuleItem> modules;

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 520;
                final columns = isWide ? 2 : 1;

                return GridView.builder(
                  itemCount: modules.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 104,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final module = modules[index];

                    return _PetModuleTile(module: module);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PetModuleItem {
  const PetModuleItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
}

class _PetModuleTile extends StatelessWidget {
  const _PetModuleTile({
    required this.module,
  });

  final PetModuleItem module;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: module.title,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: module.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    module.icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}