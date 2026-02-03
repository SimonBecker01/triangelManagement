import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

const Color darkBG = Color.fromRGBO(88, 140, 52, 1);
const Color lightBG = Color.fromRGBO(122, 201, 67, 1);

AppBar standardAppBar = AppBar(title: Image.asset('Assets/Logo.png'), backgroundColor: darkBG,);

int userLoggedIn = 0;

List<String> childList = <String>[''];
