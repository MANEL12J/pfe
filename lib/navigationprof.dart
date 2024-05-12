import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main.dart';
import 'profView.dart';
import 'chefdepartementView.dart';
import 'package:shared_preferences/shared_preferences.dart';

class navigation extends StatefulWidget {
  final String idnavigateur;

  navigation({Key? key, required this.idnavigateur}) : super(key: key);

  @override
  _navigationState createState() => _navigationState(idnavigateur);
}

class _navigationState extends State<navigation> {
  final String idnavigateur;
  int selectedindex = 0;
  Color primary = const Color(0xff89B5A2);

  _navigationState(this.idnavigateur);

  void _onSelectItem(int index) {
    setState(() {
      selectedindex = index;
    });
  }
  Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      // Sign out from Google first
      await googleSignIn.signOut();

      // Then sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Update shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth', false);

    } catch (error) {

    }
  }
  Widget _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return MainUserweb(iduserweb: idnavigateur);
      case 1:
        return MainUserweb(iduserweb: idnavigateur);
      default:
        return Center(child: Text('Error'));
    }
  }

  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Function() onTap,
  }) {
    return Container(
      decoration: isSelected ? BoxDecoration(
          color: Colors.white, // Background color for selected item
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))
      ) : null,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.black87 : Colors.white , fontSize: 13),
        ),
        leading: Icon(icon, color: isSelected ? Colors.black87 : Colors.white ,size: 14),
        selected: isSelected,
        onTap: onTap,
        shape: isSelected ? RoundedRectangleBorder(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))
        ) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var drawer = Container(
      width: MediaQuery.of(context).size.width * 0.14, // Adjust the width as needed
      color: Colors.black87,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(left: 8),
              children: <Widget>[
                DrawerHeader(
                  child: Image.asset("assets/logoozaki-removebg-preview.png", width: 70, height: 70, fit: BoxFit.contain),
                ),
                _buildDrawerItem(
                  title: 'Boite de réception',
                  icon: Icons.inbox,
                  isSelected: selectedindex == 0,
                  onTap: () => _onSelectItem(0),
                ),
                _buildDrawerItem(
                  title: 'Historique',
                  icon: Icons.history,
                  isSelected: selectedindex == 1,
                  onTap: () => _onSelectItem(1),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: MaterialButton(
              color: Colors.red,
              textColor: Colors.white,
              onPressed: () async {
                await signOut();
                // Optionally navigate to the login screen after signing out
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp()));
              },
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Use MainAxisSize.min to wrap content within the button
                children: const <Widget>[
                  Icon(Icons.logout, color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          drawer, // Drawer is always visible
          Expanded(
            child: _getDrawerItemWidget(selectedindex), // Main content
          ),
        ],
      ),
    );
  }
}