import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfessorHomePage extends StatefulWidget {
  final String iduserweb;
  ProfessorHomePage({Key? key, required this.iduserweb}) : super(key: key);

  @override
  _ProfessorHomePageState createState() => _ProfessorHomePageState();
}

class _ProfessorHomePageState extends State<ProfessorHomePage> {
  String professorName = '';
  String professorFirstName = '';
  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>> repartitionData = {};

  final List<String> parcoursList = ['L1', 'L2', 'L3'];
  final List<String> semestresList = ['Semestre 1', 'Semestre 2'];

  @override
  void initState() {
    super.initState();
    login(widget.iduserweb);
  }

  void login(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        professorName = userDoc['nom'];
        professorFirstName = userDoc['prenom']; // Assuming you have a 'prenom' field
      });
      fetchRepartitionData();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Repartition Table'),
      ),
      body: buildRepartitionTable(context),
    );
  }

  Widget buildRepartitionTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parcoursList.map<Widget>((parcours) {
          if (!repartitionData.containsKey(parcours) || repartitionData[parcours]!.isEmpty) {
            return Container(); // Skip if no data for this parcours
          }

          var parcoursData = repartitionData[parcours]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: semestresList.map<Widget>((semestre) {
              if (!parcoursData.containsKey(semestre) || parcoursData[semestre]!.isEmpty) {
                return Container(); // Skip if no data for this semestre
              }

              var semesterData = parcoursData[semestre]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('$parcours - $semestre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Table(
                    border: TableBorder.all(color: Colors.grey, width: 1),
                    defaultColumnWidth: FixedColumnWidth(120.0),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[300]),
                        children: ['Module', 'Cours', 'TD', 'TP'].map((header) => TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(header, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        )).toList(),
                      ),
                      ...semesterData.keys.expand((type) => semesterData[type]!.map((entry) {
                        return TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(entry['module'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            ...['Cours', 'TD', 'TP'].map((header) {
                              return TableCell(
                                child: buildCell(semesterData, type, header, professorName, professorFirstName, entry['module']),
                              );
                            }).toList(),
                          ],
                        );
                      })).toList(),
                    ],
                  ),
                  Divider(thickness: 2.0, color: Colors.black),
                ],
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
  void fetchRepartitionData() async {
    final int currentYear = DateTime.now().year;
    final firestore = FirebaseFirestore.instance;

    for (String parcours in parcoursList) {
      for (String semestre in semestresList) {
        Map<String, List<Map<String, dynamic>>> typeData = {'Cours': [], 'TD': [], 'TP': []};
        for (String type in typeData.keys) {
          QuerySnapshot querySnapshot = await firestore
              .collection('repartition')
              .doc(currentYear.toString())
              .collection(parcours)
              .doc(semestre)
              .collection(type)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            typeData[type] = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          }
        }
        if (repartitionData[parcours] == null) {
          repartitionData[parcours] = {};
        }
        repartitionData[parcours]![semestre] = typeData;
      }
    }
    setState(() {});
  }


  Widget buildCell(Map<String, List<Map<String, dynamic>>> typeData, String currentType, String header, String professorName, String professorFirstName, String module) {
    bool isProfessor = false;
    String text = '';

    if (typeData[currentType] != null) {
      List<Map<String, dynamic>> relevantEntries = typeData[currentType]!.where((data) => data['module'] == module).toList();
      isProfessor = relevantEntries.any((data) => data['prof'] == professorName || data['prof'] == professorFirstName);

      if (currentType == header && isProfessor) {
        Map<String, dynamic> matchingData = relevantEntries.firstWhere(
                (data) => data['prof'] == professorName || data['prof'] == professorFirstName,
            orElse: () => <String, dynamic>{}
        );
        text = matchingData.isNotEmpty ? matchingData['prof'] : '';
      }
    }

    return Container(
      color: isProfessor ? Colors.green[100] : Colors.grey[100],
      padding: EdgeInsets.all(8.0),
      child: Text(text),
    );
  }


}