import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'repartion.dart';
import 'boiteadjoint.dart';
import 'main.dart';

class navigationadjoint extends StatefulWidget {
  String idnavigateur;
  navigationadjoint({Key? key, required this.idnavigateur}) : super(key: key);
  @override
  _navigationadjoint createState() => _navigationadjoint(idnavigateur);
}

class _navigationadjoint extends State<navigationadjoint> {
  String idnavigateur;
  int selectedindex = 0;
  Color primary = const Color(0xff89B5A2);
  late List<Widget> scr;
  _navigationadjoint(this.idnavigateur) {
    scr = [AdjointRep(idnavigateur: "adjoint"), adjointboite()];
  }
  final labelstyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
  Color card = const Color(0xFFF9F9F9);
  void _onSelectItem(int index) {
    setState(() {
      selectedindex = index;
    });
  }

  Widget _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return AdjointRep(idnavigateur: "adjoint");
      case 1:
        return adjointboite();
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
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.orange, // Background color for selected item
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20)))
          : null,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87, fontSize: 13),
        ),
        leading: Icon(icon,
            color: isSelected ? Colors.white : Colors.black87, size: 14),
        selected: isSelected,
        onTap: onTap,
        shape: isSelected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20)))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var drawer = Container(
      width: MediaQuery.of(context).size.width * 0.19, // Adjust the width as needed
      color: Colors.white,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(left: 8),
              children: <Widget>[
                DrawerHeader(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'M',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 24,
                          ),
                        ),
                        TextSpan(
                          text: 'atiérelink',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildDrawerItem(
                  title: 'Répartion',
                  icon: Icons.dashboard_customize_rounded,
                  isSelected: selectedindex == 0,
                  onTap: () => _onSelectItem(0),
                ),
                _buildDrawerItem(
                  title: 'Boite de Réception',
                  icon: Icons.chat_outlined,
                  isSelected: selectedindex == 1,
                  onTap: () => _onSelectItem(1),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: MaterialButton(
              color: Colors.red,
              textColor: Colors.white,
              onPressed: () async {
                // Optionally navigate to the login screen after signing out
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => MyApp()));
              },
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize
                    .min, // Use MainAxisSize.min to wrap content within the button
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          drawer,
          Expanded(
            flex :3 ,
            child: _getDrawerItemWidget(selectedindex), // Main content
          ),
        ],
      ),
    );
  }
}
