import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_card/pocket_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {
                      context.push(Paths.createPocket);
                    },
                    icon: Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250.0,
              child: Swiper(
                itemCount: 3,
                viewportFraction: 0.8,
                scale: 1.1,
                fade: 0.6,
                curve: Curves.bounceInOut,
                itemBuilder:
                    (context, index) => PocketCard(
                      pocket: Pocket(
                        name: 'Pocket $index',
                        purpose: 'Saving Pocket',
                        balance: 1000.0 + (index * 100),
                        currency: 'USD',
                        colorGradient: ColorGradient(
                          name: 'Gradient $index',
                          colors: [
                            Colors.primaries[index % Colors.primaries.length],
                            Colors.accents[index % Colors.accents.length],
                          ],
                          id: 23,
                          createdAt: DateTime.now(),
                        ),
                        emoticon: '💰',
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
