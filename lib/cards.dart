import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:drop_cap_text/drop_cap_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';

import 'commonFunction.dart';
import 'fireStoreObjects.dart';
import 'hikeInformation.dart';
import 'main.dart';
import 'map.dart';

/// Theme for 'Show More' text button
const int SHOW_MORE_TEXT_COUNT = 150;
const EdgeInsets SHOW_MORE_INSET = EdgeInsets.fromLTRB(21, 5, 21, 0);

/// Creates a clickable widget that has an icon and text
Widget tappableIconWithText(String field, icon, onPressed, padding) {
  return (!isFieldEmpty(field))
      ? Padding(
          padding: padding,
          child: InkWell(
            onTap: () {
              onPressed(field);
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              DecoratedIcon(icon,
                  color: colorPrimary,
                  size: ICON_SIZE,
                  shadows: [
                    iconShadow,
                  ]),
              Flexible(
                child: Container(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    '$field',
                    style: headerTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ]),
          ),
        )
      : Container(width: 0, height: 0);
}

/// Represents a Business card that is displayed on the businesses page.
/// Takes the values for Business which is a business object, scrollController, scrollIndex.
class BusinessCard extends StatefulWidget {
  final Business business;
  final ItemScrollController scrollController;
  final int scrollIndex;
  final Set<Marker> mapMarkers;
  final List<FireStoreObject> listOfFireStoreObjects;

  BusinessCard(
      {this.business,
      this.scrollController,
      this.scrollIndex,
      this.mapMarkers,
      this.listOfFireStoreObjects});

  @override
  _BusinessCard createState() => _BusinessCard(
      business: business,
      scrollController: scrollController,
      scrollIndex: scrollIndex,
      mapMarkers: mapMarkers,
      listOfFireStoreObjects: listOfFireStoreObjects);
}

/// Business Card state
class _BusinessCard extends State<BusinessCard> {
  Business business;
  ItemScrollController scrollController;
  int scrollIndex;
  Set<Marker> mapMarkers;
  List<FireStoreObject> listOfFireStoreObjects;
  String firstHalf;
  String secondHalf;
  bool flag = true;

  _BusinessCard(
      {this.business,
      this.scrollController,
      this.scrollIndex,
      this.mapMarkers,
      this.listOfFireStoreObjects});

  /// Preload images
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isFieldEmpty(business.imgURL)) {
      precacheImage(NetworkImage(business.imgURL), context);
    }
  }

  /// Initialize class state and insert object to tree
  @override
  void initState() {
    super.initState();
    secondHalf = "";
    if (business.description != null) {
      if (business.description.length > SHOW_MORE_TEXT_COUNT) {
        firstHalf = business.description.substring(0, SHOW_MORE_TEXT_COUNT);
        secondHalf = business.description
            .substring(SHOW_MORE_TEXT_COUNT, business.description.length);
      } else {
        firstHalf = business.description;
      }
    }
  }

  /// Get all chip categories as a single string
  String categoryText() {
    String categories = "";
    for (var i = 0; i < business.category.length; i++) {
      if (i != business.category.length - 1) {
        categories = categories + "${business.category[i]}, ";
      } else
        categories = categories + business.category[i];
    }
    return categories;
  }

  /// Creates a social media button.
  ///
  /// This button is greyed out (not clickable) if the social media field is
  /// empty and blue (clickable) if it is not.
  Widget socialMediaButton(String field, icon, onPressed) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35),
        child: (!isFieldEmpty(field))
            ? IconButton(
                icon: DecoratedIcon(icon,
                    color: colorPrimary,
                    size: ICON_SIZE,
                    shadows: [
                      iconShadow,
                    ]),
                onPressed: () {
                  onPressed(field);
                })
            : IconButton(
                icon: DecoratedIcon(
                  icon,
                  size: ICON_SIZE,
                  color: Colors.grey[500],
                ),
                onPressed: null,
              ));
  }

  /// Final build widget for a Business Card
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 3,
        color: colorBackground,
        margin: CARD_INSET,
        child: ExpansionTile(
            onExpansionChanged: (_isExpanded) {
              if (_isExpanded) {
                // highlight map marker by changing its color
                changeMarkerColor(scrollIndex, mapMarkers,
                    listOfFireStoreObjects, scrollController);
                // highlight map marker by moving camera to its location
                if (business.location != null) {
                  changeCamera(business.location);
                }
                // scroll businesses list to expanded tile
                Future.delayed(Duration(milliseconds: 250)).then((value) {
                  scrollController.scrollTo(
                    index: scrollIndex,
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                });
              } else {
                resetMarkers(
                    mapMarkers, listOfFireStoreObjects, scrollController);
              }
            },
            title: Text(business.name, style: titleTextStyle),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              cardDivider,

              /// business description + image
              Padding(
                padding: TEXT_INSET,
                child: (!isFieldEmpty(business.description))
                    ? DropCapText(
                        (secondHalf.isEmpty)
                            ? firstHalf
                            : flag
                                ? (firstHalf + "...")
                                : (firstHalf + secondHalf),
                        // business.description,
                        style: bodyTextStyle,
                        // dropCapPadding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                        dropCapPosition: DropCapPosition.end,
                        dropCap: (!isFieldEmpty(business.imgURL))
                            ? DropCap(
                                width: 120,
                                height: 120,
                                child: Image.network(
                                  business.imgURL,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildLoadingProgressIndicator(
                                        loadingProgress);
                                  },
                                ))
                            : DropCap(width: 0, height: 0, child: null))
                    : (!isFieldEmpty(business.imgURL))
                        ? Align(
                            alignment: Alignment.topRight,
                            child: Container(
                                width: 120,
                                height: 120,
                                child: Image.network(
                                  business.imgURL,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildLoadingProgressIndicator(
                                        loadingProgress);
                                  },
                                )))
                        : Container(width: 0, height: 0),
              ),

              /// show more/less text button
              if (business.description != null && secondHalf.isNotEmpty)
                Padding(
                  padding: SHOW_MORE_INSET,
                  child: Column(
                    children: <Widget>[
                      InkWell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              flag ? "show more" : "show less",
                              style: new TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            flag = !flag;
                          });
                        },
                      ),
                    ],
                  ),
                ),

              /// business category
              Padding(
                  padding: TEXT_INSET,
                  // Checks if the category's length is empty or not
                  child: (business.category != null &&
                          business.category.length != 0
                      ? RichText(
                          text: TextSpan(children: <TextSpan>[
                          TextSpan(
                              text: 'Categories: ', style: header2TextStyle),
                          TextSpan(
                            text: categoryText(),
                            style: bodyTextStyle,
                          ),
                        ]))
                      : Container(width: 0, height: 0))),

              /// business address
              tappableIconWithText(business.address, Icons.location_on,
                  _launchAddressURL, TEXT_INSET),

              /// business phone number
              tappableIconWithText(business.phoneNumber, Icons.phone,
                  _launchPhoneURL, TEXT_INSET),

              /// business email
              tappableIconWithText(
                  business.email, Icons.email, _launchMailURL, TEXT_INSET),

              /// business website
              tappableIconWithText(business.website, Icons.language,
                  _launchWebsiteURL, TEXT_INSET),

              SizedBox(
                height: 20,
              ),

              /// business socialMedia buttons:
              /// always shows up in 1 row, icon colour is grey when empty
              (!isFieldEmpty(business.socialMedia['facebook']) ||
                      !isFieldEmpty(business.socialMedia['instagram']) ||
                      !isFieldEmpty(business.socialMedia['twitter']))
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                          /// Facebook button
                          socialMediaButton(business.socialMedia['facebook'],
                              FontAwesomeIcons.facebook, _launchFacebookURL),

                          /// Instagram button
                          socialMediaButton(business.socialMedia['instagram'],
                              FontAwesomeIcons.instagram, _launchInstaURL),

                          /// Twitter button
                          socialMediaButton(business.socialMedia['twitter'],
                              FontAwesomeIcons.twitter, _launchTwitterURL),
                        ])
                  : Container(width: 0, height: 0),
            ]));
  }
}

/// Represents a resource card that is displayed on the resource page.
/// Takes the values for Resource which is a resource object, scrollController, scrollIndex.
class ResourceCard extends StatefulWidget {
  final Resource resource;
  final ItemScrollController scrollController;
  final int scrollIndex;

  ResourceCard({this.resource, this.scrollController, this.scrollIndex});

  @override
  _ResourceCard createState() => _ResourceCard(
      resource: resource,
      scrollController: scrollController,
      scrollIndex: scrollIndex);
}

/// Resource Card state
class _ResourceCard extends State<ResourceCard> {
  Resource resource;
  ItemScrollController scrollController;
  int scrollIndex;

  _ResourceCard({this.resource, this.scrollController, this.scrollIndex});

  /// Preload images
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isFieldEmpty(resource.imgURL)) {
      precacheImage(Image.network(resource.imgURL).image, context);
    }
  }

  /// Final build widget for a Resource Card
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 3,
        color: colorBackground,
        margin: CARD_INSET,
        child: ExpansionTile(
            onExpansionChanged: (_isExpanded) {
              if (_isExpanded) {
                // scroll resources list to expanded tile
                Future.delayed(Duration(milliseconds: 250)).then((value) {
                  scrollController.scrollTo(
                    index: scrollIndex,
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                });
              }
            },
            title: Text(resource.name, style: titleTextStyle),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              cardDivider,

              /// resource image
              !(isFieldEmpty(resource.imgURL))
                  ? Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Image.network(
                        resource.imgURL,
                        fit: BoxFit.contain,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildLoadingProgressIndicator(
                              loadingProgress);
                        },
                      ),
                    )
                  : Container(width: 0, height: 0),

              /// resource description
              !(isFieldEmpty(resource.description))
                  ? Padding(
                      padding: TEXT_INSET,
                      child: Text(
                        "${resource.description}",
                        style: bodyTextStyle,
                      ),
                    )
                  : Container(width: 0, height: 0),

              /// resource website
              tappableIconWithText(resource.website, Icons.language,
                  _launchWebsiteURL, TEXT_INSET),
              SizedBox(
                height: 20,
              ),
            ]));
  }
}

/// Represents a event card that is displayed on the event page.
/// Takes the values for Event which is a event object, scrollController, scrollIndex.
class EventCard extends StatefulWidget {
  final Event event;
  final ItemScrollController scrollController;
  final int scrollIndex;

  EventCard({this.event, this.scrollController, this.scrollIndex});

  @override
  _EventCard createState() => _EventCard(
      event: event,
      scrollController: scrollController,
      scrollIndex: scrollIndex);
}

/// Event Card state
class _EventCard extends State<EventCard> {
  Event event;
  ItemScrollController scrollController;
  int scrollIndex;

  _EventCard({this.event, this.scrollController, this.scrollIndex});

  /// Preload images
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isFieldEmpty(event.imgURL)) {
      precacheImage(NetworkImage(event.imgURL), context);
    }
  }

  /// format a [dateTime] to display Month & Day
  String formatDate(DateTime dateTime) {
    String formattedDate = DateFormat('MMM d').format(dateTime);
    return formattedDate;
  }

  /// format a [dateTime] to display Month, Day & Time
  String formatDateTime(DateTime dateTime) {
    String formattedDateTime = DateFormat('MMM d ').format(dateTime) +
        DateFormat('jm').format(dateTime);
    return formattedDateTime;
  }

  /// format a [dateTime] to display Time
  String formatTime(DateTime dateTime) {
    String formattedTime = DateFormat('jm').format(dateTime);
    return formattedTime;
  }

  /// format a [dateTime] to build a date widget with Month, Day, & Weekday
  Widget _buildDateWidget(DateTime dateTime) {
    String formattedDay = DateFormat('d').format(dateTime);
    String formattedMonth = DateFormat('MMM').format(dateTime);
    String formattedWeekday = DateFormat('EEE').format(dateTime);
    return Container(
        width: 100,
        padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
        child: TextButton(
            onPressed: null,
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Column(
                children: <Widget>[
                  Text(formattedMonth,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorText,
                      )),
                  Text(formattedDay,
                      style: TextStyle(
                          fontSize: 18,
                          color: colorPrimary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Text('\t\t' + formattedWeekday,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ])));
  }

  /// Final build widget for an Event Card
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 3,
        color: colorBackground,
        margin: CARD_INSET,
        child: ExpansionTile(
            onExpansionChanged: (_isExpanded) {
              if (_isExpanded) {
                // scroll events list to expanded tile
                Future.delayed(Duration(milliseconds: 250)).then((value) {
                  scrollController.scrollTo(
                    index: scrollIndex,
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                });
              }
            },
            title: Text(event.name, style: titleTextStyle),
            leading: _buildDateWidget(event.datetimeStart),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              cardDivider,

              /// event image
              !(isFieldEmpty(event.imgURL))
                  ? Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Image.network(
                        event.imgURL,
                        fit: BoxFit.contain,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildLoadingProgressIndicator(
                              loadingProgress);
                        },
                      ),
                    )
                  : Container(width: 0, height: 0),

              /// event description
              !(isFieldEmpty(event.description))
                  ? Padding(
                      padding: TEXT_INSET,
                      child: Text(
                        "${event.description}",
                        style: bodyTextStyle,
                      ),
                    )
                  : Container(width: 0, height: 0),

              /// event dateTime
              Padding(
                  padding: EdgeInsets.zero,
                  child: Row(children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.access_time),
                      onPressed: null,
                      iconSize: ICON_SIZE,
                    ),
                    (event.isMultiday
                        ? Text(
                            '${formatDate(event.datetimeStart)} - ${formatDate(event.datetimeEnd)}',
                            style: headerTextStyle)
                        : Text(
                            '${formatDateTime(event.datetimeStart)} - ${formatTime(event.datetimeEnd)}',
                            style: headerTextStyle)),
                  ])),

              /// event location
              tappableIconWithText(event.address, Icons.location_on,
                  _launchAddressURL, EdgeInsets.only(left: 8)),

              SizedBox(
                height: 20,
              ),
            ]));
  }
}

/// Represents a hike card that is displayed on the hike page.
/// Takes the values for Hike which is a hike object, scrollController, scrollIndex.
class HikeCard extends StatefulWidget {
  final HikeTrail hikeTrail;
  final ItemScrollController scrollController;
  final int scrollIndex;
  final Set<Marker> mapMarkers;
  final List<FireStoreObject> listOfFireStoreObjects;

  HikeCard(
      {this.hikeTrail,
      this.scrollController,
      this.scrollIndex,
      this.mapMarkers,
      this.listOfFireStoreObjects});

  @override
  _HikeCard createState() => _HikeCard(
      hikeTrail: hikeTrail,
      scrollController: scrollController,
      scrollIndex: scrollIndex,
      mapMarkers: mapMarkers,
      listOfFireStoreObjects: listOfFireStoreObjects);
}

/// Hike Card state
class _HikeCard extends State<HikeCard> {
  HikeTrail hikeTrail;
  ItemScrollController scrollController;
  int scrollIndex;
  Set<Marker> mapMarkers;
  List<FireStoreObject> listOfFireStoreObjects;

  _HikeCard(
      {this.hikeTrail,
      this.scrollController,
      this.scrollIndex,
      this.mapMarkers,
      this.listOfFireStoreObjects});

  // difficulty and accessibility colors
  final Color greenColor = Colors.lightGreen[700];
  final Color orangeColor = colorAccent;
  final Color redColor = Colors.red[600];

  /// change text color to match hike difficulty
  Color getDifficultyColor() {
    Color difficultyColor;
    if (hikeTrail.rating == "Easy") {
      difficultyColor = greenColor;
    } else if (hikeTrail.rating == "Medium") {
      difficultyColor = orangeColor;
    } else {
      difficultyColor = redColor;
    }
    return difficultyColor;
  }

  /// change text color to match hike accessibility
  Color getAccessibilityColor() {
    Color accessibilityColor;
    if (hikeTrail.wheelchair == "Accessible") {
      accessibilityColor = greenColor;
    } else {
      accessibilityColor = redColor;
    }
    return accessibilityColor;
  }

  /// checks if there should be a detailed Information Page on this hike
  ///
  /// if true, build will include an 'expand' icon, otherwise there won't be an icon
  bool isThereInfoPage(HikeTrail hike) {
    return (hike.description != null || hike.pointsOfInterest != null);
  }

  /// Final build widget for a Hike Card
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: colorBackground,
      margin: CARD_INSET,
      child: ExpansionTile(
        onExpansionChanged: (_isExpanded) {
          if (_isExpanded) {
            // highlight map marker by changing its color
            changeMarkerColor(scrollIndex, mapMarkers, listOfFireStoreObjects,
                scrollController);
            // highlight map marker by moving camera to hike location
            if (hikeTrail.location != null) {
              changeCamera(hikeTrail.location);
            }
            // scroll hikes list to expanded tile
            Future.delayed(Duration(milliseconds: 250)).then((value) {
              scrollController.scrollTo(
                index: scrollIndex,
                duration: Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            });
          } else {
            resetMarkers(mapMarkers, listOfFireStoreObjects, scrollController);
          }
        },
        title: Text(
          hikeTrail.name,
          style: titleTextStyle,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          cardDivider,

          /// hike address
          tappableIconWithText(hikeTrail.address, Icons.location_on,
              _launchAddressURL, TEXT_INSET),

          Padding(
            padding: ICON_INSET,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
                    Widget>[
                  /// hike distance
                  !isFieldEmpty(hikeTrail.distance)
                      ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                          IconButton(
                            constraints: BoxConstraints(),
                            icon: Icon(Icons.timeline),
                            onPressed: null,
                            iconSize: ICON_SIZE_SMALL,
                          ),
                          Flexible(
                              child: RichText(
                                  text: TextSpan(children: <TextSpan>[
                            TextSpan(
                                text: 'Distance: ', style: header2TextStyle),
                            TextSpan(
                              text: '${hikeTrail.distance}',
                              style: bodyTextStyle,
                            ),
                          ]))),
                        ])
                      : Container(width: 0, height: 0),

                  /// hike difficulty
                  !isFieldEmpty(hikeTrail.rating)
                      ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                          IconButton(
                            constraints: BoxConstraints(),
                            icon: Icon(Icons.star_half),
                            onPressed: null,
                            iconSize: ICON_SIZE_SMALL,
                          ),
                          Flexible(
                              child: RichText(
                                  text: TextSpan(children: <TextSpan>[
                            TextSpan(
                                text: 'Difficulty: ', style: header2TextStyle),
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

                  /// hike time
                  !isFieldEmpty(hikeTrail.time)
                      ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                          IconButton(
                            constraints: BoxConstraints(),
                            icon: Icon(Icons.access_time),
                            onPressed: null,
                            iconSize: ICON_SIZE_SMALL,
                          ),
                          Flexible(
                              child: RichText(
                                  text: TextSpan(children: <TextSpan>[
                            TextSpan(text: 'Time: ', style: header2TextStyle),
                            TextSpan(
                              text: '${hikeTrail.time}',
                              style: bodyTextStyle,
                            ),
                          ]))),
                        ])
                      : Container(width: 0, height: 0),

                  /// hike wheelchair accessibility
                  !isFieldEmpty(hikeTrail.wheelchair)
                      ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                          IconButton(
                            constraints: BoxConstraints(),
                            icon: Icon(Icons.accessible_outlined),
                            onPressed: null,
                            iconSize: ICON_SIZE_SMALL,
                          ),
                          Flexible(
                              child: RichText(
                                  text: TextSpan(children: <TextSpan>[
                            TextSpan(
                                text: 'Wheelchair: ', style: header2TextStyle),
                            TextSpan(
                              text: '${hikeTrail.wheelchair}',
                              style: TextStyle(
                                fontSize: BODY_SIZE,
                                color: getAccessibilityColor(),
                              ),
                            ),
                          ]))),
                        ])
                      : Container(width: 0, height: 0),
                ]),

                /// hikeInformation page 'expand' button
                isThereInfoPage(hikeTrail)
                    ? IconButton(
                        icon: DecoratedIcon(Icons.open_in_new_outlined,
                            color: colorPrimary,
                            size: ICON_SIZE,
                            shadows: [
                              iconShadow,
                            ]),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HikeInformation(hikeTrail: hikeTrail),
                              ));
                        },
                      )
                    : Container(width: 0, height: 0),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}

/// Represents a recreational card that is displayed on the rec page.
/// Takes the values for Rec which is a recreational object, scrollController, scrollIndex.
class RecreationalCard extends StatefulWidget {
  final Recreational recreational;
  final ItemScrollController scrollController;
  final int scrollIndex;
  final Set<Marker> mapMarkers;
  final List<FireStoreObject> listOfFireStoreObjects;

  RecreationalCard(
      {this.recreational,
      this.scrollController,
      this.scrollIndex,
      this.mapMarkers,
      this.listOfFireStoreObjects});

  @override
  _RecreationalCard createState() => _RecreationalCard(
      recreational: recreational,
      scrollController: scrollController,
      scrollIndex: scrollIndex,
      mapMarkers: mapMarkers,
      listOfFireStoreObjects: listOfFireStoreObjects);
}

/// Recreational Card state
class _RecreationalCard extends State<RecreationalCard> {
  Recreational recreational;
  ItemScrollController scrollController;
  int scrollIndex;
  Set<Marker> mapMarkers;
  List<FireStoreObject> listOfFireStoreObjects;

  _RecreationalCard(
      {this.recreational,
      this.scrollController,
      this.scrollIndex,
      this.mapMarkers,
      this.listOfFireStoreObjects});

  /// Final build widget for Recreational Card
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: colorBackground,
      margin: CARD_INSET,
      child: ExpansionTile(
          onExpansionChanged: (_isExpanded) {
            if (_isExpanded) {
              // highlight map marker by changing its color
              changeMarkerColor(scrollIndex, mapMarkers, listOfFireStoreObjects,
                  scrollController);
              // highlight map marker by moving camera to rec location
              if (recreational.location != null) {
                changeCamera(recreational.location);
              }
              // scroll recreational list to expanded tile
              Future.delayed(Duration(milliseconds: 250)).then((value) {
                scrollController.scrollTo(
                  index: scrollIndex,
                  duration: Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                );
              });
            } else {
              resetMarkers(
                  mapMarkers, listOfFireStoreObjects, scrollController);
            }
          },
          title: Text(recreational.name, style: titleTextStyle),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            cardDivider,

            /// recreation description
            !(isFieldEmpty(recreational.description))
                ? Padding(
                    padding: TEXT_INSET,
                    child: Text(
                      "${recreational.description}",
                      style: bodyTextStyle,
                    ),
                  )
                : Container(width: 0, height: 0),

            /// rec address
            tappableIconWithText(recreational.address, Icons.location_on,
                _launchAddressURL, TEXT_INSET),

            /// rec phone number
            tappableIconWithText(recreational.phoneNumber, Icons.phone,
                _launchPhoneURL, TEXT_INSET),

            /// rec email
            tappableIconWithText(
                recreational.email, Icons.email, _launchMailURL, TEXT_INSET),

            /// rec website
            tappableIconWithText(recreational.website, Icons.language,
                _launchWebsiteURL, TEXT_INSET),

            SizedBox(
              height: 20,
            ),
          ]),
    );
  }
}

//==================================
// Helper Methods
//==================================

/// builds a Loading Indicator widget while images are loading
Widget _buildLoadingProgressIndicator(ImageChunkEvent loadingProgress) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes
            : null,
      ),
    ),
  );
}

/// Open URL in the default browser for [website]
void _launchWebsiteURL(String website) async =>
    await canLaunch('http://$website')
        ? launch('http://$website')
        : Fluttertoast.showToast(
            msg: "Could not open website http://$website",
            toastLength: Toast.LENGTH_SHORT);

/// Open URL in Instagram for [username] profile
void _launchInstaURL(String username) async {
  String url = username;
  if (!username.contains('.com/')) {
    url = "https://www.instagram.com/$username/";
  } else if (!username.startsWith('http')) {
    url = "https://$username/";
  }
  await canLaunch(url)
      ? launch(url)
      : Fluttertoast.showToast(
          msg: "Could not open Instagram profile: $username",
          toastLength: Toast.LENGTH_SHORT);
}

/// Open URL in Facebook for [username] profile
void _launchFacebookURL(String username) async {
  String url = username;
  if (!username.contains('.com/')) {
    url = "https://www.facebook.com/$username/";
  } else if (!username.startsWith('http')) {
    url = "https://$username/";
  }
  await canLaunch(url)
      ? launch(url)
      : Fluttertoast.showToast(
          msg: "Could not open Facebook profile: $username",
          toastLength: Toast.LENGTH_SHORT);
}

/// Open URL in Twitter for [username] profile
void _launchTwitterURL(username) async {
  String url = username;
  if (!username.contains('.com/')) {
    url = "https://www.twitter.com/$username/";
  } else if (!username.startsWith('http')) {
    url = "https://$username/";
  }
  await canLaunch(url)
      ? launch(url)
      : Fluttertoast.showToast(
          msg: "Could not open Twitter profile: $username",
          toastLength: Toast.LENGTH_SHORT);
}

/// Make a phone call to [phoneNumber]
void _launchPhoneURL(String phoneNumber) async =>
    await canLaunch('tel:$phoneNumber')
        ? launch('tel:$phoneNumber')
        : Fluttertoast.showToast(
            msg: "Could not set up a call for $phoneNumber",
            toastLength: Toast.LENGTH_SHORT);

/// Create email to [email]
void _launchMailURL(String email) async => await canLaunch('mailto:$email')
    ? launch('mailto:$email')
    : Fluttertoast.showToast(
        msg: "Could not open the email app for $email",
        toastLength: Toast.LENGTH_SHORT);

/// Open URL in GoogleMaps for [address]
void _launchAddressURL(address) async =>
    await canLaunch('https://www.google.com/maps/search/?api=1&query=$address')
        ? launch('https://www.google.com/maps/search/?api=1&query=$address')
        : Fluttertoast.showToast(
            msg: "Could not open directions for $address.",
            toastLength: Toast.LENGTH_SHORT);
