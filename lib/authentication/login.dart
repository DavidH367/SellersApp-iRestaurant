import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:login/authentication/auth_screen.dart';
import 'package:login/global/global.dart';
import 'package:login/mainScreens/home_screen.dart';
import 'package:login/widgets/error_dialog.dart';
import 'package:login/widgets/loading_dialog.dart';

import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  formValidation(){
    if(emailController.text.isNotEmpty && passwordController.text.isNotEmpty){
      //inicio de sesion
      loginNow();
    }else{
      showDialog(
          context: context,
          builder: (c){
            return ErrorDialog(
              message: "Porfavor ingrese usuario y contraseña.",);
          }
      );
    }
  }

  loginNow() async{
    showDialog(
        context: context,
        builder: (c){
          return LoadingDialog(
            message: "Validando datos.",);
        }
    );
    User? currentUser;
    await firebaseAuth.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    ).then((auth){
      currentUser = auth.user!;
    }).catchError((error){
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (c){
            return ErrorDialog(
              message: error.message.toString(),
            );
          }
      );
    });
    if(currentUser != null){
      readDataAndSetDataLocally(currentUser!);
    }
  }

  Future readDataAndSetDataLocally(User currentUser) async{
    await FirebaseFirestore.instance.collection("sellers")
        .doc(currentUser.uid)
        .get()
        .then((snapshot) async{
          if(snapshot.exists){
            if(snapshot.data()!["status"] == "approved"){
              await sharedPreferences!.setString("uid", currentUser.uid);
              await sharedPreferences!.setString("email", snapshot.data()!["sellerEmail"]);
              await sharedPreferences!.setString("name", snapshot.data()!["sellerName"]);
              await sharedPreferences!.setString("photoUrl", snapshot.data()!["sellerAvatarUrl"]);

              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (c)=> const HomeScreen()));
            }else{
              firebaseAuth.signOut();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Administrador ha bloqueado tu cuenta. \n\nContacta aqui: daniel367daniel367@gmail.com");
            }

          }else{
            firebaseAuth.signOut();
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (c)=> const AuthScreen()));

            showDialog(
                context: context,
                builder: (c){
                  return ErrorDialog(
                    message: "No hay historial encontrado.",
                  );
                }
            );
          }
    });

  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Image.asset(
                "images/logo_transparent.png"
              ),
            ),
          ),
        Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                data: Icons.email,
                controller: emailController,
                hintText: "Correo",
                isObsecre: false,
              ),
              CustomTextField(
                data: Icons.lock,
                controller: passwordController,
                hintText: "Contraseña",
                isObsecre: true,
              ),

            ],
          )

        ),
          ElevatedButton(
            child: const Text(
              "Iniciar Sesion",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
            ),
            onPressed: () {
              formValidation();

            },
          ),
          const SizedBox(height: 30,),
        ],
      ),
    );
  }
}

