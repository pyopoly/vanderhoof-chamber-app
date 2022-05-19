import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'map.dart';
import 'cards.dart';
import 'commonFunction.dart';
import 'fireStoreObjects.dart';
import 'main.dart';

bool hasReadDataFirstTime = false;

// Businesses populated from firebase
List<Recreational> recs = [];

// Businesses after filtering search - this is whats shown in ListView
List<Recreational> filteredRecs = [];

class Recreation extends StatefulWidget {
  Recreation({Key key}) : super(key: key);

  final title = "Recreational";

  @override
  _RecreationPageState createState() => new _RecreationPageState();
}

class _RecreationPageState extends State<Recreation> {
  bool isSearching = false;

  // Async Future variable that holds FireStore's data and functions
  Future future;
  // FireStore reference
  CollectionReference fireStore =
      FirebaseFirestore.instance.collection('recreation');
  // Controllers to check scroll position of ListView
  ItemScrollController _scrollController = ItemScrollController();
  ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _isScrollButtonVisible = false;

  // GoogleMap markers
  Set<Marker> _markers = HashSet<Marker>();

  /// firebase async method to get data
  Future _getRecs() async {
    if (!hasReadDataFirstTime) {
      print("*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/");
      await fireStore.get().then((QuerySnapshot snap) {
        recs = filteredRecs = [];
        snap.docs.forEach((doc) {
          String phone = formatPhoneNumber(doc['phone']);
          String website = formatWebsiteURL(doc['website']);
          Recreational b = Recreational(
            name: doc['name'],
            address: doc['address'],
            location: doc['LatLng'],
            description: doc["description"],
            id: doc['id'],
            phoneNumber: phone,
            email: doc['email'],
            website: website,
          );
          recs.add(b);
        });
      });
      print("_getRecs(): FINISHED READ. Stopped async method to reduce reads.");
      hasReadDataFirstTime = true;
    }

    return recs;
  }

  /// this method gets firebase data and populates into list of businesses
  // reference: https://github.com/bitfumes/flutter-country-house/blob/master/lib/Screens/AllCountries.dart
  @override
  void initState() {
    future = _getRecs();
    super.initState();
  }

  /// This method does the logic for search and changes filteredBusinesses to search results
  // reference: https://github.com/bitfumes/flutter-country-house/blob/master/lib/Screens/AllCountries.dart
  void _filterSearchItems(value) {
    setState(() {
      filteredRecs = recs
          .where((businessCard) =>
              businessCard.name.toLowerCase().contains(value.toLowerCase()))
          .toList();
      resetMarkers(_markers, filteredRecs, _scrollController);
    });
  }

  /// Widget build for AppBar with Search
  Widget _buildSearchAppBar() {
    return AppBar(
      title: !isSearching
          ? Text(widget.title)
          : TextField(
              onChanged: (value) {
                // search logic here
                _filterSearchItems(value);
              },
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  icon: Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  hintText: "Search Businesses",
                  hintStyle: TextStyle(color: Colors.white70)),
            ),
      actions: <Widget>[
        isSearching
            ? IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () {
                  _filterSearchItems("");
                  setState(() {
                    this.isSearching = false;
                    filteredRecs = recs;
                  });
                },
              )
            : IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    this.isSearching = true;
                  });
                },
              )
      ],
    );
  }

  /// Widget build for Rec ListView
  Widget _buildRecsList() {
    //=================================================
    // Scrolling Listener
    //=================================================

    // listener for the current scroll position
    // if scroll position is not near the very top, set FloatingActionButton visibility to true
    _itemPositionsListener.itemPositions.addListener(() {
      int firstPositionIndex =
          _itemPositionsListener.itemPositions.value.first.index;
      setState(() {
        firstPositionIndex > 5
            ? _isScrollButtonVisible = true
            : _isScrollButtonVisible = false;
      });
    });

    //=================================================
    // Build Widget for RecreationsList
    //=================================================
    return new Scaffold(
      body: Container(
          child: ScrollablePositionedList.builder(
        padding:
            const EdgeInsets.only(bottom: kFloatingActionButtonMargin + 48),
        itemScrollController: _scrollController,
        itemPositionsListener: _itemPositionsListener,
        itemCount: filteredRecs.length,
        itemBuilder: (BuildContext context, int index) {
          //======================
          return Card(
              margin: EdgeInsets.all(0),
              elevation: 0,
              key: Key(filteredRecs[index].id),
              child: RecreationalCard(
                  recreational: filteredRecs[index],
                  scrollController: _scrollController,
                  scrollIndex: index,
                  mapMarkers: _markers,
                  listOfFireStoreObjects: filteredRecs));
        },
      )),
      floatingActionButton:
          buildScrollToTopButton(_isScrollButtonVisible, _scrollController),
    );
  }

  ///=========================
  /// Final Build Widget
  ///=========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildSearchAppBar(),
      body: Container(
        padding: EdgeInsets.all(0.0),
        child: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                print("FutureBuilder snapshot.connectionState => none");
                return showLoadingScreen();
              case ConnectionState.active:
              case ConnectionState.waiting:
                return showLoadingScreen();
              case ConnectionState.done:
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // insert widgets here wrapped in `Expanded` as a child
                    // note: play around with flex int value to adjust vertical spaces between widgets
                    Container(
                        child: Gmap(filteredRecs, _markers, _scrollController)),
                    Expanded(
                        flex: 16,
                        child: filteredRecs.length != 0
                            ? _buildRecsList()
                            : Container(
                                child: Center(
                                child: Text("No results found",
                                    style: titleTextStyle),
                              ))),
                  ],
                );
              default:
                return Text("Default");
            }
          },
        ),
      ),
    );
  }
}
