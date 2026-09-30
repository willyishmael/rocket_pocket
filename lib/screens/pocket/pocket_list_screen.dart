import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/pocket/widgets/pocket_card.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

class PocketListScreen extends ConsumerWidget {
  const PocketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pocketsAsync = ref.watch(pocketViewModelProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Paths.createPocket),
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Pockets'),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          pocketsAsync.when(
            loading:
                () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (error, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $error')),
                ),
            data: (pockets) {
              if (pockets.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No pockets yet. Tap + to create one.'),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final pocket = pockets[index];
                  return GestureDetector(
                    onTap:
                        () =>
                            context.push(Paths.pocketDetailsRoute(pocket.id!)),
                    child: PocketCard(pocket: pocket),
                  );
                }, childCount: pockets.length),
              );
            },
          ),
        ],
      ),
    );
  }
}
