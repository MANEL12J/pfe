import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:untitled4/main.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart';
import 'package:badges/badges.dart' as badges; // Alias for the external badges package
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
  String professorName = '';
  String professorFirstName = '';
  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>> repartitionData = {};
  bool isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  void _openChatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[300], // Setting background color of the dialog
          title: Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blueGrey[200], // Background color for the title
            child: Text('Chat with Adjoint', style: TextStyle(color: Colors.white)), // Optional: change text color here
          ),
          content: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('messagesadjointprof')
                .doc('chats')
                .collection('adjoint${iduserweb}')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 0.4,
                child: ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot document = snapshot.data!.docs[index];
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    bool isSender = data['senderId'] == iduserweb;
                    DateTime timestamp = (data['timestamp'] as Timestamp).toDate();

                    return Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isSender) // Only show avatar for the receiver
                            CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              child: Text('A', style: TextStyle(color: Colors.white)),
                            ),
                          SizedBox(width: 8),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 2),
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: isSender ? Colors.grey[300] : Colors.blue,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['content'],
                                  style: TextStyle(color: isSender ? Colors.black : Colors.black),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Send a message',
                  border: OutlineInputBorder(), // Adding border to the TextField
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? valide;
  Future<void> _loadValidite() async {
    String currentYear = DateTime.now().year.toString();  // Convertit l'année courante en String

    DocumentSnapshot documentSnapshot = await _firestore
        .collection('repartition')
        .doc(currentYear)  // Utilisez l'année courante comme ID de document
        .get();

    if (documentSnapshot.exists) {
      setState(() {
        valide = documentSnapshot.get('valide') as String?;  // Récupère le champ valide comme String
      });
    } else {
      print('Document does not exist.');
    }
  }


  void _markMessagesAsRead() {
    if (iduserweb != null) {

      FirebaseFirestore.instance
          .collection('messagesadjointprof')
          .doc('chats')
          .collection('adjoint${iduserweb}')
          .where('senderId', isEqualTo: 'adjoint')
          .where('receiverId', isEqualTo: '${iduserweb}')
          .where('read', isEqualTo: false)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'read': true});
        }
      });
    }
  }
  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('messagesadjointprof')
          .doc('chats')
          .collection('adjoint${iduserweb}')
          .add({
        'senderId': iduserweb,
        'receiverId': 'adjoint', // You need to define the receiver ID correctly
        'timestamp': Timestamp.now(),
        'content': _messageController.text,
        'read': false,
      });

      _messageController.clear();
      _markMessagesAsRead();

    }
  }
  Future<void> fetchData() async {
    try {
      await login(widget.iduserweb);
      await fetchRepartitionData();
    } catch (e) {
      // Handle errors or show an error message
    } finally {
      setState(() => isLoading = false);
    }
  }
  Future<void> login(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      professorName = userDoc['nom'];
      professorFirstName = userDoc['prenom']; // Assuming you have a 'prenom' field
    }
  }
  Future<void> fetchRepartitionData() async {
    final firestore = FirebaseFirestore.instance;
    final int currentYear = DateTime.now().year;

    for (String parcours in ['L1', 'L2', 'L3']) {
      for (String semestre in ['Semestre 1', 'Semestre 2']) {
        Map<String, List<Map<String, dynamic>>> semesterData = {};

        for (String type in ['Cours', 'TD', 'TP']) {
          QuerySnapshot querySnapshot = await firestore
              .collection('repartition')
              .doc(currentYear.toString())
              .collection(parcours)
              .doc(semestre)
              .collection(type)
              .where('prof', isGreaterThanOrEqualTo: professorFirstName, isLessThanOrEqualTo: professorName)
              .get();

          semesterData[type] = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        }

        if (repartitionData[parcours] == null) repartitionData[parcours] = {};
        repartitionData[parcours]![semestre] = semesterData;
      }
    }
  }
  void initState() {
    super.initState();
    fetchProfName();
    fetchData();
    _loadValidite();
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

  List<ModuleState> moduleStates = List.generate(3,
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
      "statu" : "valider"
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
       "statu" : "valider"
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
      floatingActionButton:  StreamBuilder(
        stream: FirebaseFirestore.instance
          .collection('messagesadjointprof')
          .doc('chats')
          .collection('adjoint${iduserweb}')
            .where('senderId', isEqualTo: 'adjoint')
            .where('receiverId', isEqualTo: '${iduserweb}')
            .where('read', isEqualTo: false)
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
            position: BadgePosition.topEnd(top: 0, end: 3),
            child: FloatingActionButton(

              onPressed: () {
                _openChatDialog();
              },
              child: Icon(Icons.message),
              backgroundColor: Colors.blue,
            ),

          );
        },
      ),
      body: Container(
        margin: const EdgeInsets.all(6),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
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
                  String valeur = userDoc!['valide'] ; // Defaulting to 'null' if the key does not exist
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
                  }
                  else if (valeur == 'false') {
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
                                                  border: state.moduleController.text.isEmpty
                                                      ? OutlineInputBorder(borderSide: BorderSide(color: Colors.red))
                                                      : OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: TextField(
                                              controller:
                                                  state.parcoursController,
                                              decoration:  InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.all(10),
                                                border: state.parcoursController.text.isEmpty
                                                    ? OutlineInputBorder(borderSide: BorderSide(color: Colors.red))
                                                    : OutlineInputBorder(),
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
                                                border: state2.moduleController.text.isEmpty
                                                    ? OutlineInputBorder(borderSide: BorderSide(color: Colors.red))
                                                    : OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: TextField(
                                              controller:
                                                  state2.parcoursController,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.all(10),
                                                border: state2.parcoursController.text.isEmpty
                                                    ? OutlineInputBorder(borderSide: BorderSide(color: Colors.red))
                                                    : OutlineInputBorder(),
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
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                height: 40,
                                width: 100,
                                child: MaterialButton(
                                  onPressed: () async {
                                    saveDataToFirebase(widget.iduserweb);
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
                  }
                  else if (valeur == 'true' && valide == 'true'){
                     return isLoading ? Center(child: CircularProgressIndicator()) : Column(
                       children: [
                         Text(
                           'Répartion pour cette année',
                           style: TextStyle(
                               fontSize:
                               22, // Slightly larger text for the title
                               fontWeight: FontWeight.bold,
                               color: Colors.black87),
                         ),
                         buildRepartitionTable(),
                       ],
                     );
                  }
                  else if (valeur == 'true') {
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
                              'Boite de Réception ',
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
                    );}
                     else {
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
  // pas utilisé

  // UTILIS2
  void saveDataToFirebase(String iduserweb) async {
      FirebaseFirestore db = FirebaseFirestore.instance;
      var docRef = db.collection('users').doc(iduserweb);

      // Mise à jour des données si les champs sont valides.
      await docRef.update({
        'valide': 'true',
        'statu' : 'valider'
      }).catchError((error) {});

      // Sauvegarde des données.
      await saveData(iduserweb);
      await saveData2(iduserweb);

  }
  Widget buildRepartitionTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: repartitionData.entries.map<Widget>((parcoursEntry) {
          var parcours = parcoursEntry.key;
          var parcoursData = parcoursEntry.value;
          List<Widget> semesters = parcoursData.entries.map<Widget>((semesterEntry) {
            var semestre = semesterEntry.key;
            var semesterData = semesterEntry.value;
            return Expanded( // Use Expanded to distribute space evenly within the row
              child: buildSemesterData(parcours, semestre, semesterData),
            );
          }).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(parcours, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: semesters,
              ),
              Divider(thickness: 2.0, color: Colors.black),
            ],
          );
        }).toList(),
      ),
    );
  }
  Widget buildSemesterData(String parcours, String semestre, Map<String, List<Map<String, dynamic>>> semesterData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Text(semestre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Table(
          border: TableBorder.all(color: Colors.grey, width: 1),
          defaultColumnWidth: FixedColumnWidth(120.0),
          children: buildRows(semesterData),
        ),
      ],
    );
  }
  List<TableRow> buildRows(Map<String, List<Map<String, dynamic>>> semesterData) {
    List<TableRow> rows = [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey[300]),
        children: ['Module', 'Cours', 'TD', 'TP'].map((header) => TableCell(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(header, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        )).toList(),
      ),
    ];

    // Add data rows
    // Assuming that 'semesterData' is properly structured to have the same modules across 'Cours', 'TD', 'TP'
    semesterData['Cours']?.forEach((moduleData) {
      List<TableCell> cells = [TableCell(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(moduleData['module'], style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      )];

      cells.addAll(['Cours', 'TD', 'TP'].map((type) => TableCell(
        child: buildCell(semesterData, type, moduleData['module']),
      )));

      rows.add(TableRow(children: cells));
    });

    return rows;
  }
  Widget buildCell(Map<String, List<Map<String, dynamic>>> typeData, String type, String moduleName) {
    var data = typeData[type]?.firstWhere((entry) => entry['module'] == moduleName, orElse: () => {});
    bool hasData = data!.isNotEmpty;
    return Container(
      color: hasData ? Colors.green[100] : Colors.grey[100],
      padding: EdgeInsets.all(8.0),
      child: Text(hasData ? data['prof'] : '', style: TextStyle(color: hasData ? Colors.black : Colors.grey)),
    );
  }
  void showSnackbarMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
      backgroundColor: Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
