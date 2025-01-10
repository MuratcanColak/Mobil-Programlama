import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kampanya_uygulama/main.dart'; // HomePage için import

class AuthPage extends StatefulWidget {
  const AuthPage({super.key}); // 'super.key' olarak güncellendi

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kontrol için TextField kontrolcüler
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';

  Future<void> _registerUser() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      // Kullanıcı başarıyla kayıt olduktan sonra Firestore'a rol bilgisi ekle
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': 'user', // Varsayılan olarak "user" rolü atanır
        });

        setState(() {
          _errorMessage = 'Kayıt başarılı!';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: ${e.toString()}';
      });
    }
  }

  Future<void> _loginUser() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Firestore'dan kullanıcının rolünü al
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc['role']; // Kullanıcının rolü (admin veya user)

          setState(() {
            _errorMessage = 'Giriş başarılı!';
          });

          // Kullanıcıyı ana sayfaya yönlendir ve rol bilgisi gönder
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HomePage(role: role), // Rol bilgisi gönderildi
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage =
                'Kullanıcı rolü bulunamadı. Lütfen yöneticinizle iletişime geçin.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kullanıcı Girişi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Şifre"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: const Text("Kayıt Ol"),
            ),
            ElevatedButton(
              onPressed: _loginUser,
              child: const Text("Giriş Yap"),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
