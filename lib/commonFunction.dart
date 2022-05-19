import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoder/geocoder.dart';

import 'main.dart';

/// uses an address String and returns a LatLng geopoint
Future<GeoPoint> toLatLng(String addr) async {
  if (addr == null || addr.startsWith('Vanderhoof')) {
    return null;
  }
  var address;
  try {
    address = await Geocoder.local.findAddressesFromQuery(addr);
  } catch (e) {
    print("could not get geopoint for address: $addr");
    return address;
  }
  var first = address.first;
  var coor = first.coordinates;
  var lat = coor.latitude;
  var lng = coor.longitude;
  return GeoPoint(lat, lng);
}

/// returns true if a string field is empty
bool isFieldEmpty(String toCheck) {
  return (toCheck == null ||
      toCheck.trim() == "" ||
      toCheck == "." ||
      toCheck == "null");
}

/// uses a Color with a hex code and returns a MaterialColor object
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}

/// Returns a loading Wave widget.
Widget showLoadingScreen() {
  return SpinKitWave(
    color: colorPrimary,
    size: 50.0,
  );
}

///Returns a floating action button widget.
Widget buildScrollToTopButton(isVisible, controller) {
  return isVisible
      ? Container(
          child: FloatingActionButton(
              // scroll to top of the list
              child: FaIcon(FontAwesomeIcons.angleUp),
              shape: RoundedRectangleBorder(),
              foregroundColor: colorPrimary,
              mini: true,
              onPressed: () {
                controller.scrollTo(
                  index: 0,
                  duration: Duration(seconds: 1),
                  curve: Curves.easeInOut,
                );
              }),
        )
      : null;
}

/// async helper method - formats website to remove "http(s)://www."
///
/// "http://" is required to correctly launch website URL
String formatWebsiteURL(String website) {
  if (website != null && website.trim() != "" && website != ".") {
    String formatted = website.trim();
    if (formatted.startsWith('http')) {
      formatted = formatted.substring(4);
    }
    if (formatted.startsWith('s://')) {
      formatted = formatted.substring(4);
    }
    if (formatted.startsWith('://')) {
      formatted = formatted.substring(3);
    }
    if (formatted.startsWith('www.')) {
      formatted = formatted.substring(4);
    }
    return formatted;
  } else {
    // website is empty
    return null;
  }
}

/// async helper method - formats phone number to "(***) ***-****"
String formatPhoneNumber(String phone) {
  if (phone != null && phone.trim() != "" && phone != ".") {
    phone = phone.replaceAll(RegExp("[^0-9]"), '');
    String formatted = phone;
    formatted = "(" +
        phone.substring(0, 3) +
        ") " +
        phone.substring(3, 6) +
        "-" +
        phone.substring(6);
    return formatted;
  } else {
    // phone is empty
    return null;
  }
}
