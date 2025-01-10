import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kampanya_uygulama/fcm_service.dart';
import 'package:kampanya_uygulama/notification_permission_handler.dart';
import 'campaign_add_page.dart';
import 'campaign_edit_page.dart';
import 'login_page.dart';
import 'screens/campaign_detail_page.dart';
import 'screens/account_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase'i başlatıyoruz.
  await FCMService.initializeFCM();
  await NotificationPermissionHandler.requestPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kampanya Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(), // Giriş ekranı
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  final String role; // Kullanıcı rolü (admin veya user)

  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CampaignPage(
          role: widget.role), // Role bilgisi CampaignPage'e aktarılıyor
      const CategoryPage(),
      const AccountPage(),
    ];
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Sıcak Fırsatlar';
      case 1:
        return 'Kategoriler';
      case 2:
        return 'Hesap';
      default:
        return 'Kampanya Uygulaması';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          if (_currentIndex == 0 && widget.role == 'admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CampaignAddPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Kategoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hesap',
          ),
        ],
      ),
    );
  }
}

class CampaignPage extends StatefulWidget {
  final String role; // Kullanıcı rolü (admin veya user)

  const CampaignPage({super.key, required this.role});

  @override
  State<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  String selectedCategory = 'Tümü';
  String searchQuery = '';

  Future<void> _deleteCampaign(BuildContext context, String campaignId) async {
    try {
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaignId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kampanya başarıyla silindi!")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kampanya silinirken hata oluştu: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              labelText: "Arama yapın",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip("Tümü", context),
                _buildCategoryChip("Elektronik", context),
                _buildCategoryChip("Moda", context),
                _buildCategoryChip("Gıda", context),
                _buildCategoryChip("Market", context),
                _buildCategoryChip("Sağlık", context),
                _buildCategoryChip("Eğlence", context),
                _buildCategoryChip("Eğitim", context),
                _buildCategoryChip("Seyehat", context),
                _buildCategoryChip("Diğer", context),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: (selectedCategory == 'Tümü')
                ? FirebaseFirestore.instance.collection('campaigns').snapshots()
                : FirebaseFirestore.instance
                    .collection('campaigns')
                    .where('category', isEqualTo: selectedCategory)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Hiç kampanya yok!"));
              }

              final campaigns = snapshot.data!.docs.where((doc) {
                final title = doc['title'].toString().toLowerCase();
                final description = doc['description'].toString().toLowerCase();
                return title.contains(searchQuery) ||
                    description.contains(searchQuery);
              }).toList();

              if (campaigns.isEmpty) {
                return const Center(
                  child: Text("Eşleşen kampanya bulunamadı!"),
                );
              }

              return ListView.builder(
                itemCount: campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = campaigns[index];
                  final campaignId = campaign.id;

                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CampaignDetailPage(
                              title: campaign['title'],
                              description: campaign['description'],
                              imageUrl: campaign['imageUrl'],
                              campaignId: campaign.id,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (campaign['imageUrl'] != null)
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                image: DecorationImage(
                                  image: NetworkImage(campaign['imageUrl']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    campaign['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    campaign['description'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (widget.role == 'admin')
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue, size: 20),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CampaignEditPage(
                                          campaignId: campaignId,
                                          initialTitle: campaign['title'],
                                          initialDescription:
                                              campaign['description'],
                                          initialCategory: campaign['category'],
                                          initialImageUrl: campaign['imageUrl'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  onPressed: () =>
                                      _deleteCampaign(context, campaignId),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(category),
        selected: selectedCategory == category,
        onSelected: (bool selected) {
          setState(() {
            selectedCategory = selected ? category : 'Tümü';
          });
        },
      ),
    );
  }
}

// Kategoriler Sayfası
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final List<Map<String, dynamic>> categories = [
    {'name': 'Elektronik', 'icon': Icons.devices},
    {'name': 'Moda', 'icon': Icons.checkroom},
    {'name': 'Gıda', 'icon': Icons.fastfood},
    {'name': 'Market', 'icon': Icons.shopping_cart},
    {'name': 'Sağlık', 'icon': Icons.health_and_safety},
    {'name': 'Eğlence', 'icon': Icons.sports_esports},
    {'name': 'Eğitim', 'icon': Icons.school},
    {'name': 'Seyehat', 'icon': Icons.flight},
    {'name': 'Diğer', 'icon': Icons.more_horiz},
  ];

  List<String> selectedCategories = []; // Seçilen kategoriler

  @override
  void initState() {
    super.initState();
    _loadSelectedCategories(); // Seçili kategorileri yükle
  }

  Future<void> _loadSelectedCategories() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          selectedCategories =
              List<String>.from(userDoc.data()?['selectedCategories'] ?? []);
        });
      }
    }
  }

  Future<void> _saveSelectedCategories() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'selectedCategories': selectedCategories});
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });

    // Her değişiklikte otomatik kaydet
    _saveSelectedCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Üst kısım yazısı
          Container(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              "Bildirim almak istediğin kategorileri seç",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Kategoriler GridView
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index]['name'];
                  final icon = categories[index]['icon'];
                  final isSelected = selectedCategories.contains(category);

                  return GestureDetector(
                    onTap: () => _toggleCategory(category),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.orange.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.orange : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  color:
                                      isSelected ? Colors.orange : Colors.grey,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.orange
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kampanya Detay Sayfası
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Kampanya Uygulaması',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: Scaffold(
      appBar: AppBar(
        title: const Text("Kampanya Uygulaması"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('campaigns').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Kampanya bulunamadı."));
          }

          final campaigns = snapshot.data!.docs;

          return ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(campaign['title']),
                  subtitle: Text(campaign['description']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CampaignDetailPage(
                          campaignId: campaign.id, // Dinamik kampanya ID'si
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
    ),
  );
}
