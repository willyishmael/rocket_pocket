import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/account.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/dashboard/account_card.dart';

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
                    'Accounts',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      context.push(Paths.createAccount);
                      print('Add Account');
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
                    (context, index) => AccountCard(
                      account: Account(
                        id: index,
                        name: 'Account $index',
                        balance: 1000.0 + (index * 100),
                        currency: 'USD',
                        accentColor: Colors.blue.value,
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
