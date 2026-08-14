import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPage();
}

class _SettingPage extends State<SettingPage> {
  List setting = [
    "Security And Privacy",
    "Notfication",
    "Safe Zone",
    "GPS",
    "Camera",
    "Audio",
    "Location",
    "Accounts",
    "LogOut",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C621B),
          ),
        ),

        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(context: context, delegate: CustomSearch());
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          child: ListView.builder(
            itemCount: setting.length,
            itemBuilder: (context, i) {
              return InkWell(
                onTap: () {},
                child: Card(
                  color: Color(0xFFA5EC60),
                  child: ListTile(
                    title: Text(
                      "${setting[i]}",
                      style: TextStyle(
                        color: Color(0xFF1C621B),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF1C621B),
                    ),
                    onTap: () {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CustomSearch extends SearchDelegate {
  List setting = [
    "Security And Privacy",
    "Notfication",
    "Safe Zone",
    "GPS",
    "Camera",
    "Audio",
    "Location",
    "Accounts",
    "LogOut",
  ];
  List filterList = [];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = "";
        },
        icon: Icon(Icons.close),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Text("result");
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query == "") {
      return ListView.builder(
        itemCount: setting.length,
        itemBuilder: (context, i) {
          return InkWell(
            onTap: () {},
            child: Card(
              color: Color(0xFFA5EC60),
              child: ListTile(
                title: Text(
                  "${setting[i]}",
                  style: TextStyle(
                    color: Color(0xFF1C621B),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF1C621B),
                ),
                onTap: () {},
              ),
            ),
          );
        },
      );
    } else {
      filterList =
          setting
              .where(
                (element) => element.toLowerCase().trim().contains(
                  query.toLowerCase().trim(),
                ),
              )
              .toList();

      // filterList = setting.where((element) => element.contains(query)).toList();
      return ListView.builder(
        itemCount: filterList.length,
        itemBuilder: (context, i) {
          return InkWell(
            onTap: () {},
            child: Card(
              color: Color(0xFFA5EC60),
              child: ListTile(
                title: Text(
                  "${filterList[i]}",
                  style: TextStyle(
                    color: Color(0xFF1C621B),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF1C621B),
                ),
                onTap: () {},
              ),
            ),
          );
        },
      );
    }
  }
}
