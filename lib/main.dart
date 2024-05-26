import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled4/repartion.dart';
import 'Insciption.dart';
import 'nagivateuradjoint.dart';
import 'chefdepartementView.dart';
import 'navigationprof.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Properly initialize Firebase based on the platform
  if (kIsWeb) {
    // Initialize Firebase for Web
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyDAm5_ewcGTaApc_M2ol32PibE2FXKS-vg",
          authDomain: "matierelink-4a87d.firebaseapp.com",
          projectId: "matierelink-4a87d",
          storageBucket: "matierelink-4a87d.appspot.com",
          messagingSenderId: "278555224342",
          appId: "1:278555224342:web:8e8c622f52bc0a4518c837"),
    );
  } else {
    // Initialize default Firebase app
    await Firebase.initializeApp();
  }

  // After Firebase has been initialized, run the app.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              // User not logged in
              return LoginForm();
            } else {
              // User is logged in
              return navigation(idnavigateur: user.uid);
            }
          }
          // Show loading while waiting for auth state
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String uid = '';
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  String? userEmail;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    setState(() {
      _isEmailFocused = _emailFocusNode.hasFocus;
    });
  }

  void _onPasswordFocusChange() {
    setState(() {
      _isPasswordFocused = _passwordFocusNode.hasFocus;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_email == "chefdepartement@gmail.com" && _password == "chef2024") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => navigation2(idnavigateur: "chef")),
        );
      } else if (_email == "adjointdepartement@gmail.com" && _password == "adjoint2024") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => navigationadjoint(idnavigateur: "adjoint")),
        );
      } else {
        try {
          // Tenter de se connecter avec FirebaseAuth
          UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email,
            password: _password,
          );

          // Connecté avec succès, naviguer vers une page d'accueil par exemple
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigation(idnavigateur: userCredential.user!.uid,)),
          );
        } catch (e) {
          // Afficher un message d'erreur en cas de problème de connexion
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur de connexion : ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 10),
              )
          );
        }
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool("auth", true);
      }
      print('Email: $_email, Password: $_password');
    }
  }

  Future<User?> signInWithGoogleAndStoreData() async {
    await Firebase.initializeApp();
    User? user;

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      try {
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithPopup(authProvider);
        user = userCredential.user;
      } catch (e) {
        print(e);
        throw Exception('Google Sign-In aborted by user');
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        try {
          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          user = userCredential.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            print("This account already exists with a different email");
          } else if (e.code == "invalid-credential") {
            print('Error occurred while accessing. Please try again.');
          }
        } catch (e) {
          print(e);
        }
      } else {
        throw Exception('Google Sign-In aborted by user');
      }
    }

    if (user != null) {
      // Check if this is the first time the user is logging in
      var userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      var doc = await userDoc.get();
      if (!doc.exists) {
        // Only set the user data if the document does not exist
        userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'grade': 'rien',
          'displayName': user.displayName,
          'statu': 'rien',
          'valide': "null",
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool("auth", true);
      }
    }

    return user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            right: MediaQuery.of(context).size.width * 0.50,
            child: Image.asset("assets/jj.png", fit: BoxFit.fill),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height *
                0.87, // Ajustez cette valeur selon vos besoins
            child: Image.asset("assets/YOU.png", fit: BoxFit.fill),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            right: MediaQuery.of(context).size.width * 0.20,
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
          Row(
            children: [
              Expanded(flex: 1, child: Container()),
              Container(
                width: MediaQuery.of(context).size.width * 0.45,
                color: Colors.transparent,
                margin: EdgeInsets.all(30),
                child: Material(
                  color: Colors.transparent,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Bienvenue !",
                              style: TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold),
                            )),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Connecter-vous",
                              style: TextStyle(color: Colors.blueGrey),
                            )),
                        SizedBox(height: 60),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: TextFormField(
                            focusNode: _emailFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                fontSize:
                                    12, // Set the font size smaller as needed
                                // Optional: You can also change the color
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                size: 15,
                                color:
                                    _isEmailFocused ? Colors.purple : Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.purple),
                              ),
                            ),
                            validator: (value) {
                              if (value!.isEmpty || !value.contains('@')) {
                                return "Veuillez entrer un email valide.";
                              }
                              return null;
                            },
                            onSaved: (value) => _email = value!,
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: TextFormField(
                            focusNode: _passwordFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              labelStyle: TextStyle(
                                fontSize:
                                    12, // Set the font size smaller as needed
                                // Optional: You can also change the color
                              ),
                              prefixIcon: Icon(
                                Icons.lock,
                                size: 15,
                                color: _isPasswordFocused
                                    ? Colors.purple
                                    : Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.purple),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value!.isEmpty || value.length < 6) {
                                return "Le mot de passe doit contenir au moins 6 caractères.";
                              }
                              return null;
                            },
                            onSaved: (value) => _password = value!,
                          ),
                        ),
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [

                            Container(
                              width: MediaQuery.of(context).size.width * 0.15,
                              height: MediaQuery.of(context).size.height * 0.07,
                              child: TextButton(
                                onPressed: (){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Inscription1Form()),
                                  );
                                },
                                child: Expanded(
                                  child: Text(
                                    'Nouveau utilisateur? Inscription',
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  minimumSize: Size(double.infinity, 50),
                                  primary: Colors.transparent,
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.15,
                              height: MediaQuery.of(context).size.height * 0.07,
                              child: ElevatedButton(
                                onPressed: _submit,
                                child: Expanded(
                                  child: Text(
                                    'CONEXSSION ',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  minimumSize: Size(double.infinity, 50),
                                  primary: Colors.blue,
                                ),
                              ),
                            ),
                            /*ElevatedButton.icon(
                              icon: Image.asset(
                                'assets/google.png',
                                height: 24.0, // Adjust the size accordingly
                                width: 24.0,
                              ),
                              label: Text("Login with Google"),
                              onPressed: () {
                                signInWithGoogleAndStoreData();
                              },
                              style: ElevatedButton.styleFrom(
                                primary: Colors.white, // Background color
                                onPrimary: Colors.grey, // Text and icon color
                                textStyle: TextStyle(
                                  color: Colors.black, // Text color
                                ),
                                elevation: 1, // Shadow depth
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),*/
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
