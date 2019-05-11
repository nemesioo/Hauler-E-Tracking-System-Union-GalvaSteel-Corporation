import 'package:flutter/material.dart';
import 'package:device_info/device_info.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

//modules/options
import 'modules/options/delivery.dart';
import 'modules/options/data.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GalvaSteelTracking(),
    ));

class GalvaSteelTracking extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GalvaSteelTrackingState();
  }
}

class _GalvaSteelTrackingState extends State<GalvaSteelTracking> {
  var appTheme = ThemeData(
      appBarTheme: AppBarTheme(color: Colors.white),
      primaryColor: Colors.green,
      accentColor: Colors.redAccent);

  int _currentIndex = 0;
  List<Widget> _options = [];

  var refreshKey = GlobalKey<RefreshIndicatorState>();
  bool showMain;
  String destinantion;
  var deviceID;
  String _searchText = "";
  TextEditingController _search = TextEditingController();
  List areas = [];
  var deviceModel;
  var fetchAreas;
  bool wait;
  bool noInternet;
  bool showSearch;
  bool refresh;
  String origin;

  _GalvaSteelTrackingState() {
    try {
      _search.addListener(() {
        if (_search.text.isEmpty) {
          setState(() {
            _searchText = "";
            areas = fetchAreas;
          });
        } else {
          setState(() {
            _searchText = _search.text;
          });
        }
      });
    } catch (e) {}
  }

  Future getLocations(BuildContext context) async {
    try {
      var url =
          "https://script.google.com/macros/s/AKfycbyPOmOjy9Cc3AI15JvjR1F78o6Cf-tD1qiOl4KUweCvY9FKYvQ/exec?area=all";
      http.Response res = await http
          .get(Uri.encodeFull(url), headers: {"Accept": "application/json"});
      fetchAreas = json.decode(res.body).toList();
      // print(fetchAreas);
      setState(() {
        areas = fetchAreas;
        _options.add(Delivery(destination: areas, origin: origin,));
        // noInternet = true;
      });
      print('getLocations areas: $areas');
    } catch (e) {
      // customSnackbar(context, 'Check Internet Connection');
      // print('No data');
      refresh = true;
    }
  }

  void onTabNavigation(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
    });
  }

  // @override
  // void dispose() {
  //   super.dispose();
  //   getLocations(context);
  //   deviceInfo();
  //   showMain = false;
  //   wait = true;
  //   noInternet = false;
  //   showSearch = false;
  //   refresh = true;
  // }

  @override
  void initState() {
    super.initState();
    getLocations(context);
    deviceInfo();
    showMain = false;
    wait = true;
    noInternet = false;
    showSearch = false;
    refresh = true;
  }

  deviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceID = androidInfo.androidId;

    setState(() {
      deviceID = androidInfo.androidId;
      deviceModel = '${androidInfo.model} - ${androidInfo.manufacturer}';
    });

    // print("deviceModel: $deviceModel");

    verifyArea();
  }

  Future verifyArea() async {
    // print(deviceID);
    try {
      var url =
          "https://script.google.com/macros/s/AKfycbyPOmOjy9Cc3AI15JvjR1F78o6Cf-tD1qiOl4KUweCvY9FKYvQ/exec?device_id=$deviceID";
      http.Response res = await http
          .get(Uri.encodeFull(url), headers: {"Accept": "application/json"});
      var location = json.decode(res.body);
      setState(() {
        origin = location['location'];
        _options = [
          Data(
            location: location['location'],
          )

        ];
      });
      print('verifyarea areas: $areas');
      // print(location['location']);
      // print(deviceID);
      if (location['location'] != null) {
        setState(() {
          showMain = true;
        });
      } else {
        // getLocations(context);
        setState(() {
          wait = false;
        });
      }
    } catch (e) {
      print('error');
      setState(() {
        noInternet = true;
      });
    }
  }

  void customSnackbar(BuildContext context, String message) {
    var snackBar = SnackBar(content: Text('$message'));
    Scaffold.of(context).showSnackBar(snackBar);
  }

  Future writeArea(var location) async {
    print("writeArea: $deviceModel");
    var url =
        "https://script.google.com/macros/s/AKfycbyPOmOjy9Cc3AI15JvjR1F78o6Cf-tD1qiOl4KUweCvY9FKYvQ/exec?device_id=$deviceID&location=$location&device_model=$deviceModel";
    http.Response res = await http
        .get(Uri.encodeFull(url), headers: {"Accept": "application/json"});
    var message = json.decode(res.body);
    if (message['message'] != null) {
      verifyArea();
    }
  }

  void _showDialog(var value) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Area of Choice',
              style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
            ),
            content: Text(
              value,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  // func();
                  writeArea(value);
                  setState(() {
                    wait = true;
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Select'),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return showMain == true
        ? Scaffold(
            body: _options[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              fixedColor: appTheme.primaryColor,
              currentIndex: _currentIndex,
              onTap: onTabNavigation,
              items: [
                BottomNavigationBarItem(
                    icon: Icon(Icons.event_note), title: Text('Records')),
                BottomNavigationBarItem(
                    icon: Icon(Icons.local_grocery_store),
                    title: Text('Delivery'))
              ],
            ),
          )
        : wait == true ? waitList() : checkArea(context);
  }

  Widget waitList() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              noInternet = false;
            });
            verifyArea();
          },
          child: noInternet == true
              ? Icon(
                  Icons.refresh,
                  color: Colors.cyan,
                  size: 30.0,
                )
              : CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget checkArea(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: areas.length == 0 ? Colors.black : Colors.white,
        title: areas.length == 0
            ? Container(height: 0, width: 0)
            : TextField(
                controller: _search,
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.teal),
                    hintText: 'Search Area'),
              ),
      ),
      body: areas.length == 0 ? refreshArea() : areaList(context),
    );
  }

  Widget refreshArea() {
    return Center(
      child: Container(
          child: refresh == true
              ? GestureDetector(
                  onTap: () {
                    getLocations(context);
                    setState(() {
                      refresh = false;
                    });
                  },
                  child: Icon(Icons.refresh, color: Colors.teal, size: 50.0,))
              : CircularProgressIndicator()),
    );
  }

  Widget areaList(BuildContext context) {
    if (!(_searchText.isEmpty)) {
      List tmpList = List();
      for (int i = 0; i < areas.length; i++) {
        if (areas[i]['area']
            .toLowerCase()
            .contains(_searchText.toLowerCase())) {
          tmpList.add(areas[i]);
        }
      }
      areas = tmpList;
    }

    return RefreshIndicator(
      onRefresh: () => refreshList(context),
      child: ListView.builder(
        itemCount: areas.length,
        itemBuilder: (BuildContext context, int index) =>
            areaCard(context, index),
      ),
    );
  }

  Widget areaCard(BuildContext context, int index) {
    // setState((){
    //   showSearch = true;
    // });
    return GestureDetector(
      onTap: () => _showDialog(areas[index]['area']),
      child: Card(
        elevation: 8.0,
        margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Container(
          decoration: BoxDecoration(color: Colors.grey),
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            leading: Container(
              padding: EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(width: 5.0, color: Colors.white54))),
              child: Icon(
                Icons.gps_fixed,
                color: Colors.white,
              ),
            ),
            title: Text(
              '${areas[index]['area']}',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Future<Null> refreshList(BuildContext context) async {
    getLocations(context);
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(Duration(seconds: 5));
    return null;
  }
}
