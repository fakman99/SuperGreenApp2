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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_green_app/data/api/backend/products/models.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/feed_entries/entry_params/feed_nutrient_mix.dart';
import 'package:super_green_app/pages/feed_entries/feed_nutrient_mix/form/feed_nutrient_mix_form_bloc.dart';
import 'package:super_green_app/widgets/feed_form/feed_form_button.dart';
import 'package:super_green_app/widgets/feed_form/feed_form_date_picker.dart';
import 'package:super_green_app/widgets/feed_form/feed_form_layout.dart';
import 'package:super_green_app/widgets/feed_form/feed_form_param_layout.dart';
import 'package:super_green_app/widgets/feed_form/feed_form_textarea.dart';
import 'package:super_green_app/widgets/feed_form/number_form_param.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';

Map<NutrientMixPhase, String> nutrientMixPhasesUI = {
  NutrientMixPhase.EARLY_VEG: 'Early veg',
  NutrientMixPhase.MID_VEG: 'Mid veg',
  NutrientMixPhase.LATE_VEG: 'Late veg',
  NutrientMixPhase.EARLY_BLOOM: 'Early bloom',
  NutrientMixPhase.MID_BLOOM: 'Mid bloom',
  NutrientMixPhase.LATE_BLOOM: 'Late bloom',
};

class FeedNutrientMixFormPage extends StatefulWidget {
  @override
  _FeedNutrientMixFormPageState createState() =>
      _FeedNutrientMixFormPageState();
}

class _FeedNutrientMixFormPageState extends State<FeedNutrientMixFormPage> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  final ScrollController scrollController = ScrollController();

  DateTime date = DateTime.now();

  bool hideRestore = false;
  bool restore;
  bool loadingRestore;

  TextEditingController nameController = TextEditingController();
  TextEditingController phController = TextEditingController();
  TextEditingController ecController = TextEditingController();
  TextEditingController tdsController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  double volume = 10;

  List<NutrientProduct> nutrientProducts = [];
  List<TextEditingController> quantityControllers = [];

  Plant plant;
  List<FeedNutrientMixParams> lastNutrientMixParams;
  FeedNutrientMixParams baseNutrientMixParams;

  NutrientMixPhase phase;

  FocusNode nameFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      cubit: BlocProvider.of<FeedNutrientMixFormBloc>(context),
      listener: (BuildContext context, FeedNutrientMixFormBlocState state) {
        if (state is FeedNutrientMixFormBlocStateLoaded) {
          setState(() {
            plant = state.plant;
            nutrientProducts = [];
            quantityControllers = [];
            lastNutrientMixParams = state.lastNutrientMixParams;
            for (Product product in state.products) {
              NutrientProduct nutrientProduct = nutrientProducts.singleWhere(
                  (pi) => pi.product.id == product.id,
                  orElse: () => null);
              if (nutrientProduct == null) {
                nutrientProducts.add(
                    NutrientProduct(product: product, quantity: 0, unit: 'g'));
                quantityControllers.add(TextEditingController(text: null));
              } else {
                nutrientProducts.add(nutrientProduct);
                quantityControllers.add(
                    TextEditingController(text: '${nutrientProduct.quantity}'));
              }
            }
          });
        } else if (state is FeedNutrientMixFormBlocStateDone) {
          BlocProvider.of<MainNavigatorBloc>(context)
              .add(MainNavigatorActionPop(mustPop: true));
        }
      },
      child: BlocBuilder<FeedNutrientMixFormBloc, FeedNutrientMixFormBlocState>(
          cubit: BlocProvider.of<FeedNutrientMixFormBloc>(context),
          builder: (BuildContext context, FeedNutrientMixFormBlocState state) {
            Widget body;
            if (state is FeedNutrientMixFormBlocStateLoading) {
              body = FullscreenLoading(
                title: 'Saving..',
              );
            } else if (state is FeedNutrientMixFormBlocStateInit) {
              body = FullscreenLoading(
                title: 'Loading..',
              );
            } else if (state is FeedNutrientMixFormBlocStateLoaded) {
              body = renderBody(context, state);
            }
            return FeedFormLayout(
                title: '🧪',
                changed: true,
                valid: true,
                onOK: () async {
                  double ph, ec, tds;
                  if (phController.text != '') {
                    ph = double.parse(phController.text.replaceAll(',', '.'));
                  }
                  if (ecController.text != '') {
                    ec = double.parse(ecController.text.replaceAll(',', '.'));
                  }
                  if (tdsController.text != '') {
                    tds = double.parse(tdsController.text.replaceAll(',', '.'));
                  }
                  FeedNutrientMixParams nutrientProduct = lastNutrientMixParams
                      .firstWhere((np) => np.name == nameController.text,
                          orElse: () => null);
                  if (nutrientProduct != null &&
                      await confirmUpdate(context, nutrientProduct) == false) {
                    scrollController.animateTo(1000,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.linear);
                    nameFocusNode.requestFocus();
                    return;
                  }
                  Completer<List<Plant>> plantsFuture = Completer();
                  BlocProvider.of<MainNavigatorBloc>(context).add(
                      MainNavigateToPlantPickerEvent(
                          [plant], 'Which plant(s) will receive this mix?',
                          futureFn: (future) async {
                    plantsFuture.complete(await future);
                  }));
                  List<Plant> plants = await plantsFuture.future;
                  if (plants == null || plants.length == 0) {
                    return;
                  }
                  BlocProvider.of<FeedNutrientMixFormBloc>(context).add(
                      FeedNutrientMixFormBlocEventCreate(
                          date,
                          nameController.text,
                          volume,
                          ph,
                          ec,
                          tds,
                          nutrientProducts,
                          messageController.text,
                          plants,
                          phase,
                          baseNutrientMixParams));
                },
                body: AnimatedSwitcher(
                  child: body,
                  duration: Duration(milliseconds: 200),
                ));
          }),
    );
  }

  Widget renderBody(
      BuildContext context, FeedNutrientMixFormBlocStateLoaded state) {
    List<Widget> children = [];
    if (lastNutrientMixParams.length > 0 && hideRestore == false) {
      children.add(renderRestoreLastNutrientMix(lastNutrientMixParams));
    }
    children.addAll([
      FeedFormDatePicker(
        date,
        onChange: (DateTime newDate) {
          setState(() {
            date = newDate;
          });
        },
      ),
      renderVolume(context),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
        child: Row(
          children: [
            Text(
              'Nutrients in your ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87),
            ),
            Text(
              'mix',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xff3bb30b)),
            ),
            Expanded(child: Container()),
            InkWell(
                onTap: () {
                  BlocProvider.of<MainNavigatorBloc>(context).add(
                      MainNavigateToSelectNewProductEvent([],
                          categoryID: ProductCategoryID.FERTILIZER,
                          futureFn: (future) async {
                    List<Product> products = await future;
                    if (products == null || products.length == 0) {
                      return;
                    }
                    setState(() {
                      nutrientProducts.addAll(products
                          .map((p) => NutrientProduct(product: p, unit: 'g')));
                      quantityControllers.addAll(
                          products.map((p) => TextEditingController(text: '')));
                    });
                  }));
                },
                child: Icon(Icons.add, size: 30)),
          ],
        ),
      ),
    ]);
    if (nutrientProducts.length > 0) {
      int i = 0;
      List<Widget> fertilizers = [];
      for (NutrientProduct productIntake in nutrientProducts) {
        int index = i;
        fertilizers.add(FeedFormParamLayout(
            child:
                renderFertilizer(context, productIntake, quantityControllers[i],
                    (NutrientProduct newProductIntake) {
              setState(() {
                nutrientProducts[index] = newProductIntake;
              });
            }),
            icon: 'assets/products/toolbox/icon_fertilizer.svg',
            title: productIntake.product.name));
        ++i;
      }
      children.add(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: fertilizers,
      ));
    } else {
      children.add(renderEmptyToolbox(context));
    }
    children.addAll([
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
        child: Text(
          'Metrics & Observations',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
        ),
      ),
      renderWaterMetrics(context),
      renderObservations(context, state),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
        child: Text(
          'Save this nutrient mix',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
        ),
      ),
      renderName(context),
      renderPhases(context, state),
    ]);
    return AnimatedList(
      key: listKey,
      controller: scrollController,
      itemBuilder:
          (BuildContext context, int index, Animation<double> animation) =>
              children[index],
      initialItemCount: children.length,
    );
  }

  Widget renderName(BuildContext context) {
    return FeedFormParamLayout(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    'You can give this nutrient mix a name, for future reuse. (optional)'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      focusNode: nameFocusNode,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        filled: true,
                        fillColor: Colors.white10,
                        hintText: 'Ex: Veg-1',
                        labelText: 'Mix name',
                      ),
                      style: TextStyle(
                          color: Colors.black, decoration: TextDecoration.none),
                      controller: nameController,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        nameController = TextEditingController(text: '');
                      });
                      nameFocusNode.unfocus();
                    },
                    child: Icon(Icons.clear, size: 30),
                  ),
                ],
              ),
            ],
          ),
        ),
        icon: 'assets/feed_form/icon_save.svg',
        title: 'Save for future re-use?');
  }

  Widget renderVolume(BuildContext context) {
    bool freedomUnits = AppDB().getAppData().freedomUnits == true;
    return NumberFormParam(
      icon: 'assets/feed_form/icon_volume.svg',
      title: 'Water quantity',
      value: volume,
      step: 1,
      displayMultiplier: freedomUnits ? 0.25 : 1,
      unit: freedomUnits ? ' gal' : ' L',
      onChange: (newValue) {
        setState(() {
          if (newValue > 0) {
            volume = newValue;
          }
        });
      },
    );
  }

  Widget renderEmptyToolbox(BuildContext context) {
    return Container(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
                child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SvgPicture.asset('assets/products/toolbox/toolbox.svg',
                      width: 110, height: 110),
                ),
                Text(
                    'No nutrients in your toolbox yet.\nPress the + button up here.',
                    textAlign: TextAlign.center),
              ],
            ))
          ],
        ));
  }

  Widget renderWaterMetrics(BuildContext context) {
    return FeedFormParamLayout(
        icon: 'assets/feed_form/icon_metrics.svg',
        title: 'End mix metrics',
        child: Container(
          height: 245,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36.0),
                    child: Row(
                      children: [
                        Expanded(child: Container()),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Text('PH:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  child: TextField(
                                    decoration:
                                        InputDecoration(hintText: 'ex: 6.5'),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    controller: phController,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: Container()),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: [
                            Text('EC (μS/cm):',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: TextField(
                                decoration:
                                    InputDecoration(hintText: 'ex: 1800'),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                controller: ecController,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('OR', style: TextStyle(fontSize: 20))),
                      Expanded(
                        child: Column(
                          children: [
                            Text('TDS (ppm):',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: TextField(
                                decoration:
                                    InputDecoration(hintText: 'ex: 1200'),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                controller: tdsController,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget renderFertilizer(
      BuildContext context,
      NutrientProduct productIntake,
      TextEditingController textEditingController,
      Function(NutrientProduct) onChange) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Solid'),
              Switch(
                onChanged: (bool value) {
                  onChange(
                      productIntake.copyWith(unit: value == true ? 'mL' : 'g'));
                },
                value: productIntake.unit == 'mL',
              ),
              Text('Liquid'),
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                width: 70,
                child: TextField(
                  decoration: InputDecoration(hintText: 'ex: 10'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: textEditingController,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                  onChanged: (String value) {
                    onChange(
                        productIntake.copyWith(quantity: double.parse(value)));
                  },
                ),
              ),
            ),
            Text(productIntake.unit,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ]),
        ],
      ),
    );
  }

  Widget renderRestoreLastNutrientMix(
      List<FeedNutrientMixParams> lastNutrientMixParams,
      {Animation<double> animation}) {
    Widget body = FeedFormParamLayout(
      icon: 'assets/feed_form/icon_restore_nutrient_mix.svg',
      title: 'Reuse previous mix values?',
      child: Container(
        height: 70,
        child: ListView(
            scrollDirection: Axis.horizontal,
            children: lastNutrientMixParams.map<Widget>((p) {
              int i = lastNutrientMixParams.indexOf(p);
              String title = p.name;
              if (p.phase != null) {
                title = '${p.name}\n${nutrientMixPhasesUI[p.phase]}';
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 120,
                  child: FeedFormButton(
                      title: title,
                      textStyle: TextStyle(color: Colors.black),
                      onPressed: () {
                        setState(() {
                          loadingRestore = true;
                        });

                        Timer(Duration(milliseconds: 500), () {
                          listKey.currentState.removeItem(
                              0,
                              (context, animation) =>
                                  renderRestoreLastNutrientMix(
                                      lastNutrientMixParams,
                                      animation: animation),
                              duration: Duration(milliseconds: 700));
                          baseNutrientMixParams = lastNutrientMixParams[i];
                          setState(() {
                            hideRestore = true;
                            Timer(Duration(milliseconds: 600), () {
                              setLastNutrientValues(lastNutrientMixParams[i]);
                            });
                          });
                        });
                      }),
                ),
              );
            }).toList()),
      ),
    );
    if (animation != null) {
      body = SizeTransition(
        axis: Axis.vertical,
        sizeFactor: animation,
        child: body,
      );
    }
    return body;
  }

  Widget renderObservations(
      BuildContext context, FeedNutrientMixFormBlocState state) {
    return Container(
      height: 200,
      key: Key('TEXTAREA'),
      child: FeedFormParamLayout(
        title: 'Observations',
        icon: 'assets/feed_form/icon_note.svg',
        child: Expanded(
          child: FeedFormTextarea(
            textEditingController: messageController,
          ),
        ),
      ),
    );
  }

  Widget renderPhases(
      BuildContext context, FeedNutrientMixFormBlocState state) {
    return FeedFormParamLayout(
      title: 'Mix phase',
      icon: 'assets/plant_infos/icon_vegging_since.svg',
      child: Container(
          height: 110,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    'Set the right phase for this nutrient mix for better categorization.'),
              ),
              Expanded(
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: NutrientMixPhase.values
                        .map((p) => Padding(
                            padding: const EdgeInsets.only(
                                right: 16.0, top: 8, bottom: 8, left: 8),
                            child: Container(
                                width: 120,
                                child: FeedFormButton(
                                    border: phase == p,
                                    title: nutrientMixPhasesUI[p],
                                    textStyle: TextStyle(color: Colors.black),
                                    onPressed: () {
                                      setState(() {
                                        phase = phase == p ? null : p;
                                      });
                                    }))))
                        .toList()),
              ),
            ],
          )),
    );
  }

  void setLastNutrientValues(FeedNutrientMixParams lastNutrientMixParams) {
    setState(() {
      volume = lastNutrientMixParams.volume;
      nameController = TextEditingController(text: lastNutrientMixParams.name);
      if (lastNutrientMixParams.ph != null) {
        phController =
            TextEditingController(text: '${lastNutrientMixParams.ph}');
      }
      if (lastNutrientMixParams.ec != null) {
        ecController =
            TextEditingController(text: '${lastNutrientMixParams.ec}');
      }
      //List<NutrientProduct> missingProducts = [];
      for (int i = 0; i < lastNutrientMixParams.nutrientProducts.length; ++i) {
        int index = nutrientProducts.indexWhere((np) =>
            np.product.id ==
            lastNutrientMixParams.nutrientProducts[i].product.id);
        if (index == -1) {
          //missingProducts.add(lastNutrientMixParams.nutrientProducts[i]);
          nutrientProducts.add(lastNutrientMixParams.nutrientProducts[i]);
          quantityControllers.add(TextEditingController(
              text: '${lastNutrientMixParams.nutrientProducts[i].quantity}'));
        } else {
          nutrientProducts[index] = lastNutrientMixParams.nutrientProducts[i];
          quantityControllers[index] = TextEditingController(
              text: '${lastNutrientMixParams.nutrientProducts[i].quantity}');
        }
      }
      phase = lastNutrientMixParams.phase;
      /*if (missingProducts.length > 0) {
        BlocProvider.of<FeedNutrientMixFormBloc>(context)
            .add(FeedNutrientMixFormBlocEventAddNutrients(missingProducts));
      }*/
    });
  }

  Future<bool> confirmUpdate(
          BuildContext context, FeedNutrientMixParams lastNutrientMixParams) =>
      showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Update ${lastNutrientMixParams.name}?'),
              content: Text(
                  'A nutrient mix with that name already exists, overwrite?'),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text('NO, CHANGE NAME'),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text('YES'),
                ),
              ],
            );
          });
}
