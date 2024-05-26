import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfessorHomePage extends StatefulWidget {
  final String userId;
  const ProfessorHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfessorHomePageState createState() => _ProfessorHomePageState();
}

class _ProfessorHomePageState extends State<ProfessorHomePage> {
  String professorName = '';
  String professorFirstName = '';
  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>> repartitionData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      await login(widget.userId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Repartition Table')),
      body: isLoading ? CircularProgressIndicator() : buildRepartitionTable(),
    );
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
}

