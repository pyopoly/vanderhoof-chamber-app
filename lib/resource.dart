import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'commonFunction.dart';
import 'cards.dart';
import 'fireStoreObjects.dart';

bool hasReadDataFirstTime = false;

// Events populated from firebase
List<Resource> resources = [];

// Events after filtering search - this is whats shown in ListView
List<Resource> filteredResources = [];

class ResourceState extends StatefulWidget {
  ResourceState({Key key}) : super(key: key);

  final title = "Business Resources";

  @override
  _ResourcePageState createState() => new _ResourcePageState();
}

class _ResourcePageState extends State<ResourceState> {
  bool isSearching = false;

  // Async Future variable that holds FireStore's data and functions
  Future future;
  // FireStore reference
  CollectionReference fireStore =
      FirebaseFirestore.instance.collection('resources');

  // Controllers to check scroll position of ListView
  ItemScrollController _scrollController = ItemScrollController();
  ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _isScrollButtonVisible = false;

  /// firebase async method to get data
  Future _getResources() async {
    if (!hasReadDataFirstTime) {
      print("*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/");
      await fireStore.get().then((QuerySnapshot snap) {
        resources = filteredResources = [];
        snap.docs.forEach((doc) {
          String website = formatWebsiteURL(doc['website']);
          Resource resource = Resource(
            name: doc['name'],
            description: doc['description'],
            website: website,
            id: doc['id'],
            imgURL: doc['imgURL'],
          );
          resources.add(resource);
        });
      });
      print(
          "_getResources(): FINISHED READ. Stopped async method to reduce reads.");
      hasReadDataFirstTime = true;
    }

    return resources;
  }

  /// this method gets firebase data and populates into list of events
  @override
  void initState() {
    future = _getResources();
    super.initState();
  }

  /// This method does the logic for search and changes filteredEvents to search results
  void _filterSearchItems(value) {
    setState(() {
      filteredResources = resources
          .where((resource) =>
              resource.name.toLowerCase().contains(value.toLowerCase()))
          .toList();
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
                  hintText: "Search Business Resources",
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
                    filteredResources = resources;
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

  /// Widget build for Events ListView
  Widget _buildResourcesList() {
    //=================================================
    // Scrolling Listener
    //=================================================

    // listener for the current scroll position
    // if scroll position is not near the very top, set FloatingActionButton visibility to true
    _itemPositionsListener.itemPositions.addListener(() {
      int firstPositionIndex =
          _itemPositionsListener.itemPositions.value.first.index;
      setState(() {
        firstPositionIndex > 0
            ? _isScrollButtonVisible = true
            : _isScrollButtonVisible = false;
      });
    });

    //=================================================
    // Build Widget for ResourcesList
    //=================================================
    return new Scaffold(
      body: Container(
          child: ScrollablePositionedList.builder(
        padding:
            const EdgeInsets.only(bottom: kFloatingActionButtonMargin + 48),
        itemScrollController: _scrollController,
        itemPositionsListener: _itemPositionsListener,
        itemCount: filteredResources.length,
        itemBuilder: (BuildContext context, int index) {
          //======================
          return Card(
              margin: EdgeInsets.all(0),
              elevation: 0,
              key: Key(filteredResources[index].id),
              child: ResourceCard(
                  resource: filteredResources[index],
                  scrollController: _scrollController,
                  scrollIndex: index));
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
                    Image(
                        image: AssetImage(
                            'assets/images/vanderhoof_chamber_logo_large.png')),
                    Expanded(flex: 1, child: _buildResourcesList()),
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

//=================================================
// Backgrounds for Edit/Delete
//=================================================
Widget slideRightEditBackground() {
  return Container(
    color: Colors.green,
    child: Align(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 20,
          ),
          Icon(
            Icons.edit,
            color: Colors.white,
          ),
          Text(
            " Edit",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
      alignment: Alignment.centerLeft,
    ),
  );
}

Widget slideLeftDeleteBackground() {
  return Container(
    color: Colors.red,
    child: Align(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Icon(
            Icons.delete,
            color: Colors.white,
          ),
          Text(
            " Delete",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(
            width: 20,
          ),
        ],
      ),
      alignment: Alignment.centerRight,
    ),
  );
}
