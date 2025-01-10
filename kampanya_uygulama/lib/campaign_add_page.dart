import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http; // HTTP istekleri için
import 'dart:convert';

class CampaignAddPage extends StatefulWidget {
  const CampaignAddPage({super.key});

  @override
  State<CampaignAddPage> createState() => _CampaignAddPageState();
}

class _CampaignAddPageState extends State<CampaignAddPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  File? _selectedImage;
  String? _uploadedImageUrl;
  String _errorMessage = '';

  final List<String> _categories = [
    'Elektronik',
    'Moda',
    'Gıda',
    'Market',
    'Spor',
    'Sağlık',
    'Eğlence',
    'Eğitim',
    'Seyahat',
    'Diğer'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Lütfen bir görsel seçin!';
      });
      return;
    }

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref =
          FirebaseStorage.instance.ref().child('campaign_images/$fileName');
      await ref.putFile(_selectedImage!);

      final imageUrl = await ref.getDownloadURL();
      setState(() {
        _uploadedImageUrl = imageUrl;
        _errorMessage = 'Görsel başarıyla yüklendi!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Görsel yüklenirken hata oluştu: $e';
      });
    }
  }

  Future<void> _addCampaign() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _uploadedImageUrl == null ||
        _selectedCategory == null) {
      setState(() {
        _errorMessage =
            'Lütfen tüm alanları doldurun, bir kategori seçin ve görsel ekleyin!';
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('campaigns').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': _uploadedImageUrl,
        'created_at': Timestamp.now(),
      });

      // Bildirim gönder
      await _sendNotificationToCategory(_selectedCategory!);

      setState(() {
        _errorMessage = 'Kampanya başarıyla eklendi!';
      });

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
        _uploadedImageUrl = null;
        _selectedCategory = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: ${e.toString()}';
      });
    }
  }

  Future<void> _sendNotificationToCategory(String category) async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('selectedCategories', arrayContains: category)
        .get();

    for (var userDoc in usersSnapshot.docs) {
      final fcmToken = userDoc['fcmToken'];

      if (fcmToken != null) {
        await _sendFCMNotification(
          fcmToken,
          "Yeni Kampanya!",
          "Yeni bir $category kampanyası ekledik. Hemen göz atın!",
        );
      }
    }
  }

  Future<void> _sendFCMNotification(
      String fcmToken, String title, String body) async {
    const String serverKey =
        'YOUR_SERVER_KEY_HERE'; // Firebase sunucu anahtarınız
    const String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

    try {
      final response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('FCM gönderimi başarısız: ${response.body}');
      }
    } catch (e) {
      print('FCM Hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kampanya Ekle"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kampanya Bilgileri",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Kampanya Adı",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Kampanya Açıklaması",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                items: _categories
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                decoration: InputDecoration(
                  labelText: "Kategori Seçin",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Kampanya Görseli",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Görsel Seç"),
              ),
              const SizedBox(height: 10),
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _selectedImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _uploadImage,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Görsel Yükle"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addCampaign,
                icon: const Icon(Icons.add),
                label: const Text("Kampanya Ekle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
