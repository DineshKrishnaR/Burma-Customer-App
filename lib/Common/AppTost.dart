import 'package:fluttertoast/fluttertoast.dart';
import '../Common/colors.dart' as Customcolor;

class Apptoast {
  showSuccessToast(message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Customcolor.success_color,
        textColor: Customcolor.error_text_color,
        fontSize: 16.0);
  }

  showErrorToast(message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Customcolor.error_color,
        textColor: Customcolor.error_text_color,
        fontSize: 16.0);
  }
}

class CustomColors {}
