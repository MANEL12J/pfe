import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';


import 'main.dart';

class chefdepartementView extends StatefulWidget {
  chefdepartementView({Key? key, this.title = "Boite de réception"}) : super(key: key);

  final String title;

  @override
  _chefdepartementView createState() => _chefdepartementView();
}

class _chefdepartementView extends State<chefdepartementView> with TickerProviderStateMixin {
  // Pagination state


  Color primary = const Color(0xffEFEDF5);
  late TabController _tabController;
  int _selectedTabIndex = 0;

  List<String> columnNames = [];
  List sug = [] ;
  List users2 = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true; // Ajouter cette ligne dans votre classe
  void getDate() async {
    setState(() => isLoading = true); // Début du chargement
    QuerySnapshot responsebody =
    await FirebaseFirestore.instance.collection('users').orderBy('timestamp', descending: true).get();
    responsebody.docs.forEach((element) {
      Map<String, dynamic>? userData = element.data() as Map<String, dynamic>?;
      setState(() {
        users2.add(userData);
      });
    });
    setState(() => isLoading = false); // Fin du chargement
  }
  void searchData(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        sug = List.from(users2);
        print("Search term is empty, displaying all users.");
      } else {
        sug = users2.where((user) =>
            user['displayName'].toLowerCase().contains(searchTerm.toLowerCase())
        ).toList();
        print("Displaying filtered users.");
      }
      print("Current suggestions: $sug"); // Log pour vérifier les données dans sug
    });
  }
  DateTime? startDate;
  DateTime? endDate;
  bool showDateRangeMessage = false;

  void _openDatePickerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Information sur la fiche des voeux',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    _buildDateTile(context, setState, 'Du', startDate, true),
                    SizedBox(height:  10,)  ,
                    _buildDateTile(context, setState, 'Au', endDate, false),
                    if (showDateRangeMessage)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          'La fiche de voeux sera disponible du ${_formatDate(startDate!)} au ${_formatDate(endDate!)}.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (startDate != null && endDate != null) {
                  _saveDates();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Confirmer les dates'),
              style: TextButton.styleFrom(primary: Colors.blue),
            ),
          ],
        );
      },
    );
  }
  ListTile _buildDateTile(BuildContext context, StateSetter setState, String label, DateTime? date, bool isStartDate) {
    return ListTile(
      title: Text('$label : ${date != null ? _formatDate(date) : "Sélectionner"}'),
      trailing: Icon(Icons.calendar_today, color: Colors.blue),
      onTap: () => _selectDate(context, setState, isStartDate),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      tileColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
  void _selectDate(BuildContext context, StateSetter setState, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? startDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
        showDateRangeMessage = startDate != null && endDate != null;
      });
    }
  }
  Future<void> _saveDates() async {
    // Créer une nouvelle référence de document avec un ID généré automatiquement
    DocumentReference docRef = FirebaseFirestore.instance.collection('dates').doc();

    // Ajouter les dates avec l'ID du document dans le même document
    await docRef.set({
      'uid': docRef.id,  // Sauvegarder l'UID dans le document
      'startDate': startDate,
      'endDate': endDate,
      'timestamp': FieldValue.serverTimestamp(),
    });


    // Récupérer tous les documents de la collection 'users'
    var snapshot = await FirebaseFirestore.instance.collection('users').get();

    // Mettre à jour le champ 'status' pour chaque utilisateur
    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'statu': 'en attente',
        'valide' : 'false',
      });
    }
  }








  void initState(){
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index; // Update the selected tab index
      });
    });
    getDate();

  }
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }









  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5,
        title: Text(widget.title, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: MaterialButton(
              color: Colors.black87,
              textColor: Colors.white,
              onPressed: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MyApp()));
              },
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Use MainAxisSize.min to wrap content within the button
                children: <Widget>[
                  Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                isScrollable: true,
                controller: _tabController,
                indicatorColor: Colors.black54,
                indicatorWeight: 3.0,
                labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                labelColor: Colors.black,
                labelPadding: const EdgeInsets.only(left: 20, right: 20),

                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "Enseigants"),
                  Tab(text: "Adjoint"),
                  Tab(text: "Répartion",)
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  isLoading ? Center(child: CircularProgressIndicator()) :
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.0),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            hintText: 'Search',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade100, width: 2.0),
                            ),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      Expanded(child:
                      Card(
                         margin: EdgeInsets.all(20),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('users').orderBy('timestamp' , descending: true).snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Center(child: CircularProgressIndicator());
                                default:
                                  List<Map<String, dynamic>> users = snapshot.data!.docs
                                      .map((DocumentSnapshot document) {
                                    return document.data() as Map<String, dynamic>;
                                  })
                                      .toList();
                                  // Filter users based on search query
                                  if (searchController.text.isNotEmpty) {
                                    users = users.where((user) {
                                      return user['displayName'].toString().toLowerCase().contains(searchController.text.toLowerCase());
                                    }).toList();
                                  }
                                  return buildUsersTable(users); // Call the function with the list of filtered users
                              }
                            },
                          )
                      )),],
                  ),
                  Container(color: Colors.grey[300], child: Center(child: Text("No data"))),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top : 8.0),
                        child: Row (
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Répartion Globale" , style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 23
                            ),),
                            ElevatedButton.icon(
                              onPressed: _openDatePickerDialog,
                              icon: Icon(Icons.calendar_today , size: 10,),  // Icône du calendrier
                              label: Text('Ajouter un deadline'),  // Texte du bouton
                              style: ElevatedButton.styleFrom(
                                primary: Colors.greenAccent,  // Couleur de fond du bouton
                                onPrimary: Colors.white,  // Couleur du texte et de l'icône
                                elevation: 5,  // Ombre du bouton
                                textStyle: TextStyle(
                                  fontSize: 13,  // Taille du texte
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),  // Padding interne du bouton
                                shape: RoundedRectangleBorder(  // Ajoutez cette ligne pour les bordures arrondies
                                    borderRadius: BorderRadius.circular(2)  // Radius de 10.0 pour les coins arrondis
                                ),
                              ),
                            ),


                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child:
                              Container(color: Colors.white,
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("Aucune répartion est disponible pour le moment" , style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize :   15
                                  ),),
                                ),
                              ),),),
                            Expanded(
                              flex: 1,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('dates').orderBy('timestamp', descending: true).snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('Erreur: ${snapshot.error}');
                                  }
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                                    // Aucune donnée disponible, vous pouvez retourner un widget vide
                                    return SizedBox.shrink(); // ou afficher un message ou autre widget ici si nécessaire
                                  }
                                  // Ici, nous avons des données, donc on construit la Card
                                  return Card(
                                    margin: EdgeInsets.all(8.0),
                                    elevation: 4,
                                    shadowColor: Colors.blueGrey,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(vertical: 6.0),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.blue[800],
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(6),
                                              topRight: Radius.circular(6),
                                            ),
                                          ),
                                          child: Text(
                                            "Détails",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: snapshot.data!.docs.length,
                                            itemBuilder: (context, index) {
                                              DocumentSnapshot doc = snapshot.data!.docs[index];
                                              Timestamp t = doc['startDate'];
                                              Timestamp t2 = doc['endDate'];
                                              DateTime startDate = t.toDate();
                                              DateTime endDate = t2.toDate();
                                              bool isExpired = endDate.isBefore(DateTime.now());

                                              return SizedBox(
                                                height: 60,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 8.0, right: 8),
                                                  child: TimelineTile(
                                                    alignment: TimelineAlign.manual,
                                                    lineXY: 0.1,
                                                    hasIndicator: true,
                                                    isFirst: index == 0,
                                                    isLast: index == snapshot.data!.docs.length - 1,
                                                    indicatorStyle: IndicatorStyle(
                                                      width: 10,
                                                      color: Colors.blue.shade300,
                                                    ),
                                                    beforeLineStyle: LineStyle(
                                                      color: Colors.blue.shade600,
                                                      thickness: 1.5,
                                                    ),
                                                    endChild: Container(
                                                      padding: EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Text(
                                                                  "De : ${startDate.day}/${startDate.month}/${startDate.year}",
                                                                  style: TextStyle(fontSize: 12),
                                                                ),
                                                                Text(
                                                                  "À : ${endDate.day}/${endDate.month}/${endDate.year}",
                                                                  style: TextStyle(fontSize: 12),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (isExpired)
                                                            Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors.red,
                                                                borderRadius: BorderRadius.circular(4),
                                                              ),
                                                              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                              child: Text(
                                                                'Fermé',
                                                                style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.bold
                                                                ),
                                                              ),
                                                            )
                                                          else
                                                            SizedBox(
                                                              width: 40, // Correspond à la taille du conteneur 'Fermé'
                                                              height: 16,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )








                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUsersTable(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(child: Text("Pas d'enseignants trouvé"));
    }

    // Assuming that all documents have the same keys
    List<String> headers = users.first.keys.where((key) => key != "timestamp" && key != "uid"&& key != "valide").toList();
    headers.sort((a, b) => a.compareTo(b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: headers.map((header) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    header,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
        Container(height: 2, color: Colors.black),
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> user = users[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: headers.map((header) {
                    if (header == "statu") {
                      return Expanded(child: statusWidget(user[header]));
                    }
                    return Expanded(
                      child: Text(
                        '${user[header] ?? 'N/A'}',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget statusWidget(String? status) {
    switch (status) {
      case "rien":
        return Container(); // Return an empty container for "rien"
      case "en attente":
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text("En attente", style: TextStyle(color: Colors.white))),
        );
      case "valider":
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text("Validé", style: TextStyle(color: Colors.white))),
        );
      case "refuser":
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text("Refusé", style: TextStyle(color: Colors.white))),
        );
      default:
        return Container(); // Default case to handle unexpected status
    }
  }








}






class navigation2 extends StatefulWidget{
  String idnavigateur;
  navigation2({Key? key, required this.idnavigateur }) : super(key: key);
  @override
  _navigation2 createState() => _navigation2(idnavigateur);
}


class _navigation2 extends State<navigation2> {
  String idnavigateur;
  int selectedindex=0;
  Color primary = const Color(0xff89B5A2);
  late List<Widget> scr ;
  _navigation2(this.idnavigateur) {
    scr = [      chefdepartementView() , chefdepartementView()  ];
  }
  final labelstyle = const TextStyle(fontWeight: FontWeight.bold , fontSize: 20);
  Color card = const Color(0xFFF9F9F9);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.black87,
            selectedIconTheme: const IconThemeData(color: Colors.black,size: 20),
            unselectedIconTheme: const IconThemeData(color: Colors.white , size: 20),
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (int i){
              setState(() {
                selectedindex = i ;
              });
            },
            selectedIndex: selectedindex,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard  ),
                  label : Text('Boite de réception ')
              ),
              NavigationRailDestination(
                  icon: Icon(Icons.add ),
                  label : Text('Historique')
              ),

            ],

            // Called when one tab is selected
            leading: Column(
              children:  [
                const SizedBox(height: 8,),
                Image.asset(
                  "assets/logoozaki-removebg-preview.png",
                  width: 90,
                  height: 90,
                  fit: BoxFit.fill,
                ),
                const SizedBox(height: 40,),
              ],
            ),

          ),
          Expanded(
              child: Container(
                  color: Colors.white,
                  child: scr[selectedindex])),
        ],
      ),



    );
  }


}
