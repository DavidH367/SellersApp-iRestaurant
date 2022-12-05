import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login/mainScreens/home_screen.dart';
import 'package:login/widgets/custom_text_field.dart';
import 'package:login/widgets/loading_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart' as fStorage;

import '../global/global.dart';
import '../widgets/error_dialog.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();

  Position? position;
  List<Placemark>? placeMarks;

  String sellerImageUrl = "";
  String completeAddress = "";

  Future<void> _getImage() async{
   imageXFile = await _picker.pickImage(source: ImageSource.gallery);
   setState(() {
     imageXFile;
   });
  }

  getCurrentLocation() async{
    Position newPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    position = newPosition;
    placeMarks = await placemarkFromCoordinates(
      position!.latitude,
      position!.longitude,
    );

    Placemark pMark = placeMarks![0];

    completeAddress = '${pMark.subThoroughfare} ${pMark.subThoroughfare}, ${pMark.subLocality} ${pMark.locality}, ${pMark.subAdministrativeArea}, ${pMark.subAdministrativeArea} ${pMark.postalCode}, ${pMark.country}';

    locationController.text = completeAddress;
  }

  Future<void> formValidation() async{
    if(imageXFile == null){
      showDialog(
        context: context,
        builder: (c){
          return ErrorDialog(
            message: "Porfavor Selecciona una imagen.",
          );
        }
      );
    }else{
      if(passwordController.text == confirmPasswordController.text){
        if(confirmPasswordController.text.isNotEmpty && emailController.text.isNotEmpty && nameController.text.isNotEmpty && phoneController.text.isNotEmpty && locationController.text.isNotEmpty){
          //iniciar subida de imagen
          showDialog(context: context,
          builder: (c){
            return LoadingDialog(
              message: "Registrando su Cuenta",
            );
          }
          );
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          fStorage.Reference reference = fStorage.FirebaseStorage.instance.ref().child("sellers").child(fileName);
          fStorage.UploadTask uploadTask = reference.putFile(File(imageXFile!.path));
          fStorage.TaskSnapshot taskSnapshot = await uploadTask.whenComplete((){});
          await taskSnapshot.ref.getDownloadURL().then((url){
            sellerImageUrl = url;

            //guardando la informacion en FireStorage
            authenticateSellerAndSingUp();

          });

        }else{
          showDialog(
              context: context,
              builder: (c){
                return ErrorDialog(
                  message: "Porfavor ingrese toda la informacion requerida.",
                );
              }
          );
        }
      }else{
        showDialog(
            context: context,
            builder: (c){
              return ErrorDialog(
                message: "Las contraseñas no coinciden.",
              );
            }
        );
      }
    }
  }

  Future<void> authenticateSellerAndSingUp() async {
    User? currentUser;

    await firebaseAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
    ).then((auth){
      currentUser = auth.user;
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
      saveDataToFirestore(currentUser!).then((value){
        Navigator.pop(context);
        //enviar al usuario a inicio
        Route newRoute = MaterialPageRoute(builder: (c) => HomeScreen());
        Navigator.pushReplacement(context, newRoute);
        });
    }

  }


  Future saveDataToFirestore(User currentUser) async{
    FirebaseFirestore.instance.collection("sellers").doc(currentUser.uid).set({
      "sellerUID": currentUser.uid,
      "sellerEmail": currentUser.uid,
      "sellerName": nameController.text.trim(),
      "sellerAvatarUrl": sellerImageUrl,
      "phone": phoneController.text.trim(),
      "address": completeAddress,
      "status": "approved",
      "earnings": 0.0,
      "lat": position!.latitude,
      "lng": position!.longitude,
    });

    //guardar informacion
    sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences!.setString("uid", currentUser.uid);
    await sharedPreferences!.setString("email", currentUser.email.toString());
    await sharedPreferences!.setString("name", nameController.text.trim());
    await sharedPreferences!.setString("photoUrl", sellerImageUrl);

  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: 10,),
            InkWell(
              onTap: (){
                _getImage();
              },
                child: CircleAvatar(
                  radius: MediaQuery.of(context).size.width * 0.20,
                  backgroundColor: Colors.white,
                  backgroundImage: imageXFile==null ? null : FileImage(File(imageXFile!.path)),
                  child: imageXFile == null
                    ?
                Icon(
                    Icons.add_photo_alternate,
                    size: MediaQuery.of(context).size.width * 0.20,
                    color: Colors.grey,
                ) : null,

                )
            ),
            const SizedBox(height: 10,),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    data: Icons.person,
                    controller: nameController,
                    hintText: "Nombre",
                    isObsecre: false,
                  ),
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
                  CustomTextField(
                    data: Icons.lock,
                    controller: confirmPasswordController,
                    hintText: "Confirmar Contraseña",
                    isObsecre: true,
                  ),
                  CustomTextField(
                    data: Icons.phone,
                    controller: phoneController,
                    hintText: "Telefono",
                    isObsecre: false,
                  ),
                  CustomTextField(
                    data: Icons.my_location,
                    controller: locationController,
                    hintText: "Ubicacion Restaurante",
                    isObsecre: false,
                    enabled: true,
                  ),
                  Container(
                    width: 400,
                    height: 40,
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      label: Text(
                          "Obtener ubicacion actual",
                          style: TextStyle(color: Colors.white),
                      ),
                      icon: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        getCurrentLocation();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),


                        )
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30,),
            ElevatedButton(
              child: Text(
                "Registrarse",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              ),
              onPressed: (){
                  formValidation();
                },
            ),
            const SizedBox(height: 30,),
          ],
        ),
      ),
    );

  }
}

