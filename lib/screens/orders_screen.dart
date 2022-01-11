import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_drawer.dart';
import '../widgets/order_item.dart';
import '../providers/orders.dart' show Orders;

class OrdersScreen extends StatelessWidget {
  static const routeName = '/orders';

  Future<void> refetch(Orders orders) async {
    try {
      await orders.fetchAndSet();
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<Orders>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Your Orders')),
      drawer: AppDrawer(),
      body: FutureBuilder(
        future: orders.fetchAndSet(),
        builder: (ctx, data) {
          if (data.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (data.error != null) {
            //  Handle errors
            print(data.error);
            return Center(child: Text(data.error.toString()));
          }

          return RefreshIndicator(
            onRefresh: () => refetch(orders),
            child: Consumer<Orders>(
              builder: (_, orderData, child) => ListView.builder(
                itemCount: orders.count,
                itemBuilder: (_, idx) => OrderItem(orders.orders[idx]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// class OrdersScreen extends StatefulWidget {
//   static const routeName = '/orders';
//
//   @override
//   _OrdersScreenState createState() => _OrdersScreenState();
// }
//
// class _OrdersScreenState extends State<OrdersScreen> {
//   var _isLoading = false;
//
//   @override
//   void initState() {
//     fetchOrders();
//     super.initState();
//   }
//
//   Future<void> fetchOrders() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       await Provider.of<Orders>(context, listen: false).fetchAndSet();
//     } catch (error) {
//       print(error);
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   Future<void> refetch(Orders orders) async {
//     try {
//       await orders.fetchAndSet();
//     } catch (error) {
//       print(error);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final orders = Provider.of<Orders>(context);
//
//     return Scaffold(
//       appBar: AppBar(title: Text('Your Orders')),
//       drawer: AppDrawer(),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: () => refetch(orders),
//               child: ListView.builder(
//                 itemCount: orders.count,
//                 itemBuilder: (_, idx) => OrderItem(orders.orders[idx]),
//               ),
//             ),
//     );
//   }
// }
