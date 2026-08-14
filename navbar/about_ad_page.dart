import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAdPage extends StatefulWidget {
  const AboutAdPage({super.key});

  @override
  State<AboutAdPage> createState() => _AboutAdPage();
}

class _AboutAdPage extends State<AboutAdPage> {
  final List<Map<String, String>> links = [
    {
      "title": "Alzheimer’s Association – About Alzheimer’s",
      "url": "https://www.alz.org/alzheimers-dementia/what-is-alzheimers",
    },
    {
      "title": "World Health Organization – Dementia",
      "url": "https://www.who.int/news-room/fact-sheets/detail/dementia",
    },
    {
      "title": "National Institute on Aging – Alzheimer’s Disease",
      "url": "https://www.nia.nih.gov/health/alzheimers",
    },
    {
      "title": "Mayo Clinic – Alzheimer’s Disease",
      "url":
          "https://www.mayoclinic.org/diseases-conditions/alzheimers-disease/symptoms-causes/syc-20350447",
    },
  ];

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----------- HEADER -----------
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF1C621B),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 38, color: Colors.white),
                      SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          "About AD Care System",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


                // ----------- DESCRIPTION -----------
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "AD Care System helps Alzheimer’s patients and their families stay organized, safe, and connected. "
                        "From medication reminders to daily routines and location tracking, our app supports both patients and caregivers with easy-to-use features.",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF1C621B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 25),

                      Text(
                        "Learn more about Alzheimer’s disease:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C621B),
                        ),
                      ),
                    ],
                  ),
                ),


                ...links.map(
                  (link) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0,horizontal: 10),
                    child: Card(
                      color: Color(0xFFE1F3DF),
                      elevation: 2,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.public, color: Color(0xFF1C621B)),
                        title: Text(
                          link['title']!,
                          style: TextStyle(
                            color: Color(0xFF1C621B),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF1C621B),
                        ),
                        onTap: () => _launchURL(link['url']!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
