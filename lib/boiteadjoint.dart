import 'package:flutter/material.dart';

class adjointboite extends StatefulWidget {
  adjointboite({Key? key, this.title = "adjointboite"}) : super(key: key);

  final String title;

  @override
  _adjointboite createState() => _adjointboite();
}

class _adjointboite extends State<adjointboite> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}