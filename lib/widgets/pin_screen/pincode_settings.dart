import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/settings/pin_screen/confirm_pin_screen_bloc.dart';
import 'package:super_green_app/pages/settings/pin_screen/confirm_pin_screen_page.dart';
import 'package:super_green_app/pages/settings/pin_screen/settings_pin_screen_bloc.dart';
import 'package:super_green_app/pages/settings/settings_bloc.dart';
import 'package:super_green_app/widgets/pin_screen/constant/constant.dart';
import 'package:super_green_app/widgets/pin_screen/keyboard/keyboard.dart';
import 'package:super_green_app/widgets/pin_screen/pincode_confirm.dart';
import 'package:super_green_app/widgets/pin_screen/pinview/code_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PinCodeSettings extends StatefulWidget {
  final SvgPicture titleImage;
  final String error, correctPin;
  final Function onCodeSuccess, onCodeFail;
  final int codeLength;
  final TextStyle keyTextStyle, codeTextStyle, errorTextStyle;
  final bool obscurePin;
  final Color backgroundColor;
  final bool showLetters;

  PinCodeSettings({
    this.titleImage,
    this.correctPin = "****", // Default Value, use onCodeFail as onEnteredPin
    this.error = '',
    this.codeLength = 4,
    this.obscurePin = false, // Replaces by * if true
    this.onCodeSuccess,
    this.onCodeFail,
    this.errorTextStyle = const TextStyle(color: Colors.red, fontSize: 15),
    this.keyTextStyle = const TextStyle(color: pinKeyTextColor, fontSize: 18.0),
    this.codeTextStyle = const TextStyle(
        color: pinCodeColor, fontSize: 18.0, fontWeight: FontWeight.bold),
    this.backgroundColor,
    this.showLetters = false,
  });

  PinCodeSettingsState createState() => PinCodeSettingsState();
}

class PinCodeSettingsState extends State<PinCodeSettings> {
  String smsCode = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor ?? Theme.of(context).primaryColor,
      child: Column(children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RichText(
                  text: new TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: new TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      new TextSpan(
                          text: 'Type your new ',
                          style: new TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w400)),
                      new TextSpan(
                          text: 'Pin code',
                          style: new TextStyle(
                              fontSize: 25,
                              color: Colors.green,
                              fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                Stack(clipBehavior: Clip.none, children: [
                  CodeView(
                    codeTextStyle: widget.codeTextStyle,
                    code: smsCode,
                    obscurePin: widget.obscurePin,
                    length: widget.codeLength,
                  ),
                  Positioned(
                    child: SvgPicture.asset("assets/lockscreen/lock.svg"),
                    top: 10,
                    right: -40,
                  )
                ]),
              ],
            ),
          ),
        ),
        Padding(
            padding: EdgeInsets.only(bottom: 25),
            child: CustomKeyboard(
              textStyle: widget.keyTextStyle,
              onPressedKey: (key) {
                if (smsCode.length < widget.codeLength) {
                  setState(() {
                    smsCode = smsCode + key;
                  });
                }
                if (smsCode.length == widget.codeLength) {
                  print(smsCode);

                  FutureFn ff =
                      BlocProvider.of<MainNavigatorBloc>(context).futureFn();
                  BlocProvider.of<MainNavigatorBloc>(context)
                      .add(MainNavigateToConfirmPinPageEvent(
                    smsCode,
                    futureFn: ff.futureFn,
                  ));
                }
              },
              onBackPressed: () {
                int codeLength = smsCode.length;
                if (codeLength > 0)
                  setState(() {
                    smsCode = smsCode.substring(0, codeLength - 1);
                  });
              },
              showLetters: widget.showLetters,
            )),
      ]),
    );
  }
}
