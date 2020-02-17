import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_green_app/pages/feed_entries/feed_light/card/feed_light_card_bloc.dart';
import 'package:super_green_app/widgets/feed_card/feed_card.dart';
import 'package:super_green_app/widgets/feed_card/feed_card_date.dart';
import 'package:super_green_app/widgets/feed_card/feed_card_title.dart';

class FeedLightCardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedLightCardBloc, FeedLightCardBlocState>(
        bloc: BlocProvider.of<FeedLightCardBloc>(context),
        builder: (context, state) => FeedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeedCardTitle('assets/feed_card/icon_light.svg',
                      'Stretch control', state.feedEntry),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FeedCardDate(state.feedEntry),
                  ),
                  Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'From:',
                          style: TextStyle(fontSize: 20),
                        ),
                        _renderValues(state.params['initialValues']),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            'To:',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        _renderValues(state.params['values']),
                      ],
                    ),
                  ),
                ],
              ),
            ));
  }

  Widget _renderValues(List<dynamic> values) {
    return Text(
      '${values.map((v) => '$v%').join(', ')}',
      style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff3bb30b)),
    );
  }
}
