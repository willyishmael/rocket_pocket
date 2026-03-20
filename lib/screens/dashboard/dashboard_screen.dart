import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_card/pocket_card.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pocketsAsync = ref.watch(pocketViewModelProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 150.0,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Hi William!'),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pockets',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  IconButton.filledTonal(
                    onPressed: () async {
                      await context.push(Paths.createPocket);
                      if (!context.mounted) return;
                      await ref.read(pocketViewModelProvider.notifier).refreshPockets();
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250.0,
              child: pocketsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (pockets) {
                  if (pockets.isEmpty) {
                    return const Center(
                      child: Text('No pockets yet. Tap + to create one.'),
                    );
                  }
                  return Swiper(
                    itemCount: pockets.length,
                    viewportFraction: 0.8,
                    scale: 1.1,
                    fade: 0.6,
                    curve: Curves.bounceInOut,
                    itemBuilder:
                        (context, index) {
                          final pocket = pockets[index];
                          return GestureDetector(
                            onTap: () => context.push(
                              Paths.pocketDetailsRoute(pocket.id!),
                            ),
                            child: PocketCard(pocket: pocket),
                          );
                        },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
