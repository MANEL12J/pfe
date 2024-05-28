import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'nagivateuradjoint.dart'; // Alias for the external badges package

class AdjointRep extends StatefulWidget {
  String idnavigateur;
  AdjointRep({Key? key, required this.idnavigateur}) : super(key: key);
  @override
  _AdjointRep createState() => _AdjointRep(idnavigateur);
}

class _AdjointRep extends State<AdjointRep> {
  String idnavigateur;


  _AdjointRep(this.idnavigateur);

  List<String> courses = [];
  String? selectedParcours;
  String? errorMessage;
  String? selectedSemestre;
  int? nombreGroupes;
  int nombreGroupes2  = 0 ;
  final List<String> parcours = ['L1', 'L2', 'L3'];
  final List<String> semestres = ['Semestre 1', 'Semestre 2'];
  final TextEditingController groupeController = TextEditingController();
  List<TextEditingController> emptyRowControllers = [];
  List<List<TextEditingController>> groupControllersTD = [];
  List<List<TextEditingController>> groupControllersTP = [];
  Widget? customTable;

  List<Map<String, dynamic>> filteredUsers = [];
  Future<List<Map<String, dynamic>>> getUsersByParcoursAndSemester(String parcours, String semester) async {
    List<Map<String, dynamic>> usersData = [];
    var usersSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    for (var user in usersSnapshot.docs) {
      // Get additional user info such as displayName and grade
      var displayName = user.data()['displayName'] ?? "No name";
      var grade = user.data()['grade'] ?? "No grade";

      // Navigate into the specific semester collection in 'fiche de voeux'
      var ficheSnapshot =
      await user.reference.collection('fiche de voeux').doc(semester).get();
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
    List<String> ignoreWords = [
      'de',
      'la',
      'le',
      'les',
      'des'
    ]; // Mots à ignorer
    String abbreviation = '';

    // Cas spécifique pour des mots complets comme "Professeur"
    if (text.trim().toLowerCase() == 'professeur') {
      return 'Pr.';
    }

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (word.isNotEmpty && !ignoreWords.contains(word.toLowerCase())) {
        if (word.length == 1) {
          // Pour des mots comme 'A' dans "Maître Assistant A"
          abbreviation += word;
        } else {
          // Ajouter la première lettre du premier mot en majuscule, le reste en minuscule
          if (i == 0) {
            abbreviation += word[0]
                .toUpperCase(); // La première lettre du premier mot en majuscule
          } else {
            abbreviation += word[0]
                .toLowerCase(); // La première lettre des autres mots en minuscule
          }
        }
      }
    }
    return abbreviation; // Retourne le résultat avec la première lettre en majuscule et le reste en minuscule
  }

  @override
  void initState() {
    super.initState();
    _fetchChartData();
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
    if (selectedParcours.isNotEmpty &&
        selectedSemestre.isNotEmpty &&
        groupeController.text.isNotEmpty) {
      int? nombreGroupes = int.tryParse(groupeController.text);
      if (nombreGroupes != null) {
        // Détermination du semestre correct
        String semestre =
        selectedSemestre == "Semestre 1" ? "semetre1" : "semetre2";

        // Récupération des utilisateurs correspondant au parcours et au semestre
        List<Map<String, dynamic>> users =
        await getUsersByParcoursAndSemester(selectedParcours, semestre);

        // Mise à jour de l'état de manière synchrone
        updateState(() {
          filteredUsers = users;
          nombreGroupes2 = int.tryParse(groupeController.text)!;
          _updateCourses(selectedParcours, selectedSemestre);
          if (courses.isNotEmpty) {
            _initializeControllers(nombreGroupes2);
            customTable = _buildCustomTable(selectedParcours, selectedSemestre, nombreGroupes);
          } else {
            customTable = null;
          }
        });

      } else {
        // Réinitialisation de l'état en cas d'erreur
        updateState(() {
          filteredUsers = [];
          customTable = null;
        });
      }
    }
  }



  Future<Map<String, int>> gatherProfData() async {
    Map<String, int> profCount = {};

    void addEntry(String prof) {
      if (prof.isNotEmpty) {
        profCount.update(prof, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    // Collecte depuis emptyRowControllers
    for (int i = 0; i < emptyRowControllers.length; i++) {
      String prof = emptyRowControllers[i].text;
      addEntry(prof);
    }

    // Collecte depuis groupControllersTD
    for (var controllers in groupControllersTD) {
      for (var controller in controllers) {
        String prof = controller.text;
        addEntry(prof);
      }
    }

    // Collecte depuis groupControllersTP
    for (var controllers in groupControllersTP) {
      for (var controller in controllers) {
        String prof = controller.text;
        addEntry(prof);
      }
    }

    return profCount;
  }
  Future<void> _showRepartitionDialog(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final int anneeActuelle = DateTime.now().year;

    DocumentReference anneeRef = firestore.collection('repartition').doc(anneeActuelle.toString());

    Map<String, Map<String, Map<String, Map<String, String>>>> repartitionData = {};

    List<String> parcoursList = ['L1', 'L2', 'L3'];
    List<String> semestreList = ['Semestre 1', 'Semestre 2'];

    Future<void> fetchData() async {
      for (String parcours in parcoursList) {
        repartitionData[parcours] = {};
        for (String semestre in semestreList) {
          List<String> modules = _getModulesForParcoursSemestre(parcours, semestre);
          repartitionData[parcours]![semestre] = {};

          for (String module in modules) {
            repartitionData[parcours]![semestre]![module] = {'Cours': 'N/A', 'TD': 'N/A', 'TP': 'N/A'};
            for (String type in ['Cours', 'TD', 'TP']) {
              try {
                var collectionRef = anneeRef.collection(parcours).doc(semestre).collection(type);
                var snapshot = await collectionRef.where('module', isEqualTo: module).get();
                var profs = snapshot.docs.isNotEmpty
                    ? snapshot.docs.map((doc) => doc.data()['prof'] as String? ?? 'N/A').join(', ')
                    : 'N/A';
                repartitionData[parcours]![semestre]![module]![type] = profs;
              } catch (e) {
                print("Error accessing Firestore for $type: $e");
              }
            }
          }
        }
      }
    }


    Map<String, int> calculateProfOverloads() {
      Map<String, int> profCounts = {};
      repartitionData.forEach((parcours, semestres) {
        semestres.forEach((semestre, modules) {
          modules.forEach((module, types) {
            types.forEach((type, profs) {
              profs.split(', ').forEach((prof) {
                if (prof != 'N/A') {
                  profCounts[prof] = (profCounts[prof] ?? 0) + 1;
                }
              });
            });
          });
        });
      });
      return profCounts;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Données de Répartition"),
              SizedBox(width: 20),
              Container(
                height: 48,
                child: MaterialButton(
                  onPressed: () async {
                    await fetchData();
                    Map<String, int> profOverloads = calculateProfOverloads();
                    bool overloadExists = profOverloads.values.any((count) => count > 8);

                    if (overloadExists) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Surcharge détectée"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: profOverloads.entries
                                  .where((entry) => entry.value > 8)
                                  .map((entry) => Text("${entry.key}: ${entry.value}"))
                                  .toList(),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text("OK"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      final int currentYear = DateTime.now().year;
                      await firestore.collection('repartition').doc(currentYear.toString()).set({
                        'valide': 'en attente',
                      }, SetOptions(merge: true));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => navigationadjoint(idnavigateur: "adjoint")),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Répartition envoyée au chef de département')),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  color: Colors.blue,
                  textColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("Envoyer au chef de département"),
                ),
              ),
            ],
          ),
          content: FutureBuilder(
            future: fetchData(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Erreur lors du chargement des données"));
              } else {
                return SingleChildScrollView(
                  child: Column(
                    children: parcoursList.map((parcours) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(parcours, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: semestreList.map((semestre) {
                              List<String> modules = _getModulesForParcoursSemestre(parcours, semestre);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(semestre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                                      child: Table(
                                        border: TableBorder.all(color: Colors.grey, width: 1),
                                        defaultColumnWidth: FixedColumnWidth(100.0),
                                        children: [
                                          TableRow(
                                            decoration: BoxDecoration(color: Colors.grey[300]),
                                            children: [
                                              TableCell(
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text('Modules', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              ...modules.map((module) {
                                                return TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(module, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                          ...['Cours', 'TD', 'TP'].map((type) {
                                            return TableRow(
                                              children: [
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(type, style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                                ...modules.map((module) {
                                                  String cellValue = repartitionData[parcours]![semestre]![module]![type] ?? 'N/A';
                                                  return TableCell(
                                                    child: Container(
                                                      color: cellValue == 'N/A' ? Colors.orange[200] : null,
                                                      padding: EdgeInsets.all(8.0),
                                                      child: Text(cellValue),
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                          Divider(
                            thickness: 2.0, // Set the thickness to 2.0 pixels
                            color: Colors.black, // You can also change the color if needed
                          ), // Add a divider here
                        ],
                      );
                    }).toList(),
                  ),
                );
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  List<String> _getModulesForParcoursSemestre(String parcours, String semestre) {
    Map<String, Map<String, List<String>>> courses = {
      'L1': {
        'Semestre 1': [
          'Analyse1', 'Algèbre 1', 'ASD', 'Structure Machine 1', 'Terminologie Scientifique', 'Langue Étrangère', 'Option (Physique / Mécanique du Point)'
        ],
        'Semestre 2': [
          'Analyse2', 'Algèbre 2', 'ASD 2', 'Structure Machine 2', 'Proba/ statistique', 'Technologies de l\'information et communication', 'Option (Physique / Mécanique du Point)', 'Outills de programmation pour les mathématiques'
        ]
      },
      'L2': {
        'Semestre 1': [
          'Architecture ordinateur', 'ASD3', 'THG', 'Système d\'information', 'Méthodes numériques', 'Logique mathématiques', 'Langue étrangère 2'
        ],
        'Semestre 2': [
          'THL', 'Système d\'exploitation 1', 'Base de données', 'Réseaux', 'Programmation orientée objet', 'Développement applications web', 'Langue étrangère 3'
        ]
      },
      'L3': {
        'Semestre 1': [
          'Système d\'exploitation 2', 'Compilation', 'IHM', 'Génie logiciel', 'Programmation linéaire', 'Probabilités et statistiques', 'Économie numérique'
        ],
        'Semestre 2': [
          'Applications mobiles', 'Sécurité informatique', 'Intelligence artificielle', 'Données semi-structurées', 'Rédaction scientifique', 'Projet', 'Création et développement web'
        ]
      }
    };

    return courses[parcours]?[semestre] ?? [];
  }







  Future<void> _saveDataToFirebase() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final int anneeActuelle = DateTime.now().year;
    DocumentReference anneeDocRef = firestore.collection('repartition').doc(anneeActuelle.toString());

    // Retrieve the document first
    DocumentSnapshot anneeDocSnapshot = await anneeDocRef.get();

    // Check if 'valid' field exists, if not, initialize it to 'non'
    if (anneeDocSnapshot.exists) {
      Map<String, dynamic> data = anneeDocSnapshot.data() as Map<String, dynamic>? ?? {};
      if (!data.containsKey('valide')) {
        anneeDocRef.set({'valide': 'non'}, SetOptions(merge: true)); // Using merge to not overwrite other fields
      }
    } else {
      // Document does not exist, set 'valid' to 'non'
      anneeDocRef.set({'validE': 'non'});
    }

    // Example of how you might save course data
    for (int i = 0; i < emptyRowControllers.length; i++) {
      final module = courses[i];
      final contenu = emptyRowControllers[i].text;
      if (module.isNotEmpty) {
        await firestore
            .collection('repartition')
            .doc(anneeActuelle.toString())
            .collection(selectedParcours!)
            .doc(selectedSemestre!)
            .collection('Cours')
            .add({
          'prof': contenu,
          'module': module,
          'parcours': selectedParcours,
          'semestre': selectedSemestre!,
          'type': 'Cours',
        });
      }
    }

    // Continue with saving TD and TP data as in the previous message

    // Boucle à travers les groupes TD
    for (int i = 0; i < groupControllersTD.length; i++) {
      final numeroGroupe = i + 1;

      // Sauvegarde des données pour chaque module TD
      for (int j = 0; j < groupControllersTD[i].length; j++) {
        final module = courses[j];
        final contenu = groupControllersTD[i][j].text;

        if (contenu.isNotEmpty) {
          await firestore
              .collection('repartition')
              .doc(anneeActuelle.toString())
              .collection(selectedParcours!)
              .doc(selectedSemestre!)
              .collection('TD')
              .add({
            'prof': contenu,
            'module': module,
            'parcours': selectedParcours,
            'semestre': selectedSemestre!,
            'type' : ' TD: ${i+1}',
          });
        }
      }
    }

    // Boucle à travers les groupes TP
    for (int i = 0; i < groupControllersTP.length; i++) {
      final numeroGroupe = i + 1;

      // Sauvegarde des données pour chaque module TP
      for (int j = 0; j < groupControllersTP[i].length; j++) {
        final module = courses[j];
        final contenu = groupControllersTP[i][j].text;

        if (contenu.isNotEmpty) {
          await firestore
              .collection('repartition')
              .doc(anneeActuelle.toString())
              .collection(selectedParcours!)
              .doc(selectedSemestre!)
              .collection('TP')
              .add({
            'prof': contenu,
            'module': module,
            'parcours': selectedParcours,
            'semestre': selectedSemestre!,
            'type' : ' TP: ${i+1}',
          });
        }
      }
    }
    // Show a SnackBar indicating successful save
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sauvegarde réussie pour le semestre $selectedSemestre!'),
        duration: Duration(seconds: 10),
        backgroundColor: Colors.green,
      ),
    );
  }

  void showOverloadAlert(String message) {
    // Use your framework's alert/dialog mechanism here, e.g., for Flutter:
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 6),
      ),
    );
  }

  final TextEditingController _messageController = TextEditingController();
  void _sendMessage(String message, String userId) {
    if (message.isNotEmpty) {
      FirebaseFirestore.instance.collection('messages').add({
        'text': message,
        'createdAt': Timestamp.now(),
        'userId': userId,
        'isRead': false,
      });
      _messageController.clear();
    }
  }
  void markMessagesAsRead(String senderId) {
    FirebaseFirestore.instance
        .collection('messages')
        .where('userId', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isRead': true});
      }
    });
  }
  List<StatusData> _chartData = [];
  Future<void> _fetchChartData() async {
    QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('users').get();
    Map<String, int> statusCounts = {
      'valider': 0,
      'en attente': 0,
    };

    for (var doc in querySnapshot.docs) {
      String status = doc['statu'];
      if (statusCounts.containsKey(status)) {
        statusCounts[status] = statusCounts[status]! + 1;
      }
    }

    List<StatusData> pieData = statusCounts.entries.map((entry) {
      return StatusData(entry.key, entry.value);
    }).toList();

    setState(() {
      _chartData = pieData;
    });
  }
  Color blue = Color(0xff0036FE);
  Color red = Color(0xffDD6DF1);
  Color Green = Color(0xff1BD0A3);
  Color orange = Color(0xffFD6803);

  @override
  Widget build(BuildContext context) {
    List<Color> chartColors = [
      blue,
      red,
      Green,
      orange,
    ];
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Disables the back arrow
          title: Text(
            'Effectuer répartion ',
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight:
              FontWeight.bold, // Adds boldness to the title for emphasis
              fontSize: 20, // Increases the font size
            ),
          ),
          // Sets a deep blue-grey as the background color
          elevation: 2,
        ),
        floatingActionButton: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .where('userId',
              isEqualTo: "chef") // Assuming 'idChief' is the chief's user ID
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            int unreadMessages =
            snapshot.hasData ? snapshot.data!.docs.length : 0;

            return badges.Badge(
              badgeContent: Text(
                unreadMessages.toString(),
                style: TextStyle(color: Colors.white),
              ),
              showBadge: unreadMessages > 0,
              position: BadgePosition.topEnd(top: 3, end: 3),
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(20.0), // Adjust the radius as needed
                child: FloatingActionButton(
                  elevation: 0,
                  highlightElevation: 0,
                  onPressed: () {
                    markMessagesAsRead(
                        'chef'); // Mark the messages as read when the dialog is opened
                    showDialog(
                      context: context,
                      builder: (context) => buildChatDialog(context),
                    );
                  },
                  child: Icon(Icons.message),
                  backgroundColor: Colors.blue,
                ),
              ),
            );
          },
        ),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showFormDialog(context)  ,
                          style: ElevatedButton.styleFrom(
                            primary: blue,  // Background color
                            padding: EdgeInsets.symmetric(vertical: 10),  // Adjust padding to fit the height
                            textStyle: TextStyle(fontSize: 18 ,color: Colors.white),  // Bigger text
                            minimumSize: Size(double.infinity, 100),  // Minimum size to be height 50
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)  // Border radius
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.reorder , color: Colors.white,),
                              SizedBox(width: 8),
                              Text('Répartition', style: TextStyle(fontSize: 18 , color: Colors.white)),  // Bigger text
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 30,),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return StatefulBuilder(
                                  builder: (BuildContext context, StateSetter setState) {
                                    return Dialog(
                                      backgroundColor: Colors.white,
                                      child: Container(
                                        color: Colors.white,
                                        width: MediaQuery.of(context).size.width * 0.99,
                                        height: MediaQuery.of(context).size.height * 0.95,
                                        child: Card(
                                          color: Colors.white,
                                          margin: EdgeInsets.all(20),
                                          child: StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('users')
                                                .orderBy('timestamp', descending: true)
                                                .snapshots(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasError)
                                                return Text('Error: ${snapshot.error}');
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(child: CircularProgressIndicator());
                                              }
                                              List<Map<String, dynamic>> users =
                                              snapshot.data!.docs.map((DocumentSnapshot document) {
                                                return document.data() as Map<String, dynamic>;
                                              }).toList();

                                              return Row(
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: buildUsersTable(users, context, onSelectUser: (String userId) {
                                                      setState(() {
                                                        selectedUserId2 = userId;
                                                      });
                                                    }),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: selectedUserId2 == null
                                                        ? Center(child: Text("Sélectionnez un utilisateur pour voir les détails"))
                                                        : userDetails(selectedUserId2!),
                                                  ),
                                                ],
                                              );
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
                          style: ElevatedButton.styleFrom(
                            primary: red,  // Bakground color
                            padding: EdgeInsets.symmetric(vertical: 10),  // Adjust padding to fit the height
                            textStyle: TextStyle(fontSize: 18),  // Bigger text
                            minimumSize: Size(double.infinity, 100),  // Minimum size to be height 50
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)  // Border radius
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.list , color: Colors.white,),
                              SizedBox(width: 8),
                              Text('Liste des voeux', style: TextStyle(fontSize: 18 , color: Colors.white)),  // Bigger text
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 30,),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showDialogWithRepartition(context);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.pink,  // Bakground color
                            padding: EdgeInsets.symmetric(vertical: 10),  // Adjust padding to fit the height
                            textStyle: TextStyle(fontSize: 18),  // Bigger text
                            minimumSize: Size(double.infinity, 100),  // Minimum size to be height 50
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)  // Border radius
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.list , color: Colors.white,),
                              SizedBox(width: 8),
                              Text('Historique', style: TextStyle(fontSize: 18 , color: Colors.white)),  // Bigger text
                            ],
                          ),
                        ),
                      ),
                    ],
                  )

              ),
              SizedBox(height: 60,),
              Expanded(
                child: SfCircularChart(
                  title: ChartTitle(text: 'Visualisation des listes des voeux', textStyle: TextStyle(fontSize: 18)),  // Bigger title
                  legend: Legend(
                    isVisible: true,
                    overflowMode: LegendItemOverflowMode.wrap,
                    textStyle: TextStyle(fontSize: 14),  // Bigger legend text
                  ),
                  series: <CircularSeries>[
                    DoughnutSeries<StatusData, String>(
                      dataSource: _chartData,
                      xValueMapper: (StatusData data, _) => data.status,
                      yValueMapper: (StatusData data, _) => data.count,
                      dataLabelMapper: (StatusData data, _) => '${data.status}: ${data.count}',
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        // Bigger data labels
                      ),
                      pointColorMapper: (StatusData data, _) {
                        switch (data.status) {
                          case 'valider':
                            return Colors.green;
                          case 'en attente':
                            return Colors.orange;
                          default:
                            return Colors.grey;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )

    );
  }


  Widget buildChatDialog(BuildContext context) {
    double width = MediaQuery.of(context).size.width *
        0.4; // Wider dialog for better readability
    double height =
        MediaQuery.of(context).size.height * 0.99; // Adjust height to match

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(20)), // Rounded corners for the dialog
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                  20), // Rounded corners for the container
            ),
            width: width,
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header area
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue, // Header background color
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    "Discussion",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Message list
                Expanded(
                  child: buildMessageList(context, width),
                ),
                // Input field
                buildInputField(context, _messageController, width),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget buildInputField(BuildContext context, TextEditingController messageController, double width) {
    // Implement your input field for messages here
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          IconButton(
            splashColor:
            Colors.transparent, // Remove splash effect on button press
            highlightColor: Colors.transparent,
            icon: Icon(Icons.send, color: Colors.blue),
            onPressed: () => _sendMessage(messageController.text, idnavigateur),
          ),
        ],
      ),
    );
  }
  Widget buildMessageList(BuildContext context, double width) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!chatSnapshot.hasData) {
          return Center(child: Text("No messages found"));
        }
        final chatDocs = chatSnapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          itemCount: chatDocs.length,
          itemBuilder: (ctx, index) {
            var message = chatDocs[index];
            var isMe = message['userId'] ==
                idnavigateur; // Compare message userId with current user's ID
            var messageTime = message['createdAt'] as Timestamp;
            var formattedTime =
            DateFormat('HH:mm').format(messageTime.toDate());

            return Row(
              mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircleAvatar(
                      // You can display the sender's initials or an icon
                      child: Text(message['userId']
                          .substring(0, 1)
                          .toUpperCase()), // Display first letter of userId
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width * 0.7, // Maximum width for a message bubble
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.grey[100]
                          : Colors.blue[
                      300], // Different colors for sender/receiver
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['text'], // The message text
                          style: TextStyle(color: Colors.black),
                          softWrap: true,
                        ),
                        SizedBox(height: 5),
                        Text(
                          formattedTime, // The formatted timestamp
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Widget buildUsersTable(List<Map<String, dynamic>> users, BuildContext context, {required Function(String) onSelectUser}) {
    if (users.isEmpty) {
      return Center(child: Text("Pas d'enseignants trouvé"));
    }

    // Assuming that all documents have the same keys
    List<String> headers = users.first.keys
        .where((key) =>
    key != "timestamp" &&
        key != "uid" &&
        key != "valide" &&
        key != "email")
        .toList();
    headers.sort((a, b) => a.compareTo(b)); // Sort headers alphabetically

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
              children: headers
                  .map((header) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    header,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ))
                  .toList(),
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
                onTap: () => onSelectUser(
                    user['uid']), // Trigger the onSelectUser callback
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
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
          child: Center(
              child: Text("En attente", style: TextStyle(color: Colors.white))),
        );
      case "valider":
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
              child: Text("Validé", style: TextStyle(color: Colors.white))),
        );
      case "refuser":
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
              child: Text("Refusé", style: TextStyle(color: Colors.white))),
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
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Text('Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red));
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
                    bottom: BorderSide(
                        color: Colors.blue, width: 1.0), // Only bottom border
                  ),
                ),
                child: ListTile(
                  title: Text(
                    documents[index]['displayName'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12), // Smaller font size
                  ),
                  subtitle: Text(
                    "Grade: ${documents[index]['grade']}",
                    style: TextStyle(
                        fontSize: 10), // Smaller font size for subtitle
                  ),
                  trailing:
                  Icon(Icons.arrow_forward_ios, size: 14), // Smaller icon
                  onTap: () => selectUser(documents[index]['uid']),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0), // Reduced padding
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
        Center(
            child: Text('Fiche de voeux',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22))),
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
        if (snapshot.hasError)
          return Text('Erreur de chargement',
              style: TextStyle(color: Colors.red, fontSize: 14));
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
              Text('$semester',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 4),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1, // Single column for a table-like layout
                    childAspectRatio: MediaQuery.of(context).size.width /
                        95, // Adjust childAspectRatio based on screen width to fix height
                  ),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> module = modules[index];
                    return Container(
                      height: 270, // Fixed height for each row
                      decoration: BoxDecoration(
                        border: Border(
                          bottom:
                          BorderSide(color: Colors.grey[300]!, width: 1),
                          top: BorderSide(color: Colors.grey[300]!, width: 1),
                          left: BorderSide(color: Colors.grey[300]!, width: 1),
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 9.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex:
                              3, // Allocates 3 parts of space for the module name, more space due to potential length
                              child: Text("Module: ${module['moduleName']}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            Expanded(
                              child: Text("Parcours: ${module['parcours']}",
                                  style: TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: Text(
                                  "Cours: ${module['course'] ? 'Yes' : 'No'}",
                                  style: TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: Text("TD: ${module['td'] ? 'Yes' : 'No'}",
                                  style: TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: Text("TP: ${module['tp'] ? 'Yes' : 'No'}",
                                  style: TextStyle(fontSize: 13)),
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
  Widget deuxiemeTabContent() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1, // Adjusted for better spacing
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
                    child: Padding(
                      // Padding added here
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
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical:
                              0), // No vertical padding inside the TextField
                          border: OutlineInputBorder(
                            // Changed to OutlineInputBorder for clearer visibility
                            borderRadius: BorderRadius.circular(
                                8.0), // More pronounced rounded corners
                            borderSide: BorderSide(
                                color: Colors.grey,
                                width: 1.0), // Visible grey border
                          ),
                          focusedBorder: OutlineInputBorder(
                            // Border style when the TextField is focused
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: Colors.grey,
                                width: 2.0), // Thicker blue border
                          ),
                          enabledBorder: OutlineInputBorder(
                            // Border style when the TextField is enabled but not focused
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide:
                            BorderSide(color: Colors.grey, width: 1.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: userSearchResults(),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 100,
        ),
        Expanded(
          flex: 2, // Adjusted for better spacing
          child: userDetails(selectedUserId),
        ),
      ],
    );
  }
  void _initializeControllers(int nombreGroupes) {
    emptyRowControllers = List.generate(courses.length, (index) => TextEditingController());
    groupControllersTD = List.generate(nombreGroupes, (groupIndex) {
      return List.generate(courses.length, (courseIndex) => TextEditingController());

    });
    groupControllersTP = List.generate(nombreGroupes, (groupIndex) {
      return List.generate(courses.length, (courseIndex) => TextEditingController());

    });
  }
  void _showFormDialog(BuildContext scaffoldContext) { // Notez l'ajout du contexte du Scaffold ici
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setState) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.9,
                child: premierTabContent(setState: setState),
              );
            },
          ),
        );
      },
    );
  }
  Future<void> attemptSaveData(BuildContext scaffoldContext) async { // Utilisez ce contexte pour la SnackBar
    var profCount = await gatherProfData();
    bool overloadFound = false;
    List<String> overloadedProfs = [];

    profCount.forEach((prof, count) {
      if (count > 8) {
        overloadedProfs.add(prof);
        overloadFound = true;
      }
    });

    if (overloadFound) {
      String profNames = overloadedProfs.join(", ");
      setState(() {
        errorMessage = "Surcharge détectée pour les professeurs suivants : $profNames. Sauvegarde impossible.";
      });
    } else {
      await _saveDataToFirebase();
      // Remplacez cette fonction par votre méthode de sauvegarde.
      setState(() {
        errorMessage = 'Sauvgarde réussite pour ce semestre '; // Clear the error message on successful save
      });
    }
    showErrorDialog(errorMessage!);
  }
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New message"),
          content: Text(
            message,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
  Widget premierTabContent({required void Function(void Function()) setState}) {


    // Helper function to create a course card
    Widget courseCard(String title, bool isSelected) {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedParcours = title;
          });
        },
        child: Card(
          color: isSelected ? Colors.green : Colors.white,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
            ),
          ),
        ),
      );
    }

    // Helper function to create a semester card
    Widget semesterCard(String title, bool isSelected) {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedSemestre = title;
          });
        },
        child: Card(
          color: isSelected ? Colors.green : Colors.white,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
            ),
          ),
        ),
      );
    }

    // Title widget
    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800]),
        ),
      );
    }

    double commonHeight = 50.0; // Common height for TextField and Buttons

    // Layout for user interactions
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              sectionTitle("Effectuer Répartition"),
              SizedBox(width: 200),

              Expanded(
                child: FractionallySizedBox(
                  widthFactor: 0.3,
                  child: Container(
                    height: commonHeight,
                    child: ElevatedButton(
                      onPressed: () async {
                        _showRepartitionDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Visualiser  la répartion Globale',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(thickness: 2, color: Colors.blue.shade100),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Choisir un Parcours : ' , style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                    ),),
                    courseCard("L1", selectedParcours == "L1"),
                    courseCard("L2", selectedParcours == "L2"),
                    courseCard("L3", selectedParcours == "L3"),
                  ],
                ),
                SizedBox(width: 20),
                Text('Choisir un Semestre: ' , style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold
                ),),
                Expanded(child: semesterCard("Semestre 1", selectedSemestre == "Semestre 1")),
                Expanded(child: semesterCard("Semestre 2", selectedSemestre == "Semestre 2")),
                SizedBox(width: 10),
                Expanded(
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: Container(
                      height: commonHeight,
                      child: ElevatedButton(
                        onPressed: () async {
                          _saveDataToFirebase();
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sauvgarder pour ce semestre',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: commonHeight,
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
              Expanded(
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    height: commonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        _valider(setState, selectedParcours!, selectedSemestre!, groupeController);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Générer Table',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),

            ],
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
                        child: customTable!,
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
                        sectionTitle("Recommendation"),
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
                                          child: Text(user['displayName'],
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1)),
                                      Expanded(
                                          child: Text(abbreviate(user['grade']),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1))
                                    ],
                                  ),
                                  subtitle: Text(
                                    "Module: ${user['moduleName']}",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }



  Map<String, dynamic> repartitionData = {};
  String selectedDocId = '';
  Future<Map<String, dynamic>> fetchData(String documentId) async {
    DocumentReference anneeRef = FirebaseFirestore.instance.collection('repartition').doc(documentId);
    Map<String, dynamic> repartitionData = {};

    List<String> parcoursList = ['L1', 'L2', 'L3'];
    List<String> semestreList = ['Semestre 1', 'Semestre 2'];

    for (String parcours in parcoursList) {
      repartitionData[parcours] = {};
      for (String semestre in semestreList) {
        var modules = _getModulesForParcoursSemestre(parcours, semestre);
        repartitionData[parcours][semestre] = {};

        for (String module in modules) {
          repartitionData[parcours][semestre][module] = {'Cours': 'N/A', 'TD': 'N/A', 'TP': 'N/A'};
          for (String type in ['Cours', 'TD', 'TP']) {
            try {
              var collectionRef = anneeRef.collection(parcours).doc(semestre).collection(type);
              var snapshot = await collectionRef.where('module', isEqualTo: module).get();
              var profs = snapshot.docs.isNotEmpty
                  ? snapshot.docs.map((doc) => doc.data()['prof'] as String? ?? 'N/A').join(', ')
                  : 'N/A';
              repartitionData[parcours][semestre][module][type] = profs;
            } catch (e) {
              print("Error accessing Firestore for $type: $e");
            }
          }
        }
      }
    }

    return repartitionData;
  }
  void showDialogWithRepartition(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.99,
            height: MediaQuery.of(context).size.height * 0.95,
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Repartition Management',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Divider(thickness: 2.0),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection('repartition').where('valide' , isEqualTo: 'true').get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(child: Text('No documents found'));
                            }

                            var docs = snapshot.data!.docs;

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                var doc = docs[index];
                                return ListTile(
                                  title: Text('Répartition ${doc.id}'),
                                  onTap: () {
                                    // Ensure setState is called in a StatefulWidget
                                    (context as Element).markNeedsBuild();
                                    selectedDocId = doc.id;
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      VerticalDivider(thickness: 2.0),
                      Expanded(
                        flex: 5,
                        child: selectedDocId.isEmpty
                            ? Center(child: Text('Select a document to see details'))
                            : FutureBuilder<Map<String, dynamic>>(
                          future: fetchData(selectedDocId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData) {
                              return Center(child: Text('No data available'));
                            }

                            var repartitionData = snapshot.data!;
                            return buildRepartitionTable(context, repartitionData);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget buildRepartitionTable(BuildContext context, Map<String, dynamic> repartitionData) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: repartitionData.keys.map<Widget>((parcours) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(parcours, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: repartitionData[parcours].keys.map<Widget>((semestre) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(semestre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          child: Table(
                            border: TableBorder.all(color: Colors.grey, width: 1),
                            defaultColumnWidth: FixedColumnWidth(100.0),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey[300]),
                                children: [
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Modules', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  ...repartitionData[parcours][semestre].keys.map((module) {
                                    return TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(module, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                              ...['Cours', 'TD', 'TP'].map((type) {
                                return TableRow(
                                  children: [
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(type, style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    ...repartitionData[parcours][semestre].keys.map((module) {
                                      String cellValue = repartitionData[parcours][semestre][module][type];
                                      return TableCell(
                                        child: Container(
                                          color: cellValue == 'N/A' ? Colors.orange[200] : null,
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(cellValue),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              Divider(thickness: 2.0, color: Colors.black),
            ],
          );
        }).toList(),
      ),
    );
  }
  Widget _buildCustomTable(String selectedParcours, String selectedSemestre, int numberOfGroups) {
    _valider((fn) { }, selectedParcours, selectedSemestre, groupeController);
    List<Widget> rows = [
      Divider(),
      _buildCoursesHeader(),
      Divider(thickness: 2, color: Colors.black),
      _buildEmptyRowWithLabel(),
      Divider(thickness: 2, color: Colors.black),
    ];

    // Adding all TDs
    for (int i = 1; i <= numberOfGroups; i++) {
      rows.add(_buildGroupRowTD('TD', i));
    }

    // Adding a separator between TDs and TPs
    rows.add(Divider(thickness: 2, color: Colors.black));

    // Adding all TPs
    for (int i = 1; i <= numberOfGroups; i++) {
      rows.add(_buildGroupRowTP('TP', i));
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
              child: Text('Cours',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            ...List.generate(courses.length, (index) =>
                Expanded(
                  child: TextField(
                    controller: emptyRowControllers[index],
                    style: TextStyle(fontSize: 10),
                    decoration: InputDecoration(
                      hintText: '',
                      hintStyle: TextStyle(fontSize: 10),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                      constraints: BoxConstraints(
                        maxHeight:
                        30, // Hauteur maximale du TextField réduite
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
              child: Text('MODULES',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...courses
                .map((course) => Expanded(
              child: Text(course,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ))
                .toList(),
          ],
        ),
      ),
    );
  }
  Widget _buildGroupRowTD(String type, int number) {
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
              child: Text('$type$number',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            ...List.generate(courses.length, (index) => Expanded(
              child: TextField(
                controller: groupControllersTD[number - 1][index],
                style: TextStyle(fontSize: 10),
                decoration: InputDecoration(
                  hintText: '',
                  hintStyle: TextStyle(fontSize: 10),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  constraints: BoxConstraints(
                    maxHeight:
                    30, // Hauteur maximale du TextField réduite
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
  Widget _buildGroupRowTP(String type, int number) {
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
              child: Text('$type$number',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            ...List.generate(courses.length, (index) => Expanded(
              child: TextField(
                controller: groupControllersTP[number - 1][index],
                style: TextStyle(fontSize: 10),
                decoration: InputDecoration(
                  hintText: '',
                  hintStyle: TextStyle(fontSize: 10),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  constraints: BoxConstraints(
                    maxHeight:
                    30, // Hauteur maximale du TextField réduite
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
  void _updateCourses(String selectedParcours, String selectedSemestre) {
    // Define course lists for each year and semester
    if (selectedParcours == 'L1') {
      if (selectedSemestre == 'Semestre 1') {
        courses = [
          'Analyse1',
          'Algèbre 1',
          'ASD',
          'Structure Machine 1',
          'Terminologie Scientifique',
          'Langue Étrangère',
          'Option (Physique / Mécanique du Point)'
        ];
      } else {
        courses = [
          'Analyse2',
          'Algèbre 2',
          'ASD 2',
          'Structure Machine 2',
          'Proba/ statistique',
          'Technologies de l\'information et communication',
          'Option (Physique / Mécanique du Point)',
          'Outills de programmation pour les mathématiques'
        ];
      }
    } else if (selectedParcours == 'L2') {
      if (selectedSemestre == 'Semestre 1') {
        courses = [
          'Architecture ordinateur',
          'ASD3',
          'THG',
          'Système d\'information',
          'Méthodes numériques',
          'Logique mathématiques',
          'Langue étrangère 2'
        ];
      } else {
        courses = [
          'THL',
          'Système d\'exploitation 1',
          'Base de données',
          'Réseaux',
          'Programmation orientée objet',
          'Développement applications web',
          'Langue étrangère 3'
        ];
      }
    } else if (selectedParcours == 'L3') {
      if (selectedSemestre == 'Semestre 1') {
        courses = [
          'Système d\'exploitation 2',
          'Compilation',
          'IHM',
          'Génie logiciel',
          'Programmation linéaire',
          'Probabilités et statistiques',
          'Économie numérique'
        ];
      } else {
        courses = [
          'Applications mobiles',
          'Sécurité informatique',
          'Intelligence artificielle',
          'Données semi-structurées',
          'Rédaction scientifique',
          'Projet',
          'Création et développement web'
        ];
      }
    }
  }
}

class StatusData {
  final String status;
  final int count;

  StatusData(this.status, this.count);
}
