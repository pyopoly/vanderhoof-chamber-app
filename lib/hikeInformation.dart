import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cards.dart';
import 'commonFunction.dart';
import 'fireStoreObjects.dart';
import 'main.dart';

class HikeInformation extends StatefulWidget {
  final HikeTrail hikeTrail;

  HikeInformation({Key key, @required this.hikeTrail}) : super(key: key);

  @override
  _HikeInformationState createState() => _HikeInformationState(hikeTrail);
}

class _HikeInformationState extends State<HikeInformation> {
  HikeTrail hikeTrail;

  // class constructor
  _HikeInformationState(this.hikeTrail);

  // Used in Interactive Viewer to bring the image back to its original position.
  TransformationController c = TransformationController();

  // different ThemeData for InfoPage vs default ThemeData from main.dart
  static const double TITLE_SIZE = 28;
  static const EdgeInsets TEXT_INSET = EdgeInsets.fromLTRB(0, 5, 0, 0);

  static final TextStyle titleTextStyle = TextStyle(
      fontSize: TITLE_SIZE, color: colorPrimary, fontWeight: FontWeight.bold);
  static final TextStyle headerTextStyle = TextStyle(
      fontSize: BODY_SIZE + 2, color: colorText, fontWeight: FontWeight.bold);
  static final TextStyle header2TextStyle = TextStyle(
      fontSize: BODY_SIZE - 2, color: colorText, fontWeight: FontWeight.bold);

  static final Color colorTextGreen = Colors.lightGreen[700];
  static final Color colorTextOrange = colorAccent;
  static final Color colorTextRed = Colors.red[600];

  // preload images
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isFieldEmpty(hikeTrail.imgURL)) {
      precacheImage(NetworkImage(hikeTrail.imgURL), context);
    }
  }

  Color getDifficultyColor() {
    Color difficultyColor;
    if (hikeTrail.rating == "Easy") {
      difficultyColor = colorTextGreen;
    } else if (hikeTrail.rating == "Medium") {
      difficultyColor = colorTextOrange;
    } else {
      difficultyColor = colorTextRed;
    }
    return difficultyColor;
  }

  Color getAccessibilityColor() {
    Color accessibilityColor;
    if (hikeTrail.wheelchair == "Accessible") {
      accessibilityColor = colorTextGreen;
    } else {
      accessibilityColor = colorTextRed;
    }
    return accessibilityColor;
  }

  void _launchAddressURL(address) async => await canLaunch(
          'https://www.google.com/maps/search/?api=1&query=$address')
      ? launch('https://www.google.com/maps/search/?api=1&query=$address')
      : Fluttertoast.showToast(
          msg: "Could not open directions for $address.",
          toastLength: Toast.LENGTH_SHORT);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // backgroundColor: colorBackground,
        appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, false),
            ),
            title: Text(hikeTrail.name)),
        body: SingleChildScrollView(
            child: Column(
          children: [
            StickyHeader(
              header: Container(
                child: (!isFieldEmpty(hikeTrail.imgURL))
                    ? InteractiveViewer(
                        panEnabled: false,
                        boundaryMargin: EdgeInsets.all(100),
                        minScale: 0.5,
                        maxScale: 2,
                        transformationController: c,
                        // Brings the image back to its original position.
                        // reference: https://medium.com/flutterdevs/interactive-viewer-in-flutter-69d3def22a4f
                        onInteractionEnd: (ScaleEndDetails endDetails) {
                          c.value = Matrix4.identity();
                        },
                        child: Image(
                          image: NetworkImage(hikeTrail.imgURL),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes
                                    : null,
                              ),
                            );
                          },
                        ),
                      )
                    : Container(width: 0, height: 0),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// title
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                        padding: CARD_INSET,
                        child: Text(
                          hikeTrail.name,
                          textAlign: TextAlign.center,
                          style: titleTextStyle,
                        )),
                  ),
                  // cardDivider,

                  /// address
                  /// hike address
                  tappableIconWithText(hikeTrail.address, Icons.location_on,
                      _launchAddressURL, TEXT_INSET),

                  /// trail details
                  (hikeTrail.rating != null ||
                          hikeTrail.distance != null ||
                          hikeTrail.time != null ||
                          hikeTrail.wheelchair != null)
                      ? Container(
                          padding: HEADER_INSET + CARD_INSET,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                /// distance
                                !isFieldEmpty(hikeTrail.distance)
                                    ? Row(children: <Widget>[
                                        IconButton(
                                          constraints: BoxConstraints(),
                                          icon: Icon(Icons.timeline),
                                          onPressed: null,
                                          iconSize: ICON_SIZE_SMALL,
                                        ),
                                        Flexible(
                                            child: RichText(
                                                text: TextSpan(
                                                    children: <TextSpan>[
                                              TextSpan(
                                                  text: 'Distance: ',
                                                  style: header2TextStyle),
                                              TextSpan(
                                                text: '${hikeTrail.distance}',
                                                style: bodyTextStyle,
                                              ),
                                            ]))),
                                      ])
                                    : Container(width: 0, height: 0),

                                /// difficulty
                                !isFieldEmpty(hikeTrail.rating)
                                    ? Row(children: <Widget>[
                                        IconButton(
                                          constraints: BoxConstraints(),
                                          icon: Icon(Icons.star_half),
                                          onPressed: null,
                                          iconSize: ICON_SIZE_SMALL,
                                        ),
                                        Flexible(
                                            child: RichText(
                                                text: TextSpan(
                                                    children: <TextSpan>[
                                              TextSpan(
                                                  text: 'Difficulty: ',
                                                  style: header2TextStyle),
                                              TextSpan(
                                                text: '${hikeTrail.rating}',
                                                style: TextStyle(
                                                  fontSize: BODY_SIZE,
                                                  color: getDifficultyColor(),
                                                ),
                                              ),
                                            ]))),
                                      ])
                                    : Container(width: 0, height: 0),

                                /// time
                                !isFieldEmpty(hikeTrail.time)
                                    ? Row(children: <Widget>[
                                        IconButton(
                                          constraints: BoxConstraints(),
                                          icon: Icon(Icons.access_time),
                                          onPressed: null,
                                          iconSize: ICON_SIZE_SMALL,
                                        ),
                                        Flexible(
                                            child: RichText(
                                                text: TextSpan(
                                                    children: <TextSpan>[
                                              TextSpan(
                                                  text: 'Time: ',
                                                  style: header2TextStyle),
                                              TextSpan(
                                                text: '${hikeTrail.time}',
                                                style: bodyTextStyle,
                                              ),
                                            ]))),
                                      ])
                                    : Container(width: 0, height: 0),

                                /// wheelchair
                                !isFieldEmpty(hikeTrail.wheelchair)
                                    ? Row(children: <Widget>[
                                        IconButton(
                                          constraints: BoxConstraints(),
                                          icon: Icon(Icons.accessible_outlined),
                                          onPressed: null,
                                          iconSize: ICON_SIZE_SMALL,
                                        ),
                                        Flexible(
                                            child: RichText(
                                                text: TextSpan(
                                                    children: <TextSpan>[
                                              TextSpan(
                                                  text: 'Wheelchair: ',
                                                  style: header2TextStyle),
                                              TextSpan(
                                                text: '${hikeTrail.wheelchair}',
                                                style: TextStyle(
                                                  fontSize: BODY_SIZE,
                                                  color:
                                                      getAccessibilityColor(),
                                                ),
                                              ),
                                            ]))),
                                      ])
                                    : Container(width: 0, height: 0),
                              ]),
                        )
                      : Container(width: 0, height: 0),

                  /// trail description
                  !isFieldEmpty(hikeTrail.description)
                      ? Container(
                          margin: HEADER_INSET + CARD_INSET,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                  padding: CARD_INSET,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "About this activity",
                                    style: headerTextStyle,
                                  )),
                              Padding(
                                padding: CARD_INSET + TEXT_INSET,
                                child: Text(
                                  '${hikeTrail.description}',
                                  style: bodyTextStyle,
                                ),
                              ),
                            ],
                          ))
                      : Container(width: 0, height: 0),

                  /// trail points of interest
                  /// header
                  (hikeTrail.pointsOfInterest != null)
                      ? Container(
                          padding: HEADER_INSET,
                          alignment: Alignment.center,
                          child: Text(
                            "Highlights",
                            style: headerTextStyle,
                          ))
                      : Container(width: 0, height: 0),

                  /// points of interest carousel
                  (hikeTrail.pointsOfInterest != null)
                      ? Container(
                          height: 350,
                          child: CarouselSlider(
                            items: buildPointsOfInterestList(),
                            options: CarouselOptions(
                                scrollDirection: Axis.horizontal,
                                enlargeCenterPage: true,
                                enableInfiniteScroll: true,
                                height: 300,
                                pageSnapping: true),
                          ),
                        )
                      : Container(width: 0, height: 0),
                ],
              ),
            ),
          ],
        )));
  }

  List<Widget> buildPointsOfInterestList() {
    List<Widget> build = [];

    for (var i = 0; i < hikeTrail.pointsOfInterest.length; i++) {
      Widget content = Card(
        color: colorBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        elevation: 5,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                  padding: HEADER_INSET,
                  child: Text(
                    '${i + 1}) ${hikeTrail.pointsOfInterest[i]['name']} \n',
                    style: TextStyle(
                        fontSize: BODY_SIZE + 4,
                        color: colorPrimary,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  )),
              cardDivider,
              Container(
                  margin: CARD_INSET,
                  child: Text(
                    '${hikeTrail.pointsOfInterest[i]['description']}\n',
                    style: bodyTextStyle,
                  )),
            ],
          ),
        ),
      );

      build.add(content);
    }

    return build;
  }
}
