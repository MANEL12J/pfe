import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RepartitionPage extends StatefulWidget {
  @override
  _RepartitionPageState createState() => _RepartitionPageState();
}

class _RepartitionPageState extends State<RepartitionPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Repartition Management'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('repartition').where('valide', isEqualTo: 'true').get(),
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
                                setState(() {
                                  selectedDocId = doc.id;
                                });
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
}