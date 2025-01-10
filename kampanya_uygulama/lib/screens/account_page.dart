import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kampanya_uygulama/screens/campaign_detail_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Kullanıcı giriş yapmamış.");
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim"),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text("Kullanıcı bilgileri yüklenemedi."),
            );
          }

          final userData = snapshot.data!;
          final profileImageUrl = userData['profileImageUrl'];

          return SingleChildScrollView(
            child: Column(
              children: [
                // Arka plan ve profil alanı
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 150,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -60, // Avatarın yukarı taşınması
                      left: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 80, // Avatar boyutu
                        backgroundColor:
                            Colors.black, // Çerçeve için beyaz arka plan
                        child: CircleAvatar(
                          radius: 75, // İçteki resim boyutu
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          backgroundColor:
                              Colors.grey[200], // Görsel yoksa arka plan
                          child: profileImageUrl == null
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70), // Avatarın altındaki boşluk

                // Kullanıcı bilgileri
                Text(
                  userData['username'] ?? 'Kullanıcı Adı Yok',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Profil Düzenle butonu
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfilePage()),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Profili Düzenle"),
                ),
                const SizedBox(height: 30),

                // Kaydettiklerim ve Yorumlarım alanı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureCard(
                        context,
                        icon: Icons.bookmark,
                        title: "Kaydettiklerim",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FavoritesPage()),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.comment,
                        title: "Yorumlarım",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CommentsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Ayarlar butonu
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text("Ayarlar"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 150,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// FavoritesPage
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Future<void> _removeFavorite(String campaignId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(campaignId)
            .delete();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Favorilerden kaldırıldı.")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Favorilerden kaldırma başarısız: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kaydettiklerim"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('favorites')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz bir favori eklenmedi."));
          }

          final favoriteCampaigns = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favoriteCampaigns.length,
            itemBuilder: (context, index) {
              final campaign = favoriteCampaigns[index];
              return Card(
                child: ListTile(
                  title: Text(campaign['title']),
                  subtitle: Text(campaign['description']),
                  leading: campaign['imageUrl'] != null
                      ? Image.network(campaign['imageUrl'], width: 50)
                      : const Icon(Icons.image),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _removeFavorite(campaign.id);
                    },
                  ),
                  onTap: () {
                    // Detay sayfasına yönlendirme
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CampaignDetailPage(
                          campaignId: campaign.id,
                          title: campaign['title'],
                          description: campaign['description'],
                          imageUrl: campaign['imageUrl'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// CommentsPage
class CommentsPage extends StatelessWidget {
  const CommentsPage({super.key});

  Future<void> _deleteComment(String commentId, String campaignId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('campaigns')
            .doc(campaignId)
            .collection('comments')
            .doc(commentId)
            .delete();

        // Kullanıcıya bilgi ver
        debugPrint("Yorum başarıyla silindi.");
      } catch (e) {
        debugPrint("Yorum silinirken hata oluştu: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text("Kullanıcı giriş yapmamış."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yorumlarım"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('comments')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Hata: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.size == 0) {
            return const Center(child: Text("Henüz bir yorum yapmadınız."));
          }

          final userComments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: userComments.length,
            itemBuilder: (context, index) {
              final comment =
                  userComments[index].data() as Map<String, dynamic>;
              final campaignId =
                  userComments[index].reference.parent.parent!.id;
              final commentId = userComments[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    comment['campaignTitle'] ?? 'Kampanya Bilgisi Yok',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['comment'] ?? 'Yorum içeriği yok',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tarih: ${comment['createdAt'] != null ? (comment['createdAt'] as Timestamp).toDate().toString() : 'Bilinmiyor'}",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteComment(commentId, campaignId),
                  ),
                  onTap: () async {
                    try {
                      // Kampanya detaylarını Firestore'dan al
                      final campaignDoc = await FirebaseFirestore.instance
                          .collection('campaigns')
                          .doc(campaignId)
                          .get();

                      if (campaignDoc.exists) {
                        final campaignData = campaignDoc.data()!;

                        // Kampanya detay sayfasına yönlendirme
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CampaignDetailPage(
                              campaignId: campaignId,
                              title: campaignData['title'] ??
                                  'Kampanya Başlığı Yok',
                              description: campaignData['description'] ??
                                  'Açıklama bulunamadı.',
                              imageUrl: campaignData['imageUrl'],
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Kampanya bulunamadı.")),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Hata: $e")),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// SettingsPage
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _changePassword(BuildContext context) async {
    // Şifre değiştirme işlemleri (uygun bir dialog eklenebilir)
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Şifre değiştirme bağlantısı e-postanıza gönderildi.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("E-posta bulunamadı. Giriş yapmayı kontrol edin.")),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // Hesabı silme işlemleri
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hesap başarıyla silindi.")),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    // Gizlilik sözleşmesi
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gizlilik Sözleşmesi"),
        content: const SingleChildScrollView(
          child: Text("Buraya gizlilik sözleşmesinin içeriği yazılacak."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    // Kullanıcı sözleşmesi
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kullanıcı Sözleşmesi"),
        content: const SingleChildScrollView(
          child: Text("Buraya kullanıcı sözleşmesinin içeriği yazılacak."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    // Hakkında bilgileri
    showAboutDialog(
      context: context,
      applicationName: "Kampanya Uygulaması",
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(Icons.campaign, size: 50),
      children: const [
        Text(
            "Bu uygulama, kampanya oluşturma ve paylaşma amacıyla geliştirilmiştir."),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Şifre Değiştir"),
            onTap: () => _changePassword(context),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("Hakkında"),
            onTap: () => _showAbout(context),
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text("Kullanıcı Sözleşmesi"),
            onTap: () => _showTermsOfService(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Gizlilik Sözleşmesi"),
            onTap: () => _showPrivacyPolicy(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text("Hesabı Sil"),
            onTap: () => _deleteAccount(context),
          ),
          const Divider(), // Ayrım çizgisi
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text("Oturumu Kapat"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Mevcut profil resmini Firestore'dan yükle
  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        _profileImageUrl = userDoc['profileImageUrl'] as String?;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_imageFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Firebase Storage'a yükleme
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');
      await ref.putFile(_imageFile!);

      // URL'yi alma
      final imageUrl = await ref.getDownloadURL();

      // Firestore'da güncelleme
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileImageUrl': imageUrl,
      });

      setState(() {
        _profileImageUrl = imageUrl;
        _imageFile = null; // Geçici dosyayı sıfırla
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil resmi güncellendi!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  Future<void> _deleteProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Firebase Storage'dan sil
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');
      await ref.delete();

      // Firestore'dan URL'yi kaldır
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileImageUrl': FieldValue.delete(),
      });

      setState(() {
        _profileImageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil resmi silindi!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profili Düzenle"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profil Resmi
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : const AssetImage('assets/default_avatar.png')),
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Profil Resmini Güncelle
              ElevatedButton.icon(
                onPressed: _uploadProfileImage,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Profil Resmini Güncelle"),
              ),

              // Profil Resmini Sil
              if (_profileImageUrl != null)
                ElevatedButton.icon(
                  onPressed: _deleteProfileImage,
                  icon: const Icon(Icons.delete),
                  label: const Text("Profil Resmini Sil"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),

              const Divider(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
