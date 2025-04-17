// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vms/components/button.dart';
import 'package:vms/model/pass_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:vms/screens/pass_screen.dart';
import 'package:http/http.dart' as http;

class RegisterVisit extends StatefulWidget {
  const RegisterVisit({super.key});
  @override
  State<RegisterVisit> createState() => _RegisterVisitState();
}

class _RegisterVisitState extends State<RegisterVisit> {
  final _auth = FirebaseAuth.instance;
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  File? photo;
  final ImagePicker _picker = ImagePicker();

  // string for displaying the error Message
  String? errorMessage;

  String idTypeSelected = "Aadhaar";
  // String branch = "";

  String department = "Degree";

  // List<String> getBranch() {
  //   if (department == "Diploma") {
  //     return ["CSEAIML", "Computer Engineer", "Electrical"];
  //   } else {
  //     return [];
  //   }
  // }

  Future getAllBranches() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where("admin", isEqualTo: true)
        .get();
    Map<String, Map<String, List<String>>> streamToBranchMobiles = {};

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final stream = data['stream'];
      final branch = data['branch'];
      final mobile = data['mobile'];

      if (stream != null && branch != null && mobile != null) {
        // Initialize if stream not present
        streamToBranchMobiles.putIfAbsent(stream, () => {});
        // Initialize if branch not present under that stream
        streamToBranchMobiles[stream]!.putIfAbsent(branch, () => []);
        // Add mobile
        streamToBranchMobiles[stream]![branch]!.add(mobile.toString());
      }
    }

    setState(() {
      streamToBranchList = {
        for (var stream in streamToBranchMobiles.keys)
          stream: streamToBranchMobiles[stream]!
      };
    });

// Convert sets to lists
  }

  Map<String, Map<String, List<String>>> streamToBranchList = {};

  // List<String?> _branches = [];
  String selectedMobile = '';
  String _selectedBranch = '';
  @override
  void initState() {
    fetchBranches();
    super.initState();
  }

  void fetchBranches() async {
    await getAllBranches();
  }

  // our form key
  final _formKey = GlobalKey<FormState>();
  // editing Controller
  final nameEditingController = TextEditingController();
  final idEditingController = TextEditingController();
  final emailEditingController = TextEditingController();
  final contactInfoController = TextEditingController();
  final hostEmailEditingController = TextEditingController();
  final hostNameEditingController = TextEditingController();
  final dayInfoController = TextEditingController();
  final venueLocationEditingController = TextEditingController();

  Future getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        {
          photo = File(pickedFile.path);
        }
      });
    }
  }

  Future uploadFile(String name) async {
    if (photo == null) return;
    try {
      await storage.ref(name).putFile(photo!);
    } catch (e) {
      if (kDebugMode) {
        print('error occurred');
      }
    }
  }

  void _showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () {
                      getImage(ImageSource.gallery);
                      Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    getImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final branchList = streamToBranchList[department]?.keys.toList() ?? [];

    final nameField = TextFormField(
        autofocus: false,
        controller: nameEditingController,
        keyboardType: TextInputType.name,
        validator: (value) {
          RegExp regex = RegExp(r'^.{3,}$');
          if (value!.isEmpty) {
            return ("First Name cannot be Empty");
          }
          if (!regex.hasMatch(value)) {
            return ("Enter Valid name(Min. 3 Character)");
          }
          return null;
        },
        onSaved: (value) {
          nameEditingController.text = value!;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.account_circle),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Name",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));

    Widget idTypeField = Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Icon(Icons.account_circle, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                  child: DropdownButton<String>(
                isExpanded: true,
                value: idTypeSelected,
                elevation: 16,
                underline: Container(
                  height: 2,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    idTypeSelected = newValue ?? "Aadhaar";
                  });
                },
                items: <String>["Aadhaar", "Driving License", "PAN", "Voter ID"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ))
            ]));

    //id
    final idField = TextFormField(
        autofocus: false,
        controller: idEditingController,
        keyboardType: TextInputType.name,
        validator: (value) {
          if (value!.isEmpty) {
            return ("ID cannot be Empty");
          }
          return null;
        },
        onSaved: (value) {
          idEditingController.text = value!;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.card_membership_sharp),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "ID",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));

    final hostName = TextFormField(
        autofocus: false,
        controller: hostNameEditingController,
        keyboardType: TextInputType.name,
        validator: (value) {
          if (value!.isEmpty) {
            return ("Host Name cannot be Empty");
          }
          return null;
        },
        onSaved: (value) {
          hostNameEditingController.text = value!;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.account_circle),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Host Name",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));

    //contact
    final contactInfo = TextFormField(
        autofocus: false,
        controller: contactInfoController,
        keyboardType: TextInputType.number,
        validator: (value) {
          RegExp regex = RegExp(r'^.{10,}$');
          if (value!.isEmpty) {
            return ("Phone Number is required for Pass");
          }
          if (!regex.hasMatch(value)) {
            return ("Enter Valid Phone number");
          }
          return null;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.phone),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Contact Information",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));

    //email field
    final emailField = TextFormField(
        autofocus: false,
        controller: emailEditingController,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value!.isEmpty) {
            return ("Please Enter Your Email");
          }
          // reg expression for email validation
          if (!RegExp("^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]")
              .hasMatch(value)) {
            return ("Please Enter a valid email");
          }
          return null;
        },
        onSaved: (value) {
          nameEditingController.text = value!;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.mail),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Email",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));
    final hostEmailField = TextFormField(
        autofocus: false,
        controller: hostEmailEditingController,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value!.isEmpty) {
            return ("Please Enter Your Email");
          }
          // reg expression for email validation
          // if (!RegExp(r"^[a-zA-Z0-9+_.-]+@iiita\.ac\.in").hasMatch(value)) {
          //   return ("Please Enter a valid email of domain iiita.ac.in");
          // }
          return null;
        },
        onSaved: (value) {
          nameEditingController.text = value!;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.mail),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Host Email Address",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));
    final venueLocation = TextFormField(
        autofocus: false,
        controller: venueLocationEditingController,
        keyboardType: TextInputType.text,
        validator: (value) {
          if (value!.isEmpty) {
            return ("Please Enter Your Visiting Location");
          }

          return null;
        },
        onSaved: (value) {
          nameEditingController.text = value!;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.location_city_sharp),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Venue Name",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));
    final days = TextFormField(
        autofocus: false,
        controller: dayInfoController,
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value!.isEmpty) {
            return ("Days Info can't be empty");
          }
          return null;
        },
        onSaved: (value) {
          dayInfoController.text = value!;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Enter number of days",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));

    final uploadImage = Center(
      child: GestureDetector(
        onTap: () {
          _showPicker(context);
        },
        child: CircleAvatar(
          radius: 55,
          backgroundColor: const Color(0xffFDCF09),
          child: photo != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.file(
                    photo!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.fill,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(50)),
                  width: 100,
                  height: 100,
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.grey[800],
                  ),
                ),
        ),
      ),
    );
    final submitButton = makeButton("Submit", submit);
    final branchField = Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Icon(Icons.school),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<String>(
              hint: const Text("Please select Branch"),
              isExpanded: true,
              value:
                  branchList.contains(_selectedBranch) ? _selectedBranch : null,
              elevation: 16,
              underline: Container(
                height: 2,
              ),
              onChanged: (String? newValue) {
                selectedMobile =
                    streamToBranchList[department]?[newValue]?[0].toString() ??
                        '';
                print(selectedMobile);
                setState(() {
                  _selectedBranch = newValue!;
                });
              },
              items: streamToBranchList[department]?.keys.map((branch) {
                return DropdownMenuItem(
                  value: branch,
                  child: Text(branch),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // passing this to our root
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    uploadImage,
                    const SizedBox(height: 20),
                    nameField,
                    const SizedBox(height: 20),
                    contactInfo,
                    const SizedBox(height: 20),
                    emailField,
                    const SizedBox(height: 20),
                    idTypeField,
                    const SizedBox(height: 20),
                    idField,
                    const SizedBox(height: 20),
                    hostName,
                    const SizedBox(height: 20),
                    hostEmailField,
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Radio<String>(
                          value: 'Diploma',
                          groupValue: department,
                          onChanged: (String? value) {
                            setState(() {
                              department = value!;
                            });
                          },
                        ),
                        const Text('Diploma'),
                        Radio<String>(
                          value: 'Degree',
                          groupValue: department,
                          onChanged: (String? value) {
                            setState(() {
                              department = value!;
                            });
                          },
                        ),
                        const Text('Degree'),
                      ],
                    ),
                    branchField,
                    const SizedBox(height: 20),
                    venueLocation,
                    const SizedBox(height: 20),
                    days,
                    const SizedBox(height: 20),
                    submitButton,
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Uploading'), backgroundColor: Colors.blue));
      postDetailsToFirestore();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Errors in form'), backgroundColor: Colors.red));
    }
  }

  postDetailsToFirestore() async {
    // calling our firestore
    // calling our user model
    // sending these values
    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    User? user = _auth.currentUser;

    PassModel passModel = PassModel();
    var uuid = const Uuid();
    passModel.passSecret = uuid.v1();
    passModel.userId = user?.uid;
    passModel.email = emailEditingController.text;
    passModel.name = nameEditingController.text;
    passModel.contactInfo = contactInfoController.text;
    passModel.idType = idTypeSelected;
    passModel.idValue = idEditingController.text;
    passModel.department = department;
    passModel.branch = _selectedBranch;
    passModel.days = int.parse(dayInfoController.text);
    passModel.hostName = hostNameEditingController.text;
    passModel.hostEmail = hostEmailEditingController.text;
    passModel.location = venueLocationEditingController.text;
    passModel.isActive = false;
    passModel.isVerified = false;

    await firebaseFirestore
        .collection("passes")
        .add(passModel.toMap())
        .then((value) => {passModel.uid = value.id});

    await Future.wait([
      firebaseFirestore.collection("users").doc(user!.uid).update({
        'passes': FieldValue.arrayUnion([passModel.uid!])
      }),
      uploadFile(passModel.uid!),
    ]);
    if (selectedMobile.isNotEmpty) {
      const bannerImageUrl =
          'https://armiet.in/wp-content/uploads/2020/08/Armiet-logo-12.png';
      final message = Uri.encodeComponent('''
Hi, you have a new visitor!
details are as follows:
Hi, I'm ${passModel.name} 👋
*I want to visit*
👨‍💼 Department: ${passModel.department}
📘 Branch: ${passModel.branch}
*My details are:*
📇 ID (${passModel.idType}): ${passModel.idValue}
📧 Email: ${passModel.email}
📞 Contact: ${passModel.contactInfo}
📍 Location: ${passModel.location}
👤 Host: ${passModel.hostName} (${passModel.hostEmail})
🕒 Valid for: ${passModel.days} day(s)

Kindly open VMS app to verify the visitor.
''');
      final url =
          "https://int.chatway.in/api/send-msg?username=Meerolabs&number=91$selectedMobile&message=$message&token=azlhZjM1dGZKclBoRHh2MlBjMkxRdz09&file_url=$bannerImageUrl&file_name=Armiet-logo-12.png";

      try {
        Dio dio = Dio();
        await dio.get(url).then((response) {
          if (response.statusCode == 200) {
            print("Message sent successfully");
          } else {
            print("Failed to send message");
          }
        });
      } catch (e) {
        print(e);
      }
    } else {
      print("Mobile No Not Selected");
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Pass created successfully!"),
        backgroundColor: Colors.green));

    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return PassScreen(passModel);
    }));
  }
}
