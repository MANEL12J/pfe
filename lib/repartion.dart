import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class AdjointRep extends StatefulWidget {
  String idnavigateur;
  AdjointRep({Key? key, required this.idnavigateur }) : super(key: key);
  @override
  _AdjointRep createState() => _AdjointRep(idnavigateur);
}

class _AdjointRep extends State<AdjointRep> with TickerProviderStateMixin {
  String idnavigateur;
  _AdjointRep(this.idnavigateur);

  List<String> courses = [];
  String? selectedParcours;
  String? selectedSemestre;
  int? nombreGroupes;
  final List<String> parcours = ['L1', 'L2', 'L3', 'M1', 'M2'];
  final List<String> semestres = ['Semestre 1', 'Semestre 2'];
  final TextEditingController groupeController = TextEditingController();
  Widget? customTable;
  late TabController _tabController;
  int _selectedTabIndex = 0;
  List<Map<String, dynamic>> filteredUsers = [];
  Future<List<Map<String, dynamic>>> getUsersByParcoursAndSemester(String parcours, String semester) async {
    List<Map<String, dynamic>> usersData = [];
    var usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var user in usersSnapshot.docs) {
      // Get additional user info such as displayName and grade
      var displayName = user.data()['displayName'] ?? "No name";
      var grade = user.data()['grade'] ?? "No grade";

      // Navigate into the specific semester collection in 'fiche de voeux'
      var ficheSnapshot = await user.reference.collection('fiche de voeux').doc(semester).get();
      if (ficheSnapshot.exists) {
        var modules = ficheSnapshot.data()?['modules'] as List;
        for (var module in modules) {
          if (module['parcours'] == parcours) {
            usersData.add({
              'moduleName': module['moduleName'],
              'parcours': module['parcours'],
              'semester': semester,
              'user': user.id,
              'displayName': displayName,
              'grade': grade
            });
            // This break ensures only the first match is added per user per semester; remove if you want all matches.
            break;
          }
        }
      }
    }
    return usersData;
  }
  String abbreviate(String text) {
    List<String> words = text.split(' '); // Sépare le texte en mots.
    List<String> ignoreWords = ['de', 'la', 'le', 'les', 'des']; // Mots à ignorer
    String abbreviation = '';

    // Cas spécifique pour des mots complets comme "Professeur"
    if (text.trim().toLowerCase() == 'professeur') {
      return 'Pr.';
    }

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (word.isNotEmpty && !ignoreWords.contains(word.toLowerCase())) {
        if (word.length == 1) { // Pour des mots comme 'A' dans "Maître Assistant A"
          abbreviation += word;
        } else {
          // Ajouter la première lettre du premier mot en majuscule, le reste en minuscule
          if (i == 0) {
            abbreviation += word[0].toUpperCase(); // La première lettre du premier mot en majuscule
          } else {
            abbreviation += word[0].toLowerCase(); // La première lettre des autres mots en minuscule
          }
        }
      }
    }
    return abbreviation; // Retourne le résultat avec la première lettre en majuscule et le reste en minuscule
  }






  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index; // Update the selected tab index
      });

    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  String? selectedUserId;
  String? selectedUserId2;
  void selectUser(String userId) {
    setState(() {
      selectedUserId = userId;
    });
  }
  String searchText = '';
  void _valider(StateSetter updateState, String selectedParcours, String selectedSemestre, TextEditingController groupeController) async {
    if (selectedParcours.isNotEmpty && selectedSemestre.isNotEmpty && groupeController.text.isNotEmpty) {
      int? nombreGroupes = int.tryParse(groupeController.text);
      if (nombreGroupes != null) {
        // Détermination du semestre correct
        String semestre = selectedSemestre == "Semestre 1" ? "semetre1" : "semetre2";

        // Récupération des utilisateurs correspondant au parcours et au semestre
        List<Map<String, dynamic>> users = await getUsersByParcoursAndSemester(selectedParcours, semestre);

        // Mise à jour de l'interface utilisateur dans le dialogue
        updateState(() {
          filteredUsers = users;
          customTable = _buildCustomTable(selectedParcours, selectedSemestre, nombreGroupes);
        });

      } else {
        // Réinitialisation de l'interface utilisateur en cas d'erreur
        updateState(() {
          filteredUsers = [];
          customTable = null;
        });
      }
    }
  }
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('messages').add({
        'text': _messageController.text,
        'createdAt': Timestamp.now(),
        'userId': idnavigateur,
      });
      _messageController.clear();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Increase the AppBar's height
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black87,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("AdjointView" , style: TextStyle(color: Colors.white, fontSize: 23),),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                isScrollable: true,
                controller: _tabController,
                indicatorColor: Colors.blueAccent,
                indicatorWeight: 5.0,
                labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                labelColor: Colors.black,
                labelPadding: const EdgeInsets.only(left: 30, right: 30),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "Répartition"),
                  Tab(text: "Liste fiches des voeux"),
                  Tab(text: "Boite de Réception"),

                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  //PREMIER TAB
                  Container(
                    child:
                    Row(
                      children: [
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    child: StatefulBuilder(
                                      builder: (BuildContext context, StateSetter setState) {
                                        return Container(
                                          width: MediaQuery.of(context).size.width * 0.9,
                                          height: MediaQuery.of(context).size.height * 0.9,
                                          child: SingleChildScrollView(
                                            child: premierTabContent(setState: setState),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              child: Text('Répartion'),
                            ),
                            SizedBox(width: 10,) ,
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(  // Utilisez StatefulBuilder ici
                                      builder: (BuildContext context, StateSetter setState) {  // Notez le `setState` ici
                                        return Dialog(
                                          child: Container(
                                            width: MediaQuery.of(context).size.width * 0.9,
                                            height: MediaQuery.of(context).size.height * 0.9,
                                            child: Card(
                                              margin: EdgeInsets.all(20),
                                              child: StreamBuilder<QuerySnapshot>(
                                                stream: FirebaseFirestore.instance.collection('users').orderBy('timestamp', descending: true).snapshots(),
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

                                                      return Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 3,
                                                            child: buildUsersTable(users, context, onSelectUser: (String userId) {
                                                              setState(() {  // Utilisez le setState local de StatefulBuilder
                                                                selectedUserId2 = userId;
                                                              });
                                                            }),
                                                          ),
                                                          Expanded(
                                                            flex: 3,
                                                            child: selectedUserId2 == null
                                                                ? Center(child: Text("Sélectionnez un utilisateur pour voir les détails"))
                                                                : userDetails(selectedUserId2),
                                                          ),
                                                        ],
                                                      );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              child: Text('Liste des voeux'),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Expanded(
                              child: StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection('messages')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (ctx, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
                                  if (chatSnapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                  final chatDocs = chatSnapshot.data!.docs;
                                  return ListView.builder(
                                    reverse: true,
                                    itemCount: chatDocs.length,
                                    itemBuilder: (ctx, index) {
                                      var isMe = chatDocs[index]['userId'] == idnavigateur;
                                      return ListTile(
                                        leading: isMe ? null : CircleAvatar(child: Icon(Icons.person)),
                                        title: Container(
                                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: isMe ? Colors.grey[300] : Colors.blue[400],
                                            borderRadius: isMe
                                                ? BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                              bottomLeft: Radius.circular(12),
                                            )
                                                : BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            chatDocs[index]['text'],
                                            style: TextStyle(color: isMe ? Colors.black : Colors.white),
                                          ),
                                        ),
                                        trailing: isMe ? CircleAvatar(child: Icon(Icons.person)) : null,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        labelText: 'Send a message...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.send, color: Colors.blueGrey),
                                    onPressed: _sendMessage,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),




                      ],
                    ),
                  ),
                  //DEUXIEUR  TAB
                  Container(
                    child: deuxiemeTabContent(),
                  ),
                  //TROISIEME TAB
                 Container(),



                ]),
          ),
        ],
      ),
    );
  }


  Widget buildUsersTable(List<Map<String, dynamic>> users, BuildContext context, {required Function(String) onSelectUser}) {
    if (users.isEmpty) {
      return Center(child: Text("Pas d'enseignants trouvé"));
    }

    // Assuming that all documents have the same keys
    List<String> headers = users.first.keys.where((key) => key != "timestamp" && key != "uid" && key != "valide" && key != "email").toList();
    headers.sort((a, b) => a.compareTo(b));  // Sort headers alphabetically

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row with styling
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
        // Divider line
        Container(height: 2, color: Colors.black),
        // List of users
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> user = users[index];
              return InkWell(
                onTap: () => onSelectUser(user['uid']),  // Trigger the onSelectUser callback
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: headers.map((header) {
                      return Expanded(
                        child: Text(
                          '${user[header] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      );
                    }).toList(),
                  ),
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

// Helper method to create a decorated container for dropdowns
  Widget decorBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
  Widget userSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var documents = snapshot.data!.docs;
        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 0,
              color: Colors.white,
              margin: EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.blue, width: 1.0),  // Only bottom border
                  ),
                ),
                child: ListTile(
                  title: Text(
                    documents[index]['displayName'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),  // Smaller font size
                  ),
                  subtitle: Text(
                    "Grade: ${documents[index]['grade']}",
                    style: TextStyle(fontSize: 10),  // Smaller font size for subtitle
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14),  // Smaller icon
                  onTap: () => selectUser(documents[index]['uid']),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),  // Reduced padding
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget userDetails(String? userId) {
    if (userId == null) {
      return Center(child: Text("", style: TextStyle(fontSize: 14)));
    }

    return Column(
      children: [
        Center(child: Text('Fiche de voeux', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22))),
        Expanded(
          child: semesterDetails(userId, 'semetre1'),
        ),
        Expanded(
          child: semesterDetails(userId, 'semetre2'),
        ),
      ],
    );
  }
  Widget semesterDetails(String? userId, String semester) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fiche de voeux')
          .doc(semester)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Erreur de chargement', style: TextStyle(color: Colors.red, fontSize: 14));
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Center(child: CircularProgressIndicator());
        }

        var document = snapshot.data!.data() as Map<String, dynamic>;
        var modules = document['modules'] as List<dynamic>;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$semester', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 4),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,  // Single column for a table-like layout
                    childAspectRatio: MediaQuery.of(context).size.width / 70,  // Adjust childAspectRatio based on screen width to fix height
                  ),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> module = modules[index];
                    return Container(
                      height: 30,  // Fixed height for each row
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                          top: BorderSide(color: Colors.grey[300]!, width: 1),
                          left: BorderSide(color: Colors.grey[300]!, width: 1),
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3, // Allocates 3 parts of space for the module name, more space due to potential length
                              child: Text("Module: ${module['moduleName']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                            Expanded(
                              child: Text("Parcours: ${module['parcours']}", style: TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: Text("Course: ${module['course'] ? 'Yes' : 'No'}", style: TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: Text("TD: ${module['td'] ? 'Yes' : 'No'}", style: TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: Text("TP: ${module['tp'] ? 'Yes' : 'No'}", style: TextStyle(fontSize: 13)),
                            ),
                          ],
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
    );
  }
  Widget deuxiemeTabContent(){
    return  Row(
      children: <Widget>[
        Expanded(
          flex:1 ,  // Adjusted for better spacing
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Rechercher :",
                      style: TextStyle(fontSize: 20, color: Colors.black87),
                    ),
                  ),
                  Expanded(
                    child: Padding( // Padding added here
                      padding: EdgeInsets.only(top: 10.0), // Top padding only
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Entrer le nom',
                          prefixIcon: Icon(Icons.search),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0), // No vertical padding inside the TextField
                          border: OutlineInputBorder( // Changed to OutlineInputBorder for clearer visibility
                            borderRadius: BorderRadius.circular(8.0), // More pronounced rounded corners
                            borderSide: BorderSide(color: Colors.grey, width: 1.0), // Visible grey border
                          ),
                          focusedBorder: OutlineInputBorder( // Border style when the TextField is focused
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey, width: 2.0), // Thicker blue border
                          ),
                          enabledBorder: OutlineInputBorder( // Border style when the TextField is enabled but not focused
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey, width: 1.0),
                          ),
                        ),
                      ),
                    ),
                  ),],),
                  Expanded(
                        child: userSearchResults(),
                   ),
             ],
          ),
        ),
        SizedBox(width: 100,),
        Expanded(
          flex: 2, // Adjusted for better spacing
          child: userDetails(selectedUserId),
        ),],
    );
  }
  Widget premierTabContent({required void Function(void Function()) setState}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // Dropdown for parcours selection
                Expanded(
                  child: decorBox(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedParcours,
                        hint: Text('Choisir un parcours'),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedParcours = newValue;
                          });
                        },
                        items: parcours.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Dropdown for semester selection
                Expanded(
                  child: decorBox(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedSemestre,
                        hint: Text('Choisir un semestre'),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedSemestre = newValue;
                          });
                        },
                        items: semestres.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // TextField for group number input
                Expanded(
                  child: Container(
                    height: 48,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: groupeController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de groupes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.group),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Button to validate the input
                ElevatedButton(
                  onPressed:  (){
                    _valider(setState, selectedParcours!, selectedSemestre!, groupeController);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                  ),
                  child: Text(
                    'Valider',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          if (customTable != null)
            Container(
              height: MediaQuery.of(context).size.height * 0.95,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Expanded(
                          child: customTable!, // Assurez-vous que customTable est capable de gérer l'overflow.
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Recommendation",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        Expanded(
                            child: ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (BuildContext context, int index) {
                                var user = filteredUsers[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                              user['displayName'],
                                              overflow: TextOverflow.ellipsis, // Ajoute des points de suspension si nécessaire
                                              maxLines: 1, // Garde le texte sur une seule ligne
                                            )
                                        ),
                                        Expanded(
                                            child: Text(
                                              abbreviate(user['grade']),
                                              overflow: TextOverflow.ellipsis, // Ajoute des points de suspension si nécessaire
                                              maxLines: 1, // Garde le texte sur une seule ligne
                                            )
                                        )
                                      ],
                                    ),
                                    subtitle: Text(
                                      "Module: ${user['moduleName']}",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis, // Gère le texte long dans le sous-titre
                                      maxLines: 1, // Garde le sous-titre sur une seule ligne
                                    ),
                                  ),
                                );
                              },
                            )

                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          // Optionally add more widgets or another column here depending on your UI needs
        ],
      ),
    );
  }
  Widget _buildCustomTable(String selectedParcours, String selectedSemestre, int numberOfGroups) {
    _updateCourses(selectedParcours, selectedSemestre);
    List<Widget> rows = [
      Divider(),
      _buildCoursesHeader(),
      Divider(thickness: 2, color: Colors.black),
      _buildEmptyRowWithLabel(),
      Divider(thickness: 2, color: Colors.black),
    ];

    // Adding all TDs
    for (int i = 1; i <= numberOfGroups; i++) {
      rows.add(_buildGroupRow('TD', i));
    }

    // Adding a separator between TDs and TPs
    rows.add(Divider(thickness: 2, color: Colors.black));

    // Adding all TPs
    for (int i = 1; i <= numberOfGroups; i++) {
      rows.add(_buildGroupRow('TP', i));
    }

    return SingleChildScrollView(
      child: Column(
        children: rows,
      ),
    );
  }
  Widget _buildEmptyRowWithLabel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text('Cours', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold,fontSize: 10)),
            ),
            ...List.generate(courses.length, (index) => Expanded(
              child: TextField(
                style: TextStyle(fontSize: 10),
                decoration: InputDecoration(
                  hintText: '',
                  hintStyle: TextStyle(fontSize: 10),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  constraints: BoxConstraints(
                    maxHeight: 30, // Hauteur maximale du TextField réduite
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
  Widget _buildCoursesHeader() {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: Colors.grey[300],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Expanded(
              child: Text('MODULES', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...courses.map((course) => Expanded(
              child: Text(course, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            )).toList(),
          ],
        ),
      ),
    );
  }
  Widget _buildGroupRow(String type, int number) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Text('$type$number', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold , fontSize: 10)),
            ),
            ...List.generate(courses.length, (index) => Expanded(
              child: TextField(
                style: TextStyle(fontSize: 10),
                decoration: InputDecoration(
                  hintText: '',
                  hintStyle: TextStyle(fontSize: 10),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  constraints: BoxConstraints(
                    maxHeight: 30, // Hauteur maximale du TextField réduite
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
  void _updateCourses( String selectedParcours, String selectedSemestre) {
    // Define course lists for each year and semester
    if (selectedParcours == 'L1') {
      if (selectedSemestre == 'Semestre 1') {
        courses = [
          'Analyse1', 'Algèbre 1', 'ASD', 'Structure Machine 1',
          'Terminologie Scientifique', 'Langue Étrangère',
          'Option (Physique / Mécanique du Point)'
        ];
      } else {
        courses = [
          'Analyse2', 'Algèbre 2', 'ASD 2', 'Structure Machine 2',
          'Proba/ statistique', 'Technologies de l\'information et communication',
          'Option (Physique / Mécanique du Point)'
        ];
      }
    } else if (selectedParcours == 'L2') {
      if (selectedSemestre == 'Semestre 1') {
        courses = [
          'Architecture ordinateur', 'ASD3', 'THG', 'Système d\'information',
          'Méthodes numériques', 'Logique mathématiques', 'Langue étrangère 2'
        ];
      } else {
        courses = [
          'THL', 'Système d\'exploitation 1', 'Base de données', 'Réseaux',
          'Programmation orientée objet', 'Développement applications web',
          'Langue étrangère 3'
        ];
      }
    } else if (selectedParcours == 'L3') {
      if (selectedSemestre == 'Semestre 1') {
        courses = [
          'Système d\'exploitation 2', 'Compilation', 'IHM', 'Génie logiciel',
          'Programmation linéaire', 'Probabilités et statistiques',
          'Économie numérique'
        ];
      } else {
        courses = [
          'Applications mobiles', 'Sécurité informatique', 'Intelligence artificielle', 'Données semi-structurées',
          'Rédaction scientifique', 'Projet',
          'Création et développement web'
        ];
      }
    }
  }





}






