import 'package:flutter/material.dart';
import 'package:login/authentication/login.dart';
import 'package:login/authentication/registro.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
 _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                colors: [
                  Colors.cyan,
                  Colors.amber,
                ],
               begin: const FractionalOffset(0.0, 0.0),
               end: const FractionalOffset(1.0, 0.0),
               stops: [0.0, 0.1],
               tileMode: TileMode.clamp,
                ),
              ),
          ),
                  title: const Text(
          "El Provenir Steaks",
          style: TextStyle(
            fontSize: 60,
            color: Colors.white,
            fontFamily: "Lobster",
               ),
              ),

          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.lock,color: Colors.white,),
                text: "Login",
                 ),
                Tab(
                icon: Icon(Icons.person,color: Colors.white,),
                text: "Registrarse",
                   ),
                 ],
                 indicatorColor: Colors.white38,
                 indicatorWeight: 6,
              ),
           ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.amber,
                Colors.cyan,
              ],
            ),
          ),
          child: const TabBarView(
            children:[
              LoginScreen(),
              RegistroScreen(),
            ]
          )
        ),
      ),
    );


  }
}
