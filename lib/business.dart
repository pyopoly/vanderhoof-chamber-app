import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'cards.dart';
import 'commonFunction.dart';
import 'fireStoreObjects.dart';
import 'main.dart';
import 'map.dart';
import 'data.dart';

bool hasReadDataFirstTime = false;
// Businesses populated from firebase
List<Business> businesses = [];

// Businesses after filtering search - this is whats shown in ListView
List<Business> filteredBusinesses = [];

List<Widget> chips2;

class BusinessState extends StatefulWidget {
  BusinessState({Key key}) : super(key: key);

  final title = "Businesses";

  @override
  _BusinessPageState createState() => new _BusinessPageState();
}

class _BusinessPageState extends State<BusinessState> {
  bool isSearching = false;

  // Async Future variable that holds FireStore's data and functions
  Future future;
  // FireStore reference
  CollectionReference fireStore =
      FirebaseFirestore.instance.collection('businesses');
  // Controllers to check scroll position of ListView
  ItemScrollController _scrollController = ItemScrollController();
  ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _isScrollButtonVisible = false;

  // GoogleMap markers
  Set<Marker> _markers = HashSet<Marker>();

  // Choice Chips for Category
  int _selectedIndex;

  /// firebase async method to get data
  Future _getBusinesses() async {
    if (!hasReadDataFirstTime) {
      print("*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/");
      await fireStore.get().then((QuerySnapshot snap) {
        businesses = filteredBusinesses = [];
        snap.docs.forEach((doc) {
          String phone = formatPhoneNumber(doc['phone']);
          String website = formatWebsiteURL(doc['website']);
          Business b = Business(
              name: doc['name'],
              address: doc['address'],
              location: doc['LatLng'],
              description: doc["description"],
              phoneNumber: phone,
              email: doc['email'],
              socialMedia: doc['socialMedia'],
              website: website,
              imgURL: doc['imgURL'],
              category: doc['category'],
              id: doc['id']);
          businesses.add(b);
        });
      });
      print(
          "_getBusinesses(): FINISHED READ. Stopped async method to reduce reads.");
      hasReadDataFirstTime = true;
    }
    businesses.sort((a, b) => (a.name).compareTo(b.name));
    return businesses;
  }

  /// this method gets firebase data and populates into list of businesses
  // reference: https://github.com/bitfumes/flutter-country-house/blob/master/lib/Screens/AllCountries.dart
  @override
  void initState() {
    future = _getBusinesses();
    super.initState();
  }

  /// This method does the logic for search and changes filteredBusinesses to search results
  // reference: https://github.com/bitfumes/flutter-country-house/blob/master/lib/Screens/AllCountries.dart
  void _filterSearchItems(value) {
    setState(() {
      filteredBusinesses = businesses
          .where((businessCard) =>
              businessCard.name.toLowerCase().contains(value.toLowerCase()))
          .toList();
      resetMarkers(_markers, filteredBusinesses, _scrollController);
    });
  }

  void scrollToIndex(int index) {
    _scrollController.scrollTo(
      index: index,
      duration: Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
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
                    filteredBusinesses = businesses;
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

  /// Widget build for Businesses ListView
  Widget _buildBusinessesList() {
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
    // Build Widget for BusinessesList
    //=================================================
    return new Scaffold(
      body: Container(
          child: ScrollablePositionedList.builder(
        padding:
            const EdgeInsets.only(bottom: kFloatingActionButtonMargin + 48),
        itemScrollController: _scrollController,
        itemPositionsListener: _itemPositionsListener,
        itemCount: filteredBusinesses.length,
        itemBuilder: (BuildContext context, int index) {
          //======================
          return Card(
              margin: EdgeInsets.all(0),
              elevation: 0,
              key: Key(filteredBusinesses[index].id),
              child: BusinessCard(
                  business: filteredBusinesses[index],
                  scrollController: _scrollController,
                  scrollIndex: index,
                  mapMarkers: _markers,
                  listOfFireStoreObjects: filteredBusinesses));
        },
      )),
      floatingActionButton:
          buildScrollToTopButton(_isScrollButtonVisible, _scrollController),
    );
  }

  /// Widget build for ChoiceChip for filtering businesses by category
  Widget _buildChips() {
    List<Widget> chips = [];

    void _filterSearchItemsByCategory(value) {
      setState(() {
        filteredBusinesses = businesses.where((businessCard) {
          if (businessCard.category != null &&
              businessCard.category.length != 0) {
            return (businessCard.category).contains(value);
          } else {
            return false;
          }
        }).toList();
        resetMarkers(_markers, filteredBusinesses, _scrollController);
      });
    }

    // get a ChoiceChip widget for each category
    for (int i = 0; i < categoryOptions.length; i++) {
      ChoiceChip choiceChip = ChoiceChip(
        selected: _selectedIndex == i,
        label: Text(categoryOptions[i], style: bodyTextStyle),
        elevation: 3,
        pressElevation: 5,
        backgroundColor: createMaterialColor(Color(0xFFE3E3E3)),
        selectedColor: colorAccent,
        onSelected: (bool selected) {
          setState(() {
            if (selected) {
              _selectedIndex = i;
              _filterSearchItemsByCategory(categoryOptions[i]);
            } else {
              _selectedIndex = null;
              filteredBusinesses = businesses;
              resetMarkers(_markers, filteredBusinesses, _scrollController);
            }
          });
        },
      );

      chips.add(Padding(
          padding: EdgeInsets.symmetric(horizontal: 10), child: choiceChip));
    }

    chips2 = chips;

    return ListView(
      // This next line does the trick.
      scrollDirection: Axis.horizontal,
      children: chips,
    );
  }

  ///=========================
  /// Final Build Widget
  ///=========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Drawer: Hamburger menu for Admin
      appBar: _buildSearchAppBar(),
      body: Container(
        padding: EdgeInsets.all(0.0),
        child: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
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
                        child: Gmap(
                            filteredBusinesses, _markers, _scrollController)),
                    Container(
                      width: double.infinity,
                      height: 50.0,
                      child: _buildChips(),
                    ),
                    Expanded(
                        flex: 14,
                        child: filteredBusinesses.length != 0
                            ? _buildBusinessesList()
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
