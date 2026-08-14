import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddReportLinkPage extends StatefulWidget {
  final String patientUID;
  final String patientName;

  const AddReportLinkPage({
    super.key,
    required this.patientUID,
    required this.patientName,
  });

  @override
  State<AddReportLinkPage> createState() => _AddReportLinkPageState();
}

class _AddReportLinkPageState extends State<AddReportLinkPage> {
  final TextEditingController urlController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  bool _isValidUrl(String url) {
    Uri? uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  Future<void> _saveReport() async {
    final url = urlController.text.trim();
    final desc = descController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the file URL')),
      );
      return;
    }
    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL (http or https)'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await firestore
          .collection('users')
          .doc(widget.patientUID)
          .collection('reports')
          .add({'url': url, 'description': desc, 'uploadedAt': DateTime.now()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report added successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add report: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    urlController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Report for ${widget.patientName}'),
        backgroundColor: const Color(0xFF1C621B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'File URL',
                border: OutlineInputBorder(),
                hintText: 'Enter the link to the report file',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C621B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                  ),
                  onPressed: _saveReport,
                  child: const Text('Add Report'),
                ),
          ],
        ),
      ),
    );
  }
}
