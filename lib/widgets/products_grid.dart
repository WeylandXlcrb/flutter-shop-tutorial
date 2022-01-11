import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/products.dart';
import './product_item.dart';

class ProductsGrid extends StatelessWidget {
  final bool showOnlyFavorites;

  ProductsGrid(this.showOnlyFavorites);

  @override
  Widget build(BuildContext context) {
    var productsData = Provider.of<Products>(context);
    var products =
        showOnlyFavorites ? productsData.favoriteItems : productsData.items;

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (_, idx) => ChangeNotifierProvider.value(
        value: products[idx],
        child: ProductItem(
            // products[idx].id,
            // products[idx].title,
            // products[idx].imageUrl,
            ),
      ),
      itemCount: products.length,
    );
  }
}
