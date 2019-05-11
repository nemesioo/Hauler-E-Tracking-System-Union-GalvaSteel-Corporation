import 'package:flutter/material.dart';
import 'dart:async';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Delivery extends StatefulWidget {
  final List destination;
  final String origin;
  Delivery({this.destination, this.origin});
  @override
  State<StatefulWidget> createState() {
    return _DeliveryState(destination);
  }
}

class _DeliveryState extends State<Delivery> {
  List destination;
  // _DeliveryState.destination(this.destination);

  var count = 0;
  Map<dynamic, TextEditingController> controllers = {};
  List selectedDestination = [];
  // Map<dynamic, String> destinationMap = {};
  // List destinationLis
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  String plateNumber, truckType, truckName;
  String _searchText = "";
  TextEditingController _search = TextEditingController();

  bool verify = false;
  String message;

  @override
  Widget build(BuildContext context) {
    // return selectArea();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Image(
          image: AssetImage('assets/images/galva.png'),
        ),
      ),
      body: Center(
        child: Container(child: multipleDR(context)),
      ),
    );
  }

  @override
  void dispose() {
    controllers.forEach((k, v) => v.dispose());
    super.dispose();
  }

  bool isNumber(value) {
    try {
      return double.parse(value) != null;
    } catch (e) {
      return false;
    }
  }

  _DeliveryState(this.destination) {
    try {
      _search.addListener(() {
        if (_search.text.isEmpty) {
          setState(() {
            _searchText = "";
            // areas = fetchAreas;
          });
        } else {
          setState(() {
            _searchText = _search.text;
          });
        }
      });
    } catch (e) {}
  }

  Future _scan(BuildContext context) async {
    try {
      String qrValue = await BarcodeScanner.scan();
      var parsedQrValue = json.decode(qrValue);
      if (parsedQrValue['plateNumber'] != null &&
          parsedQrValue['truckName'] != null &&
          parsedQrValue['truckType'] != null) {
        setState(() {
          plateNumber = parsedQrValue['plateNumber'];
          truckName = parsedQrValue['truckName'];
          truckType = parsedQrValue['truckType'];
          // count = 0;
          // controllers.clear();
          // selectedDestination.clear();
          message = null;
          verify = false;
        });
        _scriptCommunication(context);
      } else {
        var snackBar = SnackBar(content: Text('QR Code Invalid'));
        Scaffold.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      var snackBar = SnackBar(content: Text('Something went Wrong!'));
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }

  Future _scriptCommunication(BuildContext context) async {
    try {
      var urlList = [];
      http.Response res;
      controllers.forEach((k, v) {
        var url =
            "https://script.google.com/macros/s/AKfycbyPOmOjy9Cc3AI15JvjR1F78o6Cf-tD1qiOl4KUweCvY9FKYvQ/exec?truck_name=$truckName&truck_type=$truckType&delivery_number=${v.text}&plate_number=$plateNumber&origin=${widget.origin}";
        urlList.add(url);
      });
      for (int i = 0; i < controllers.length; i++) {
        print("${urlList[i]}&destination=${selectedDestination[i]}");
        res = await http.get(
            Uri.encodeFull(
                "${urlList[i]}&destination=${selectedDestination[i]}"),
            headers: {"Accept": "application/json"});
      }
      var resBody = json.decode(res.body);
      var snackBar = SnackBar(content: Text(resBody['message']));
      Scaffold.of(context).showSnackBar(snackBar);
    } catch (e) {
      var snackBar = SnackBar(content: Text('Check Internet Connection'));
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }

  Widget multipleDR(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          Container(
            child: Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: ListTile(
                leading: GestureDetector(
                  onTap: () {
                    setState(() {
                      count = 0;
                      controllers.clear();
                      selectedDestination.clear();
                      message = null;
                      verify = false;
                    });
                  },
                  child: Icon(Icons.refresh),
                ),
                title: Center(
                  child: Text(
                    'DELIVERY NUMBER',
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    count != 0
                        ? GestureDetector(
                            onTap: () {
                              controllers
                                  .forEach((k, v) => print('$k: ${v.text}'));
                              if (_formKey.currentState.validate() &&
                                  verify == true) {
                                _scan(context);
                              }
                            },
                            child: Icon(
                              Icons.camera_alt,
                              size: 40.0,
                              color: Colors.lightGreen,
                            ),
                          )
                        : Text(''),
                    SizedBox(
                      width: 10.0,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          count++;
                          selectedDestination.add('');
                          verify = false;
                        });
                      },
                      child: Icon(
                        Icons.add,
                        color: Colors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
              padding: message == null
                  ? const EdgeInsets.all(0.0)
                  : const EdgeInsets.all(20.0),
              child: message == null
                  ? Container(height: 0.0, width: 0.0)
                  : Container(
                      child: Center(
                        child: Text('$message',
                            style:
                                TextStyle(fontSize: 15.0, color: Colors.red)),
                      ),
                    )),
          ListView.builder(
            reverse: true,
            shrinkWrap: true,
            itemCount: count,
            itemBuilder: (BuildContext context, int index) {
              var drController = TextEditingController();
              controllers.putIfAbsent("$index", () => drController);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 175.0,
                        child: TextFormField(
                          controller: controllers['$index'],
                          validator: (value) {
                            if (value.isEmpty) {
                              setState(() {
                                message = "Please Enter Delivery Number";
                              });
                              return '';
                            } else if (!isNumber(value)) {
                              setState(() {
                                message = "Numbers Only";
                              });
                              return '';
                            } else if (checkSelectedDestination() == true) {
                              setState(() {
                                message = "Please Set Destination";
                              });
                              return null;
                            } else {
                              setState(() {
                                message = null;
                                verify = true;
                              });
                            }
                          },
                          keyboardType: TextInputType.numberWithOptions(),
                          decoration: InputDecoration(
                            labelText: 'Delivery Number',
                            errorStyle: TextStyle(
                                color: Colors.redAccent, fontSize: 0.0),
                            contentPadding:
                                EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            navigateToSelectArea(index);
                          },
                          child: selectedDestination.isEmpty ||
                                  selectedDestination[index] == ""
                              ? Row(children: <Widget>[
                                  IconButton(
                                      onPressed: () {
                                        navigateToSelectArea(index);
                                      },
                                      tooltip: 'Set destination',
                                      icon: Icon(Icons.gps_fixed),
                                      color: Colors.red),
                                  Text('Set destination')
                                ])
                              : Container(
                                  padding: EdgeInsets.only(left: 12.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                          width: 5.0, color: Colors.green),
                                    ),
                                  ),
                                  child: Text('${selectedDestination[index]}'),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool checkSelectedDestination() {
    var val;
    for (var item in selectedDestination) {
      print("checkSelectedDestination $item");
      if (item == "") val = true;
    }
    return val;
  }

  void navigateToSelectArea(int index) async {
    String tmpLoc = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => selectArea()));
    print(tmpLoc);
    if (tmpLoc != null && tmpLoc != "") {
      selectedDestination[index] = tmpLoc;
    }
  }

  Widget selectArea() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: TextField(
          controller: _search,
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.teal),
              hintText: 'Search Area'),
        ),
        backgroundColor: Colors.grey,
      ),
      body: areaList(),
    );
  }

  Widget areaList() {
    if (!(_searchText.isEmpty)) {
      List tmpList = List();
      for (int i = 0; i < destination.length; i++) {
        if (destination[i]['area']
            .toLowerCase()
            .contains(_searchText.toLowerCase())) {
          tmpList.add(destination[i]);
        }
      }
      destination = tmpList;
    }
    return ListView.builder(
      itemCount: destination.length,
      itemBuilder: (BuildContext context, int index) => Card(
            elevation: 8.0,
            margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context, destination[index]['area'].toString());
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.grey),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  leading: Container(
                    padding: EdgeInsets.only(right: 12.0),
                    decoration: BoxDecoration(
                        border: Border(
                            right:
                                BorderSide(width: 5.0, color: Colors.white54))),
                    child: Icon(
                      Icons.gps_fixed,
                      color: Colors.white,
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () {
                      Navigator.pop(
                          context, destination[index]['area'].toString());
                    },
                    child: Text(
                      '${destination[index]['area']}',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
