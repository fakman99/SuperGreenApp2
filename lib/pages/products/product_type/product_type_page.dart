/*
 * Copyright (C) 2018  SuperGreenLab <towelie@supergreenlab.com>
 * Author: Constantin Clauzel <constantin.clauzel@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_green_app/data/api/backend/products/models.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/products/product_type/product_type_bloc.dart';
import 'package:super_green_app/pages/products/product_type/product_types.dart';
import 'package:super_green_app/widgets/appbar.dart';
import 'package:super_green_app/widgets/green_button.dart';
import 'package:super_green_app/widgets/section_title.dart';

class ProductTypePage extends StatefulWidget {
  @override
  _ProductTypePageState createState() => _ProductTypePageState();
}

class _ProductTypePageState extends State<ProductTypePage> {
  ProductCategoryID selectedType;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductTypeBloc, ProductTypeBlocState>(
      listener: (BuildContext context, ProductTypeBlocState state) {},
      child: BlocBuilder<ProductTypeBloc, ProductTypeBlocState>(
        builder: (BuildContext context, ProductTypeBlocState state) {
          Widget body = Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SectionTitle(
                  title: 'Item type',
                  icon: 'assets/products/toolbox/icon_item_type.svg',
                  iconPadding: 0,
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  children:
                      productTypes.keys.map<Widget>((ProductCategoryID name) {
                    final ProductType type = productTypes[name];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedType = name;
                        });
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: selectedType == name
                                        ? Border.all(color: Colors.green)
                                        : null,
                                    borderRadius: selectedType == name
                                        ? BorderRadius.all(Radius.circular(25))
                                        : null),
                                child: SvgPicture.asset(type.icon)),
                          ),
                          Text(type.name,
                              style: TextStyle(
                                  fontWeight: selectedType == name
                                      ? FontWeight.bold
                                      : null))
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GreenButton(
                    title: 'NEXT',
                    onPressed: selectedType == null
                        ? null
                        : () {
                            BlocProvider.of<MainNavigatorBloc>(context).add(
                                MainNavigateToProductInfosEvent(
                                    futureFn: (future) async {
                              Product product = await future;
                              if (product != null) {
                                BlocProvider.of<MainNavigatorBloc>(context).add(
                                    MainNavigatorActionPop(
                                        param: Product(
                                            name: product.name,
                                            category: selectedType,
                                            supplier: product.supplier)));
                              }
                            }));
                          },
                  ),
                ),
              ),
            ],
          );
          return Scaffold(
              appBar: SGLAppBar(
                '🛠',
                fontSize: 40,
                backgroundColor: Color(0xff0EA9DA),
                titleColor: Colors.white,
                iconColor: Colors.white,
              ),
              backgroundColor: Colors.white,
              body: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200), child: body));
        },
      ),
    );
  }
}
