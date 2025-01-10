import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CampaignEditPage extends StatefulWidget {
  final String campaignId;
  final String initialTitle;
  final String initialDescription;
  final String initialCategory;
  final String? initialImageUrl;

  const CampaignEditPage({
    super.key,
    required this.campaignId,
    required this.initialTitle,
    required this.initialDescription,
    required this.initialCategory,
    this.initialImageUrl,
  });

  @override
  State<CampaignEditPage> createState() => _CampaignEditPageState();
}

class _CampaignEditPageState extends State<CampaignEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String selectedCategory;

  File? _newImageFile;
  String? _imageUrl;
  bool _deleteImage = false;
  String _errorMessage = '';
  bool _isLoading = false; // Yükleniyor durumu

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    selectedCategory = widget.initialCategory;
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _updateCampaign() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Lütfen tüm alanları doldurun.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String? updatedImageUrl = _imageUrl;

      if (_newImageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('campaign_images')
            .child('${widget.campaignId}.jpg');
        await ref.putFile(_newImageFile!);
        updatedImageUrl = await ref.getDownloadURL();
      } else if (_deleteImage) {
        if (_imageUrl != null) {
          final ref = FirebaseStorage.instance.refFromURL(_imageUrl!);
          await ref.delete();
        }
        updatedImageUrl = null;
      }

      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaignId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': selectedCategory,
        'imageUrl': updatedImageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kampanya başarıyla güncellendi!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Hata: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
        _deleteImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kampanya Düzenle"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Kampanya Adı",
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Kampanya Açıklaması",
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Kategori Seç",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                      items: <String>[
                        'Elektronik',
                        'Moda',
                        'Gıda',
                        'Market',
                        'Sağlık',
                        'Eğitim',
                        'Seyehat',
                        'Diğer'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    if (_imageUrl != null && !_deleteImage) ...[
                      Center(
                        child: Image.network(
                          _imageUrl!,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text("Resmi Sil"),
                            onPressed: () {
                              setState(() {
                                _deleteImage = true;
                                _newImageFile = null;
                              });
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Yeni Resim Yükle"),
                            onPressed: _pickImage,
                          ),
                        ],
                      ),
                    ],
                    if (_newImageFile != null)
                      Column(
                        children: [
                          Center(
                            child: Image.file(
                              _newImageFile!,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Farklı Resim Seç"),
                            onPressed: _pickImage,
                          ),
                        ],
                      ),
                    if (_imageUrl == null && _newImageFile == null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Resim Yükle"),
                        onPressed: _pickImage,
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _updateCampaign,
                      icon: const Icon(Icons.save),
                      label: const Text("Güncelle"),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage.isNotEmpty)
                      Center(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
