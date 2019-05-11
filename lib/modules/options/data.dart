import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Data extends StatefulWidget {
  final location;
  Data({Key key, this.location}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _DataState();
  }
}

class _DataState extends State<Data> {
  List haulers = [];
  List fetchHaulersReverse = [];
  bool noInternet = false;
  bool preBuild;
  bool circular = false;
  var refreshKey = GlobalKey<RefreshIndicatorState>();
  var timer;

  String _searchText = "";
  TextEditingController _search = TextEditingController();
  Icon _searchIcon = Icon(
    Icons.search,
    color: Colors.teal,
  );
  Widget _appBarTitle = Image(image: AssetImage('assets/images/galva.png'));

  Future _getData(BuildContext context) async {
    try {
      if (preBuild == false) customSnackbar(context, 'Processing');
      var url =
          "https://script.google.com/macros/s/AKfycbyPOmOjy9Cc3AI15JvjR1F78o6Cf-tD1qiOl4KUweCvY9FKYvQ/exec?records=get";
      http.Response res = await http
          .get(Uri.encodeFull(url), headers: {"Accept": "application/json"});
      fetchHaulersReverse = json.decode(res.body).reversed.toList();

      setState(() {
        haulers = fetchHaulersReverse;
        noInternet = true;
      });

      // print(haulers[0]["date"]);
    } catch (e) {
      if (preBuild == false) {
        customSnackbar(context, 'Check Internet Connection');
      }
    }
  }

  Future<Null> refreshList(BuildContext context) async {
    _getData(context);
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(Duration(seconds: 5));
    return null;
  }

  _DataState() {
    _search.addListener(() {
      if (_search.text.isEmpty) {
        setState(() {
          _searchText = "";
          haulers = fetchHaulersReverse;
        });
      } else {
        setState(() {
          _searchText = _search.text;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    preBuild = true;
    _getData(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading:
            GestureDetector(onTap: () => _searchPressed(), child: _searchIcon),
        title: _appBarTitle,
      ),
      body: Center(
        child: noInternet == false
            ? _internetConnectionError(context)
            : _haulersList(context),
      ),
    );
  }

  Widget _haulerList(BuildContext context, int index) {
    return Card(
      elevation: 8.0,
      margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration:
            BoxDecoration(color: checkColor('${haulers[index]['status']}')),
        child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            leading: GestureDetector(
              onTap: () => _showDialog(index),
              child: Container(
                height: 50.0,
                padding: EdgeInsets.only(right: 12.0),
                decoration: BoxDecoration(
                    border: Border(
                  right: BorderSide(
                    width: 5.0,
                    color: Colors.white54,
                  ),
                )),
                child: checkIcon('${haulers[index]['status']}'),
              ),
            ),
            title: GestureDetector(
              onTap: () => _showDialog(index),
              child: Text(
                '${haulers[index]['plateNumber']} - ${haulers[index]['truckName']} (${haulers[index]['truckType']})',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: GestureDetector(
                onTap: () => _showDialog(index),
                child: checkSubtitle(haulers, index)),
            trailing: GestureDetector(
              onTap: () {
                _confirm(haulers[index]['drNumber']);
              },
              child: haulers[index]['status'] == 'Intransit'
                  ? Container(
                      height: 50.0,
                      padding: EdgeInsets.only(left: 12.0),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 5.0,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.move_to_inbox,
                        color: Colors.white,
                      ),
                    )
                  : Container(
                      height: 0,
                      width: 0,
                    ),
            )),
      ),
    );
  }

  dateParser(String date) {
    var parsedDate = DateTime.parse(date).toLocal();
    return DateFormat.yMMMMEEEEd().add_jms().format(parsedDate);
  }

  Future delivered(var dr) async {
    try {
      print({'$dr - ${widget.location}'});
      var url =
          "https://script.google.com/macros/s/AKfycbyPOmOjy9Cc3AI15JvjR1F78o6Cf-tD1qiOl4KUweCvY9FKYvQ/exec?deliver=complete&delivery_number=$dr";
      http.Response res = await http
          .get(Uri.encodeFull(url), headers: {"Accept": "application/json"});
      print(res);
      setState(() {
        noInternet = false;
        circular = false;
      });
      _getData(context);
    } catch (e) {
      customSnackbar(context, "Connection Error");
    }
  }

  void _confirm(var val) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              child: AlertDialog(
                content: Text('Mark as Delivered'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                      delivered(val);
                    },
                    child: Text('Confirm'),
                  )
                ],
              ),
            ),
          );
        });
  }

  void _showDialog(int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              height: 400.0,
              child: AlertDialog(
                title: Text("Hauler Information"),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Delivery Number: ${haulers[index]['drNumber']}'),
                    Text('Truck Name: ${haulers[index]['truckName']}'),
                    Text('Plate Number: ${haulers[index]['plateNumber']}'),
                    Text('Truck Type: ${haulers[index]['truckType']}'),
                    Text(
                        'Delivery Date: ${dateParser(haulers[index]['drDate'])}'),
                    haulers[index]['status'] != 'Intransit'
                        ? Text(
                            'Arrival Date: ${dateParser(haulers[index]['arrivalDate'])}')
                        : Container(width: 0, height: 0),
                    Text('Origin: ${haulers[index]['origin']}'),
                    Text('Destination: ${haulers[index]['destination']}'),
                    Text('Status: ${haulers[index]['status']}'),
                  ],
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                elevation: 8.0,
              ),
            ),
          );
        });
  }

  Widget _haulersList(BuildContext context) {
    if (!(_searchText.isEmpty)) {
      List tmpList = List();
      for (int i = 0; i < haulers.length; i++) {
        if (haulers[i]['plateNumber']
            .toLowerCase()
            .contains(_searchText.toLowerCase())) {
          tmpList.add(haulers[i]);
        }
      }
      haulers = tmpList;
    }
    return RefreshIndicator(
      onRefresh: () => refreshList(context),
      child: ListView.builder(
        itemCount: haulers.length,
        itemBuilder: (BuildContext context, int index) =>
            _haulerList(context, index),
      ),
    );
  }

  Widget _internetConnectionError(BuildContext context) {
    return Center(
      child: circularToRefresh(),
    );
  }

  Widget circularToRefresh() {
    timer = Timer(Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          circular = true;
        });
      }
    });
    return circular == false
        ? CircularProgressIndicator()
        : GestureDetector(
            onTap: () {
              setState(() {
                circular = false;
                preBuild = false;
              });
              _getData(context);
            },
            child: Icon(
              Icons.refresh,
              color: Colors.cyan,
              size: 70.0,
            ),
          );
  }

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = Icon(
          Icons.close,
          color: Colors.red,
        );
        this._appBarTitle = TextField(
          controller: _search,
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.teal),
              hintText: 'Search Plate Number'),
        );
      } else {
        this._searchIcon = Icon(Icons.search, color: Colors.teal);
        this._appBarTitle = Image(image: AssetImage('assets/images/galva.png'));
        haulers = fetchHaulersReverse;
        _search.clear();
      }
    });
  }

  Widget checkSubtitle(List haulers, int index) {
    return haulers[index]['status'] == 'Intransit'
        ? Text('Delivery Date: ${dateParser(haulers[index]['drDate'])}',
            style: TextStyle(color: Colors.white))
        : Text('Arrival Date: ${dateParser(haulers[index]['arrivalDate'])}',
            style: TextStyle(color: Colors.white));
  }

  Color checkColor(String status) {
    return status == 'Intransit' ? Colors.red : Colors.green;
  }

  Icon checkIcon(String status) {
    return status == 'Intransit'
        ? Icon(
            Icons.local_shipping,
            color: Colors.white,
          )
        : Icon(Icons.check_circle, color: Colors.white);
  }

  void customSnackbar(BuildContext context, String message) {
    var snackBar = SnackBar(content: Text('$message'));
    Scaffold.of(context).showSnackBar(snackBar);
  }
}
