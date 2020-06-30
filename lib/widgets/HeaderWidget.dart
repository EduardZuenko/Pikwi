import 'package:flutter/material.dart';

AppBar header(context, {bool isAppTitle = false, String strTitle, disapearedBackButton = false}) {
  return AppBar(
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
    automaticallyImplyLeading: disapearedBackButton ? false : true,
    title: Text(
      isAppTitle ? "Pikwi" : strTitle,
      style: TextStyle(
        color: Colors.white,
        fontSize: isAppTitle ? 45.0 : 22.0,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
