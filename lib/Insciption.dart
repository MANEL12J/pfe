import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Inscription1Form extends StatefulWidget {
  @override
  _InscriptionFormState createState() => _InscriptionFormState();
}

class _InscriptionFormState extends State<Inscription1Form> {
  final _formKey = GlobalKey<FormState>(); // Correct type argument here

  String _nom = '';
  String _prenom = '';
  String _email = '';
  String _grade = 'Choisir grade';
  String _fonction = 'Choisir fonction';

  final List<String> _grades = [
    'Choisir grade',
    'Professeur',
    'Maître de conférences A',
    'Maître de conférences B',
    'Maître assistant A',
    'Maître assistant B',
  ];

  final List<String> _fonctions = [
    'Choisir fonction',
    'Chef de département',
    'Responsable de spécialité',
    'Président CPC',
    'Responsable de domaine',
    'Responsible de filière',
    'Aucun',
  ];

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Créer une référence de document avec un ID unique
      DocumentReference documentReference =
          FirebaseFirestore.instance.collection('inscriptions').doc();

      // Sauvegarde dans Firestore et récupération de l'UID du document
      documentReference.set({
        'statu': 'rien',
        'valide': "null",
        'timestamp': FieldValue.serverTimestamp(),
        'nom': _nom,
        'displayName': '$_nom $_prenom',
        'prenom': _prenom,
        'email': _email,
        'grade': _grade,
        'fonction': _fonction,
        'uid': documentReference.id // Sauvegarde l'ID dans le même document
      }).then((_) {
        // Afficher un message toast prolongé
        _showLongToast("Inscription validée, votre demande est en cours de traitement.}");
          Navigator.pop(context);
      }).catchError((error) {
        _showLongToast("Erreur lors de l'inscription: ${error.toString()}");
      });
    }
  }

  void _showLongToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength:
            Toast.LENGTH_LONG, // Durée par défaut d'environ 3-5 secondes
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);

    // Attendre 30 secondes avant d'annuler le toast
    Future.delayed(Duration(seconds: 35), () {
      Fluttertoast.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height *
                0.40, // Ajustez cette valeur selon vos besoins
            child: Image.asset("assets/wow.png", fit: BoxFit.fill),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.02,
            right: MediaQuery.of(context).size.width * 0.80,
            // Ajustez cette valeur selon vos besoins
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
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  
                  Expanded(child: Image.asset("assets/CAPTURE.png", fit: BoxFit.fill)),
                  SizedBox(
                    width: MediaQuery.of(context).size.width *
                        0.5, // Take up 50% of screen width
                    child: Card(
                      // Wrapping content inside a Card for better aesthetics
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            15.0), // Rounded corners for the Card
                      ),
                      margin: EdgeInsets.all(20), // Space around the Card
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            // Use Column for more compact layout inside Card
                            mainAxisSize: MainAxisSize
                                .min, // Fit content in minimal space needed
                            children: <Widget>[
                              
                              Expanded(
                                child: Text(
                                  "Formulaire d\'inscription",
                                  style: TextStyle(
                                      fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Divider(thickness: 2),
                              // Divider after title
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Nom',
                                    fillColor: Colors
                                        .white, // Background color of input field
                                    filled: true,
                                    border: OutlineInputBorder(
                                      // Rounded border for TextFormField
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre nom';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _nom = value!;
                                  },
                                ),
                              ),
                              SizedBox(height: 20), 
                              // Spacing between fields
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Prénom',
                                    fillColor: Colors
                                        .white, // Background color of input field
                                    filled: true,
                                    border: OutlineInputBorder(
                                      // Rounded border for TextFormField
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre prénom';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _prenom = value!;
                                  },
                                ),
                              ),
                              SizedBox(height: 20)
                              , // Spacing between fields
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    fillColor: Colors
                                        .white, // Background color of input field
                                    filled: true,
                                    border: OutlineInputBorder(
                                      // Rounded border for TextFormField
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        !value.contains('@')) {
                                      return 'Veuillez entrer un email valide';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _email = value!;
                                  },
                                ),
                              ),
                              SizedBox(height: 20), // Spacing before row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [

                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.white, // Background color for dropdown
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey)
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white)
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        value: _grade,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _grade = newValue!;
                                          });
                                        },
                                        items: _grades.map<DropdownMenuItem<String>>((String grade) {
                                          return DropdownMenuItem<String>(
                                            value: grade,
                                            child: Text(grade),
                                          );
                                        }).toList(),
                                        onSaved: (value) {
                                          _grade = value!;
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.white, // Background color for dropdown
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey)
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white)
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        value: _fonction,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _fonction = newValue!;
                                          });
                                        },
                                        items: _fonctions.map<DropdownMenuItem<String>>((String fonction) {
                                          return DropdownMenuItem<String>(
                                            value: fonction,
                                            child: Text(fonction),
                                          );
                                        }).toList(),
                                        onSaved: (value) {
                                          _fonction = value!;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed : () async {
                                     _saveForm();



                                },
                                  child: Text('Inscripe'),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors
                                        .blue, // Background color of the button
                                    onPrimary: Colors.white, // Text color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          10), // Rounded corners for the button
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 50,
                                        vertical:
                                            15), // Padding inside the button
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
