import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/0_widgets/month_selector_delegate.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_card/pocket_card.dart';
import 'package:rocket_pocket/screens/dashboard/dashboard_statistics_section.dart';
import 'package:rocket_pocket/viewmodels/dashboard_statistics_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _activePocketIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                      await ref
                          .read(pocketViewModelProvider.notifier)
                          .refreshPockets();
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

                  final maxIndex = pockets.length - 1;
                  final safeIndex =
                      _activePocketIndex > maxIndex
                          ? maxIndex
                          : _activePocketIndex;
                  if (safeIndex != _activePocketIndex) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _activePocketIndex = safeIndex);
                    });
                  }

                  return Swiper(
                    itemCount: pockets.length,
                    index: safeIndex,
                    viewportFraction: 0.8,
                    scale: 1.1,
                    fade: 0.6,
                    curve: Curves.bounceInOut,
                    onIndexChanged: (index) {
                      if (_activePocketIndex == index) return;
                      setState(() => _activePocketIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final pocket = pockets[index];
                      return GestureDetector(
                        onTap:
                            () => context.push(
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
          ..._buildStatisticsSlivers(context, pocketsAsync),
        ],
      ),
    );
  }

  List<Widget> _buildStatisticsSlivers(
    BuildContext context,
    AsyncValue<List<Pocket>> pocketsAsync,
  ) {
    if (!pocketsAsync.hasValue || pocketsAsync.requireValue.isEmpty) {
      return const [];
    }

    final pockets = pocketsAsync.requireValue;
    final selectedPocket =
        pockets[_activePocketIndex.clamp(0, pockets.length - 1)];
    final pocketId = selectedPocket.id;
    if (pocketId == null) {
      return const [];
    }

    final statisticsAsync = ref.watch(dashboardStatisticsProvider(pocketId));
    final sectionHeader = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          'Statistics',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );

    return statisticsAsync.when(
      loading:
          () => [
            sectionHeader,
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
      error:
          (error, _) => [
            sectionHeader,
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load statistics: $error'),
              ),
            ),
          ],
      data: (statistics) {
        final slivers = <Widget>[sectionHeader];
        if (statistics.availableMonths.isNotEmpty &&
            statistics.selectedMonth != null) {
          slivers.add(
            SliverPersistentHeader(
              pinned: true,
              delegate: MonthSelectorDelegate(
                months: statistics.availableMonths,
                selectedMonth: statistics.selectedMonth!,
                onMonthSelected: (month) {
                  ref
                      .read(dashboardSelectedMonthProvider(pocketId).notifier)
                      .setMonth(month);
                },
              ),
            ),
          );
        }

        slivers.add(
          SliverToBoxAdapter(
            child: DashboardStatisticsSection(
              state: statistics,
              currency: selectedPocket.currency,
            ),
          ),
        );
        return slivers;
      },
    );
  }
}
