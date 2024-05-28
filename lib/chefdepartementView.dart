import 'dart:convert';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:badges/badges.dart'
    as badges; // Alias for the external badges package
import 'histpriqueview.dart';
import 'main.dart';
import 'package:http/http.dart' as http;

class chefdepartementView extends StatefulWidget {
  String idchefdepartement;
  chefdepartementView({Key? key, required this.idchefdepartement})
      : super(key: key);
  @override
  _chefdepartementView createState() => _chefdepartementView(idchefdepartement);
}

class _chefdepartementView extends State<chefdepartementView>
    with TickerProviderStateMixin {
  // Pagination state
  String idchefdepartement;
  _chefdepartementView(this.idchefdepartement);

  Color primary = const Color(0xffEFEDF5);
  late TabController _tabController;
  int _selectedTabIndex = 0;
  String buttonText = "Valider la répartition";
  Color buttonColor = Colors.redAccent;

  List<String> columnNames = [];
  List sug = [];
  List users2 = [];
  final String documentId = DateTime.now().year.toString();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isClicked = false;
  Future<void> checkRepartitionStatus() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('repartition')
          .doc(currentYear.toString()) // Replace with the actual document ID for the current year
          .get();

      if (doc.exists) {
        String status = doc['valide'];
        setState(() {
          if (status == 'true') {
            isClicked = true;
            buttonColor = Colors.blueGrey;
            buttonText = "Répartition validée";
          } else if (status == 'en attente') {
            isClicked = false;
            buttonColor = Colors.redAccent;
            buttonText = "Valider la répartition";
          }
        });
      }
    } catch (e) {
      print("Error checking repartition status: $e");
    }
  }

  Future<void> validateRepartition(
      String documentId, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('repartition')
        .doc(documentId)
        .update({'valide': 'true'}).then((_) {
      setState(() {
        isClicked = true;
        buttonColor = Colors.blueGrey;
        buttonText = "Répartition validée";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Répartition globale validée et envoyée aux enseignants."),
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la validation : $error"),
          duration: Duration(seconds: 10),
        ),
      );
    });
  }

  Stream<DocumentSnapshot> _getValidationStatus() {
    final int currentYear = DateTime.now().year;

    return firestore
        .collection('repartition')
        .doc(currentYear.toString())
        .snapshots();
  }

  TextEditingController searchController = TextEditingController();
  bool isLoading = true; // Ajouter cette ligne dans votre classe
  void getDate() async {
    setState(() => isLoading = true); // Début du chargement
    QuerySnapshot responsebody = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('timestamp', descending: true)
        .get();
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
        sug = users2
            .where((user) => user['displayName']
                .toLowerCase()
                .contains(searchTerm.toLowerCase()))
            .toList();
        print("Displaying filtered users.");
      }
      print(
          "Current suggestions: $sug"); // Log pour vérifier les données dans sug
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
                    SizedBox(
                      height: 10,
                    ),
                    _buildDateTile(context, setState, 'Au', endDate, false),
                    if (showDateRangeMessage)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          'La fiche de voeux sera disponible du ${_formatDate(startDate!)} au ${_formatDate(endDate!)}.',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700]),
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

  ListTile _buildDateTile(BuildContext context, StateSetter setState,
      String label, DateTime? date, bool isStartDate) {
    return ListTile(
      title:
          Text('$label : ${date != null ? _formatDate(date) : "Sélectionner"}'),
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

  void _selectDate(
      BuildContext context, StateSetter setState, bool isStartDate) async {
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
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('dates').doc();

    // Ajouter les dates avec l'ID du document dans le même document
    await docRef.set({
      'uid': docRef.id, // Sauvegarder l'UID dans le document
      'startDate': startDate,
      'endDate': endDate,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Récupérer tous les documents de la collection 'users' où le champ 'statu' n'est pas égal à 'valide'
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('statu', isNotEqualTo: 'valider')
        .get();

    // Mettre à jour le champ 'status' pour chaque utilisateur
    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'statu': 'en attente',
        'valide': 'false',
      });
    }
  }

  final TextEditingController _messageController = TextEditingController();

  // Déplacer l'inscription et créer un utilisateur
  void _validerInscription(String documentId, Map<String, dynamic> data) async {
    try {
      String email = "${data['nom']}${data['prenom']}@matierelink.com"
          .toLowerCase()
          .replaceAll(' ', '');
      String password = "${DateTime.now().year}${data['nom']}";

      // Créer l'utilisateur dans FirebaseAuth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Ajouter l'utilisateur à la collection 'users' avec l'UID comme ID du document
      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        ...data, // Importer toutes les données de l'inscription
        'uid': uid // Sauvegarder également l'UID dans le document
      });

      // Supprimer l'inscription de la collection 'inscriptions'
      await FirebaseFirestore.instance
          .collection('inscriptions')
          .doc(documentId)
          .delete();

      _showLongToast("Inscription validée et utilisateur créé");
    } catch (e) {
      _showLongToast("Erreur: ${e.toString()}");
    }
  }

  void _showLongToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG, // Durée par défaut d'environ 3-5 secondes
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // Attendre 30 secondes avant d'annuler le toast
    Future.delayed(Duration(seconds: 35), () {
      Fluttertoast.cancel();
    });
  }

  Future<void> sendValidationEmail(Map<String, dynamic> doc) async {
    String toEmail = "${doc['nom']}${doc['prenom']}@matierelink.com"
        .toLowerCase()
        .replaceAll(' ', '');
    String topassword = "${DateTime.now().year}${doc['nom']}";

    final service_id = 'service_qjck4f1';
    final template_id = 'template_s2hndwe';
    final user_id = 'sbG2M-XWbWJeQmgYu';
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'service_id': service_id,
        'template_id': template_id,
        'user_id': user_id,
        'template_params': {
          'user_subject': "Validation de l'inscription",
          'to_name': doc['nom'],
          'user_message': "email : $toEmail \n mot de passe : $topassword",
          'to_email': doc['email'],
          'user_email': "manelbensalah95@gmail.com",
        }
      }),
    );

    if (response.statusCode == 200) {
      // Handle successful email sending
      print("Email sent successfully!");
    } else {
      // Handle errors
      print("Failed to send email. Status code: ${response.statusCode}");
    }
  }

  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex =
            _tabController.index; // Update the selected tab index
      });
    });
    getDate();
    checkRepartitionStatus();
  }

  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final DocumentReference repartitionRef =
        firestore.collection('repartition').doc(currentYear.toString());
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 5,
        title: Text('Chef departement',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('userId',
                isEqualTo:
                    "adjoint") // Assuming 'adjoint' is the chief's user ID
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
            position: BadgePosition.topEnd(top: 0, end: 3),
            child: FloatingActionButton(
              onPressed: () {
                markMessagesAsRead(
                    'adjoint'); // Mark the messages as read when the dialog is opened
                showDialog(
                  context: context,
                  builder: (context) => buildChatDialog(context),
                );
              },
              child: Icon(Icons.message),
              backgroundColor: Colors.blue,
            ),
          );
        },
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
                labelStyle:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                labelColor: Colors.black,
                labelPadding: const EdgeInsets.only(left: 20, right: 20),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(
                    text: "Répartion",
                  ),
                  Tab(text: "Valider Inscription"),
                  Tab(text: "Enseigants"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  //PREMIER TAB
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Répartion Globale",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 23),
                            ),
                            ElevatedButton(
                              onPressed: isClicked
                                  ? null
                                  : () => validateRepartition(currentYear.toString(),
                                      context), // Replace with the actual document ID for the current year
                              child: Text(
                                buttonText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) => buttonColor,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openDatePickerDialog,
                              icon: Icon(
                                Icons.calendar_today,
                                size: 10,
                              ), // Icône du calendrier
                              label: Text(
                                  'Ajouter un deadline'), // Texte du bouton
                              style: ElevatedButton.styleFrom(
                                primary: Colors
                                    .greenAccent, // Couleur de fond du bouton
                                onPrimary: Colors
                                    .white, // Couleur du texte et de l'icône
                                elevation: 5, // Ombre du bouton
                                textStyle: TextStyle(
                                  fontSize: 13, // Taille du texte
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10), // Padding interne du bouton
                                shape: RoundedRectangleBorder(
                                    // Ajoutez cette ligne pour les bordures arrondies
                                    borderRadius: BorderRadius.circular(
                                        2) // Radius de 10.0 pour les coins arrondis
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
                              flex: 4,
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: repartitionRef.snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child: Text(
                                            "Erreur lors du chargement des données"));
                                  } else if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return Center(
                                        child:
                                            Text("Aucune donnée disponible"));
                                  }

                                  var data = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  String status = data['valide'] ?? 'non';
                                  switch (status) {
                                    case 'en attente':
                                      return FutureBuilder<
                                          Map<String, dynamic>>(
                                        future: fetchData(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                "Erreur lors de la récupération des données");
                                          } else if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            return buildRepartitionTable(
                                                context, snapshot.data!);
                                          } else {
                                            return Text(
                                                "Aucune répartition à afficher");
                                          }
                                        },
                                      );
                                    case 'true':
                                      return FutureBuilder<
                                          Map<String, dynamic>>(
                                        future: fetchData(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                "Erreur lors de la récupération des données");
                                          } else if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            return buildRepartitionTable(
                                                context, snapshot.data!);
                                          } else {
                                            return Text(
                                                "Aucune répartition à afficher");
                                          }
                                        },
                                      );
                                    default:
                                      return Center(
                                          child: Text(
                                              "Aucune répartition disponible pour l'instant"));
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('dates')
                                    .orderBy('timestamp', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('Erreur: ${snapshot.error}');
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.data == null ||
                                      snapshot.data!.docs.isEmpty) {
                                    // Aucune donnée disponible, vous pouvez retourner un widget vide
                                    return SizedBox
                                        .shrink(); // ou afficher un message ou autre widget ici si nécessaire
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
                                          padding: EdgeInsets.symmetric(
                                              vertical: 6.0),
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
                                            itemCount:
                                                snapshot.data!.docs.length,
                                            itemBuilder: (context, index) {
                                              DocumentSnapshot doc =
                                                  snapshot.data!.docs[index];
                                              Timestamp t = doc['startDate'];
                                              Timestamp t2 = doc['endDate'];
                                              DateTime startDate = t.toDate();
                                              DateTime endDate = t2.toDate();
                                              bool isExpired = endDate
                                                  .isBefore(DateTime.now());

                                              return SizedBox(
                                                height: 60,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0, right: 8),
                                                  child: TimelineTile(
                                                    alignment:
                                                        TimelineAlign.manual,
                                                    lineXY: 0.1,
                                                    hasIndicator: true,
                                                    isFirst: index == 0,
                                                    isLast: index ==
                                                        snapshot.data!.docs
                                                                .length -
                                                            1,
                                                    indicatorStyle:
                                                        IndicatorStyle(
                                                      width: 10,
                                                      color:
                                                          Colors.blue.shade300,
                                                    ),
                                                    beforeLineStyle: LineStyle(
                                                      color:
                                                          Colors.blue.shade600,
                                                      thickness: 1.5,
                                                    ),
                                                    endChild: Container(
                                                      padding:
                                                          EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Text(
                                                                  "De : ${startDate.day}/${startDate.month}/${startDate.year}",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          12),
                                                                ),
                                                                Text(
                                                                  "À : ${endDate.day}/${endDate.month}/${endDate.year}",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          12),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (isExpired)
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    Colors.red,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                              ),
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          5,
                                                                      vertical:
                                                                          2),
                                                              child: Text(
                                                                'Fermé',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                            )
                                                          else
                                                            SizedBox(
                                                              width:
                                                                  40, // Correspond à la taille du conteneur 'Fermé'
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
                  //DEUXI2ME TAB
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('inscriptions')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return Text('Erreur: ${snapshot.error}');
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return Center(child: CircularProgressIndicator());
                      final data = snapshot.requireData;

                      return ListView.separated(
                        itemCount: data.size,
                        separatorBuilder: (context, index) => Divider(
                          thickness: 1,
                          indent: 15,
                          endIndent: 15,
                        ),
                        itemBuilder: (context, index) {
                          var doc = data.docs[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(15),
                              title: Text(
                                "${doc['nom']} ${doc['prenom']}",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    "Email: ${doc['email']}",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Grade: ${doc['grade']}",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Fonction: ${doc['fonction']}",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  _validerInscription(doc.id,
                                      doc.data() as Map<String, dynamic>);
                                  await sendValidationEmail(
                                      doc.data() as Map<String, dynamic>);
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  child: Text(
                                    'Valider Inscription',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  //TROISI2ME TAB
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.0),
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.search, color: Colors.grey),
                                  hintText: 'Search',
                                  hintStyle:
                                      TextStyle(color: Colors.grey.shade500),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade100,
                                        width: 2.0),
                                  ),
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                            Expanded(
                                child: Card(
                                    margin: EdgeInsets.all(20),
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('users')
                                          .orderBy('timestamp',
                                              descending: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError)
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        switch (snapshot.connectionState) {
                                          case ConnectionState.waiting:
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          default:
                                            List<Map<String, dynamic>> users =
                                                snapshot.data!.docs.map(
                                                    (DocumentSnapshot
                                                        document) {
                                              return document.data()
                                                  as Map<String, dynamic>;
                                            }).toList();
                                            // Filter users based on search query
                                            if (searchController
                                                .text.isNotEmpty) {
                                              users = users.where((user) {
                                                return user['displayName']
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains(searchController
                                                        .text
                                                        .toLowerCase());
                                              }).toList();
                                            }
                                            return buildUsersTable(
                                                users); // Call the function with the list of filtered users
                                        }
                                      },
                                    ))),
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

  final int currentYear = DateTime.now().year;
  Future<Map<String, dynamic>> fetchData() async {
    DocumentReference anneeRef =
        firestore.collection('repartition').doc(currentYear.toString());
    Map<String, dynamic> repartitionData = {};

    List<String> parcoursList = ['L1', 'L2', 'L3'];
    List<String> semestreList = ['Semestre 1', 'Semestre 2'];

    for (String parcours in parcoursList) {
      repartitionData[parcours] = {};
      for (String semestre in semestreList) {
        var modules = _getModulesForParcoursSemestre(parcours, semestre);
        repartitionData[parcours][semestre] = {};

        for (String module in modules) {
          repartitionData[parcours][semestre]
              [module] = {'Cours': 'N/A', 'TD': 'N/A', 'TP': 'N/A'};
          for (String type in ['Cours', 'TD', 'TP']) {
            try {
              var collectionRef =
                  anneeRef.collection(parcours).doc(semestre).collection(type);
              var snapshot =
                  await collectionRef.where('module', isEqualTo: module).get();
              var profs = snapshot.docs.isNotEmpty
                  ? snapshot.docs
                      .map((doc) => doc.data()['prof'] as String? ?? 'N/A')
                      .join(', ')
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

  List<String> _getModulesForParcoursSemestre(
      String parcours, String semestre) {
    Map<String, Map<String, List<String>>> courses = {
      'L1': {
        'Semestre 1': [
          'Analyse1',
          'Algèbre 1',
          'ASD',
          'Structure Machine 1',
          'Terminologie Scientifique',
          'Langue Étrangère',
          'Option (Physique / Mécanique du Point)'
        ],
        'Semestre 2': [
          'Analyse2',
          'Algèbre 2',
          'ASD 2',
          'Structure Machine 2',
          'Proba/ statistique',
          'Technologies de l\'information et communication',
          'Option (Physique / Mécanique du Point)',
          'Outills de programmation pour les mathématiques'
        ]
      },
      'L2': {
        'Semestre 1': [
          'Architecture ordinateur',
          'ASD3',
          'THG',
          'Système d\'information',
          'Méthodes numériques',
          'Logique mathématiques',
          'Langue étrangère 2'
        ],
        'Semestre 2': [
          'THL',
          'Système d\'exploitation 1',
          'Base de données',
          'Réseaux',
          'Programmation orientée objet',
          'Développement applications web',
          'Langue étrangère 3'
        ]
      },
      'L3': {
        'Semestre 1': [
          'Système d\'exploitation 2',
          'Compilation',
          'IHM',
          'Génie logiciel',
          'Programmation linéaire',
          'Probabilités et statistiques',
          'Économie numérique'
        ],
        'Semestre 2': [
          'Applications mobiles',
          'Sécurité informatique',
          'Intelligence artificielle',
          'Données semi-structurées',
          'Rédaction scientifique',
          'Projet',
          'Création et développement web'
        ]
      }
    };

    return courses[parcours]?[semestre] ?? [];
  }

  Widget buildRepartitionTable(
      BuildContext context, Map<String, dynamic> repartitionData) {
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
                child: Text(parcours,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    repartitionData[parcours].keys.map<Widget>((semestre) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(semestre,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width),
                          child: Table(
                            border:
                                TableBorder.all(color: Colors.grey, width: 1),
                            defaultColumnWidth: FixedColumnWidth(100.0),
                            children: [
                              TableRow(
                                decoration:
                                    BoxDecoration(color: Colors.grey[300]),
                                children: [
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Modules',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  ...repartitionData[parcours][semestre]
                                      .keys
                                      .map((module) {
                                    return TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(module,
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
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
                                        child: Text(type,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    ...repartitionData[parcours][semestre]
                                        .keys
                                        .map((module) {
                                      String cellValue =
                                          repartitionData[parcours][semestre]
                                              [module][type];
                                      return TableCell(
                                        child: Container(
                                          color: cellValue == 'N/A'
                                              ? Colors.orange[200]
                                              : null,
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

  Widget buildChatDialog(BuildContext context) {
    double width =
        MediaQuery.of(context).size.width * 0.4; // 40% de la largeur de l'écran

    return Dialog(
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            color: Colors.white,
            width: width,
            height: MediaQuery.of(context).size.height *
                0.9, // 90% de la hauteur de l'écran
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Aligner le texte à gauche
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Boite de Réception", // Ou tout autre titre que vous souhaitez utiliser
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue, // Vous pouvez ajuster la couleur ici
                    ),
                  ),
                ),
                Expanded(
                  child: buildMessageList(context, width),
                ),
                buildInputField(context, _messageController, width),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildInputField(BuildContext context,
      TextEditingController messageController, double width) {
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
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () =>
                _sendMessage(messageController.text, idchefdepartement),
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
                idchefdepartement; // Compare message userId with current user's ID
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

  Widget buildUsersTable(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(child: Text("Pas d'enseignants trouvé"));
    }

    // Assuming that all documents have the same keys
    List<String> headers = users.first.keys
        .where((key) => key != "timestamp" && key != "uid" && key != "valide")
        .toList();
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
        Container(height: 2, color: Colors.black),
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> user = users[index];
              return Padding(
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
}

class navigation2 extends StatefulWidget {
  String idnavigateur;
  navigation2({Key? key, required this.idnavigateur}) : super(key: key);
  @override
  _navigation2 createState() => _navigation2(idnavigateur);
}

class _navigation2 extends State<navigation2> {
  String idnavigateur;
  int selectedindex = 0;
  Color primary = const Color(0xff89B5A2);
  late List<Widget> scr;
  _navigation2(this.idnavigateur) {
    scr = [
      chefdepartementView(
        idchefdepartement: "chef",
      ),
      RepartitionPage(),
    ];
  }
  final labelstyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
  Color card = const Color(0xFFF9F9F9);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.black26,
            selectedIconTheme:
                const IconThemeData(color: Colors.white, size: 20),
            unselectedIconTheme:
                const IconThemeData(color: Colors.black87, size: 20),
            selectedLabelTextStyle: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle:
                const TextStyle(color: Colors.black87, fontSize: 12),
            labelType: NavigationRailLabelType.all,

            onDestinationSelected: (int i) {
              setState(() {
                selectedindex = i;
              });
            },
            selectedIndex: selectedindex,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard),
                  label: Text('Boite de réception ')),
              NavigationRailDestination(
                  icon: Icon(Icons.add), label: Text('Historique')),
            ],

            // Called when one tab is selected
            leading: Column(
              children: [
                const SizedBox(
                  height: 8,
                ),
                Image.asset(
                  "photo_2024-05-28_17-10-33-removebg-preview.png",
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                const SizedBox(
                  height: 40,
                ),
              ],
            ),
            trailing: Column(
              children: [
                SizedBox(
                  height: 170,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    color: Colors.redAccent,
                    textColor: Colors.white,
                    onPressed: () async {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => MyApp()));
                    },
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize
                          .min, // Use MainAxisSize.min to wrap content within the button
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
          ),
          Expanded(
            flex: 3,
              child: Container(color: Colors.white, child: scr[selectedindex])),
        ],
      ),
    );
  }
}
