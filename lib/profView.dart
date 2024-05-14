import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:untitled4/main.dart';
import 'package:intl/intl.dart';

class MainUserweb extends StatefulWidget {
  String iduserweb;
  MainUserweb({Key? key, required this.iduserweb}) : super(key: key);

  @override
  _MainUserweb createState() => _MainUserweb(iduserweb);
}

class _MainUserweb extends State<MainUserweb> {
  String iduserweb;
  _MainUserweb(this.iduserweb);

  String profName = "";
  String? valeur;
  String? datefin;

  void initState() {
    super.initState();
    fetchProfName();
  }

  Future<dynamic> fetchProfName() async {
    DocumentSnapshot profDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(iduserweb)
        .get();

    if (profDoc.exists) {
      // Cast the data to Map<String, dynamic> to avoid type errors.
      Map<String, dynamic> data = profDoc.data() as Map<String, dynamic>;
      setState(() {
        profName = data['displayName'] ?? 'Name not found';
        valeur = data['valide'] ?? 'non valide';
      });
    } else {
      setState(() {
        profName = 'Professor not found';
      });
    }
    FirebaseFirestore db = FirebaseFirestore.instance;
    try {
      QuerySnapshot querySnapshot = await db
          .collection('dates')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var document = querySnapshot.docs.first;
        DateTime date = document['endDate'].toDate();
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        setState(() {
          datefin = formattedDate;
        }); // Formate la date en String selon le format désiré
      } else {
        setState(() {
          datefin = "Aucune date disponible";
        }); // Gestion quand aucun document n'est trouvé
      }
    } catch (e) {
      setState(() {
        datefin = "Erreur lors de la récupération";
      });
    }
  }

  List<ModuleState> moduleStates = List.generate(
      3,
      (index) => ModuleState(
            moduleController: TextEditingController(),
            parcoursController: TextEditingController(),
          ));
  List<ModuleState> moduleStates2 = List.generate(
      3,
      (index) => ModuleState(
            moduleController: TextEditingController(),
            parcoursController: TextEditingController(),
          ));

  void _showGradeDialog(BuildContext context) {
    String? selectedGrade = "Chef de département"; // Default initial value

    List<String> grades = [
      "Chef de département",
      "Responsable de domaine",
      "Responsable de filière",
      "Professeur",
      "Maître de conférences A",
      "Maître de conférences B",
      "Maître assistant A",
      "Maître assistant B"
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            "Veuillez préciser votre grade",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              fillColor:
                  Colors.grey[800], // Slightly lighter grey than the background
              filled: true,
              prefixIcon: const Icon(Icons.school, color: Colors.white),
            ),
            dropdownColor: Colors.grey[800], // Dropdown background
            value: selectedGrade,
            style: const TextStyle(color: Colors.white), // Text style for items
            onChanged: (String? newValue) {
              if (newValue != null) {
                selectedGrade = newValue;
              }
            },
            items: grades.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors
                    .green, // A vibrant color to contrast the dark background
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text("Enregistrer"),
              onPressed: () {
                if (selectedGrade != null) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(iduserweb)
                      .update({'grade': selectedGrade}).then((_) {
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text("Erreur lors de l'enregistrement: $error")));
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> saveData(String userId) async {
    List<Map<String, dynamic>> modules = moduleStates.map((ModuleState state) {
      return {
        "moduleName": state.moduleController.text,
        "parcours": state.parcoursController.text,
        "course": state.course,
        "td": state.td,
        "tp": state.tp,
      };
    }).toList();
    var db = FirebaseFirestore.instance;
    var userDocRef = db.collection("users").doc(userId);
    var ficheDeVoeuxRef =
        userDocRef.collection("fiche de voeux").doc("semetre1");

    await ficheDeVoeuxRef.set({
      "department": "Informatique",
      "modules": modules,
      "timestamp": FieldValue.serverTimestamp(),
    });
    var userDocRef2 = db.collection("users").doc(userId);

    await userDocRef2.update({
      "valide": "true",
    });
  }

  Future<void> saveData2(String userId) async {
    List<Map<String, dynamic>> modules =
        moduleStates2.map((ModuleState state2) {
      return {
        "moduleName": state2.moduleController.text,
        "parcours": state2.parcoursController.text,
        "course": state2.course,
        "td": state2.td,
        "tp": state2.tp,
      };
    }).toList();
    var db = FirebaseFirestore.instance;
    var userDocRef = db.collection("users").doc(userId);
    var ficheDeVoeuxRef =
        userDocRef.collection("fiche de voeux").doc("semetre2");

    await ficheDeVoeuxRef.set({
      "department": "Informatique",
      "modules": modules,
      "timestamp": FieldValue.serverTimestamp(),
    });
    var userDocRef2 = db.collection("users").doc(userId);

    await userDocRef2.update({
      "valide": "true",
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtention de l'année actuelle
    int currentYear = DateTime.now().year;
    // Calcul de l'année prochaine
    int nextYear = currentYear + 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              profName.toLowerCase(),
              style: TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(iduserweb)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Text(''); // Show loading text if no data

                var userDoc = snapshot.data;
                var grade = userDoc?['grade'] ??
                    "rien"; // Default to "rien" if grade is not set

                return Visibility(
                  visible:
                      grade == "rien", // Visibility based on grade being "rien"
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.notification_important),
                      color: Colors.red,
                      onPressed: () {
                        _showGradeDialog(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(6),
        child: Center(
          child: Column(
            children: <Widget>[
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(iduserweb)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('');
                  }

                  var userDoc = snapshot.data;
                  var valeur = userDoc?['valide'] ??
                      'null'; // Defaulting to 'null' if the key does not exist

                  if (valeur == 'null') {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Add some padding around the text
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 20),
                            Text(
                              'Boîte de réception',
                              style: TextStyle(
                                  fontSize:
                                      22, // Slightly larger text for the title
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            const Divider(),
                            SizedBox(
                                height:
                                    10), // Space between the title and subtitle
                            Text(
                              "Aucun message pour l'instant !",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (valeur == 'false') {
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Fiche de vœux $currentYear /$nextYear',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '(Veuiller soumettre avant $datefin)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Expanded(
                            flex: 1,
                            child: ListView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                  color: Colors.blueGrey,
                                                  width: 2),
                                              left: BorderSide(
                                                  color: Colors.blueGrey,
                                                  width: 2),
                                              right: BorderSide(
                                                  color: Colors.blueGrey,
                                                  width: 2),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: RichText(
                                              textAlign: TextAlign.left,
                                              text: TextSpan(
                                                style: const TextStyle(
                                                    color: Colors
                                                        .black), // Style par défaut pour tout le texte
                                                children: [
                                                  const TextSpan(
                                                    text: 'MATIÈRES ',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: ' À POUVOIR',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: ' SOUHAITÉES POUR LE',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: '  SEMESTRE 1 ',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '$currentYear-$nextYear PAR ORDRE DE PRIORITÉ  \n',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text:
                                                        '(Préciser le parcours L1, L2, L3, M1, M2)',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                                color: Colors.blueGrey,
                                                width: 2),
                                            right: BorderSide(
                                                color: Colors.blueGrey,
                                                width: 2),
                                          ),
                                        ),
                                        child: const Text(
                                          'Département \n',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Card(
                                  margin: const EdgeInsets.fromLTRB(
                                      8.0, 0, 8.0, 8.0),
                                  color: Colors.white,
                                  elevation: 0.0,
                                  child: Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(3.1),
                                      1: FlexColumnWidth(1.5),
                                      2: FlexColumnWidth(0.5),
                                      3: FlexColumnWidth(0.5),
                                      4: FlexColumnWidth(0.5),
                                      5: FlexColumnWidth(2),
                                    },
                                    border: TableBorder.all(
                                        color: Colors.blueGrey, width: 2),
                                    children: [
                                      const TableRow(children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Modules',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Parcours',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Cours',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('TD',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('TP',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ]),
                                      ...List.generate(moduleStates.length,
                                          (index) {
                                        final state = moduleStates[index];
                                        return TableRow(children: [
                                          SizedBox(
                                            height: 30,
                                            child: Center(
                                              child: TextField(
                                                controller:
                                                    state.moduleController,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets.all(10),
                                                  hintText: '${index + 1}:',
                                                  border:
                                                      const OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: TextField(
                                              controller:
                                                  state.parcoursController,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.all(10),
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: Center(
                                              child: Checkbox(
                                                value: state.course,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    state.course = value!;
                                                  });
                                                },
                                                activeColor: Colors.green,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: Center(
                                              child: Checkbox(
                                                value: state.td,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    state.td = value!;
                                                  });
                                                },
                                                activeColor: Colors.green,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: Center(
                                              child: Checkbox(
                                                value: state.tp,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    state.tp = value!;
                                                  });
                                                },
                                                activeColor: Colors.green,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 30,
                                            child: TextField(
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.all(10),
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ]);
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            flex: 1,
                            child: ListView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                  color: Colors.blueGrey,
                                                  width: 2),
                                              left: BorderSide(
                                                  color: Colors.blueGrey,
                                                  width: 2),
                                              right: BorderSide(
                                                  color: Colors.blueGrey,
                                                  width: 2),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: RichText(
                                              textAlign: TextAlign.left,
                                              text: TextSpan(
                                                style: const TextStyle(
                                                    color: Colors
                                                        .black), // Style par défaut pour tout le texte
                                                children: [
                                                  const TextSpan(
                                                    text: 'MATIÈRES ',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: ' À POUVOIR',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: ' SOUHAITÉES POUR LE',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: '  SEMESTRE 2 ',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '$currentYear-$nextYear PAR ORDRE DE PRIORITÉ  \n',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text:
                                                        '(Préciser le parcours L1, L2, L3, M1, M2)',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                                color: Colors.blueGrey,
                                                width: 2),
                                            right: BorderSide(
                                                color: Colors.blueGrey,
                                                width: 2),
                                          ),
                                        ),
                                        child: const Text(
                                          'Département \n',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Card(
                                  margin: const EdgeInsets.fromLTRB(
                                      8.0, 0, 8.0, 8.0),
                                  color: Colors.white,
                                  elevation: 0.0,
                                  child: Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(3.1),
                                      1: FlexColumnWidth(1.5),
                                      2: FlexColumnWidth(0.5),
                                      3: FlexColumnWidth(0.5),
                                      4: FlexColumnWidth(0.5),
                                      5: FlexColumnWidth(2),
                                    },
                                    border: TableBorder.all(
                                        color: Colors.blueGrey, width: 2),
                                    children: [
                                      const TableRow(children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Modules',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Parcours',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Cours',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('TD',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('TP',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ]),
                                      ...List.generate(moduleStates2.length,
                                          (index) {
                                        final state2 = moduleStates2[index];
                                        return TableRow(children: [
                                          SizedBox(
                                            height: 30,
                                            child: TextField(
                                              controller:
                                                  state2.moduleController,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.all(10),
                                                hintText: '${index + 1}:',
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: TextField(
                                              controller:
                                                  state2.parcoursController,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.all(10),
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: Center(
                                              child: Checkbox(
                                                value: state2.course,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    state2.course = value!;
                                                  });
                                                },
                                                activeColor: Colors.green,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: Center(
                                              child: Checkbox(
                                                value: state2.td,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    state2.td = value!;
                                                  });
                                                },
                                                activeColor: Colors.green,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: Center(
                                              child: Checkbox(
                                                value: state2.tp,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    state2.tp = value!;
                                                  });
                                                },
                                                activeColor: Colors.green,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 30,
                                            child: TextField(
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.all(10),
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ]);
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: SizedBox(
                                height: 40,
                                width: 100,
                                child: MaterialButton(
                                  onPressed: () async {
                                    FirebaseFirestore db =
                                        FirebaseFirestore.instance;
                                    var docRef =
                                        db.collection('users').doc(iduserweb);
                                    await docRef.update({
                                      'valide':
                                          'true' // Met à jour le champ `valide` à true
                                    }).catchError((error) {});
                                    await saveData(iduserweb);
                                    await saveData2(iduserweb);
                                  },
                                  color: Colors.green, // Couleur du bouton
                                  textColor: Colors.white, // Couleur du texte
                                  child: const Row(
                                    mainAxisSize: MainAxisSize
                                        .min, // Pour s'assurer que le contenu interne reste compact
                                    children: <Widget>[
                                      Icon(Icons.check), // Icône
                                      SizedBox(
                                          width:
                                              8), // Espace entre l'icône et le texte
                                      Text('Valider'), // Texte
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          5.0) // Arrondir les coins du bouton
                                      ),
                                  elevation:
                                      2.0, // Ajoute une ombre sous le bouton
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (valeur == 'true') {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Add some padding around the text
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 20),
                            Text(
                              'Boîte de réception',
                              style: TextStyle(
                                  fontSize:
                                      22, // Slightly larger text for the title
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            const Divider(),
                            SizedBox(
                                height:
                                    10), // Space between the title and subtitle
                            Text(
                              "Merci, la répartition vous sera transmise",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Text("Data is inconsistent.");
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ModuleState {
  TextEditingController moduleController;
  TextEditingController parcoursController;
  bool course;
  bool td;
  bool tp;
  String additionalInfo;

  ModuleState({
    required this.moduleController,
    required this.parcoursController,
    this.course = false,
    this.td = false,
    this.tp = false,
    this.additionalInfo = "",
  });

  Map<String, dynamic> toJson() => {
        'moduleName': moduleController.text,
        'parcours': parcoursController.text,
        'course': course,
        'td': td,
        'tp': tp,
        'additionalInfo': additionalInfo,
      };
}
