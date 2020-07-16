import 'package:flutter/material.dart';
import 'package:flutter_webview/simpleExample.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter web view"),
      ),
      body: Center(
        child: Container(
            height: 300,
            child: Column(
              children: <Widget>[
                RaisedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SimpleExample()));
                    },
                    child: Text("Simple webview example")),
              ],
            )),
      ),
    );
  }
}
