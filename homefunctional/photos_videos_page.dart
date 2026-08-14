import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhotosPage extends StatefulWidget {
  const PhotosPage({super.key});

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _mediaList = [];
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _loadMediaFromFirestore();
  }

  Future<void> _loadMediaFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('media').get();
    setState(() {
      _mediaList = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _uploadToFirebase(XFile file, String type) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'media/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );

      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('media').add({
        'url': url,
        'type': type,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _mediaList.add({'url': url, 'type': type});
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$type uploaded successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      await _uploadToFirebase(pickedFile, 'image');
    }
  }

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      await _uploadToFirebase(pickedFile, 'video');
    }
  }

  Future<void> _captureFromCamera() async {
    final XFile? capturedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (capturedFile != null) {
      await _uploadToFirebase(capturedFile, 'image');
    }
  }

  void _showMediaPreview(Map<String, dynamic> media) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                media['type'] == 'video'
                    ? VideoPlayerWidget(url: media['url'])
                    : InteractiveViewer(
                      child: Image.network(media['url'], fit: BoxFit.contain),
                    ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMediaPreview(Map<String, dynamic> media) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showMediaPreview(media),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    media['type'] == 'video'
                        ? Image.network(
                          media['url'],
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(color: Colors.black12),
                        )
                        : Image.network(media['url'], fit: BoxFit.cover),
              ),
              if (media['type'] == 'video')
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: const Color(0xFF1C621B), size: 28),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Media Gallery",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1C621B),
        elevation: 2,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.photo,
                    tooltip: 'Select Image',
                    onPressed: _pickImage,
                  ),
                  _buildActionButton(
                    icon: Icons.videocam,
                    tooltip: 'Select Video',
                    onPressed: _pickVideo,
                  ),
                  _buildActionButton(
                    icon: Icons.camera_alt,
                    tooltip: 'Open Camera',
                    onPressed: _captureFromCamera,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _mediaList.length,
                itemBuilder: (context, index) {
                  return _buildMediaPreview(_mediaList[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.play();
        });
      });
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
        : const Center(child: CircularProgressIndicator());
  }
}
