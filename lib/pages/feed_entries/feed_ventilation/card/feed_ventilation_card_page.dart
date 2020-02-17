import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_green_app/pages/feed_entries/feed_ventilation/card/feed_ventilation_card_bloc.dart';
import 'package:super_green_app/widgets/feed_card/feed_card.dart';
import 'package:super_green_app/widgets/feed_card/feed_card_date.dart';
import 'package:super_green_app/widgets/feed_card/feed_card_title.dart';

//{"initialValues":{"blowerDay":40,"blowerNight":20},"values":{"blowerDay":52,"blowerNight":30}}
class FeedVentilationCardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedVentilationCardBloc, FeedVentilationCardBlocState>(
        bloc: BlocProvider.of<FeedVentilationCardBloc>(context),
        builder: (context, state) => FeedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeedCardTitle('assets/feed_card/icon_blower.svg',
                      'Feed Ventilation', state.feedEntry),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FeedCardDate(state.feedEntry),
                  ),
                  Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'From:',
                                style: TextStyle(fontSize: 20),
                              ),
                              _renderValues(state.params['initialValues']),
                            ]),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'To:',
                                style: TextStyle(fontSize: 20),
                              ),
                              _renderValues(state.params['values']),
                            ]),
                      ],
                    ),
                  ),
                ],
              ),
            ));
  }

  Widget _renderValues(Map<String, dynamic> values) {
    return Text(
      'Night: ${values['blowerNight']}%\nDay: ${values['blowerDay']}%',
      style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff3bb30b)),
    );
  }
}
