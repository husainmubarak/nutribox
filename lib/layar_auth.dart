import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'layar_kalkulator.dart';
import 'layar_beranda.dart'; // Tambahkan import ini

class LayarAuth extends StatefulWidget {
  const LayarAuth({super.key});

  @override
  State<LayarAuth> createState() => _LayarAuthState();
}

class _LayarAuthState extends State<LayarAuth> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool isLogin = true; 
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _cekStatusLogin();
  }

  // FUNGSI AUTO-LOGIN (Jika user buka aplikasi lagi)
  void _cekStatusLogin() {
    Future.delayed(Duration.zero, () async {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Cek profilnya, kalau lengkap ke beranda, kalau kosong ke kalkulator
        final cekProfil = await Supabase.instance.client
            .from('users')
            .select('target_diet')
            .eq('id', session.user.id)
            .maybeSingle();

        if (mounted) {
          if (cekProfil != null && cekProfil['target_diet'] != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LayarBeranda()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LayarKalkulatorGizi()),
            );
          }
        }
      }
    });
  }

  Future<void> prosesAuth() async {
    setState(() => isLoading = true);
    
    try {
      if (isLogin) {
        // --- LOGIKA JIKA USER MEMILIH MASUK (LOGIN) ---
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted && response.user != null) {
          // Cek apakah user ini sudah pernah mengisi data diet
          final cekProfil = await Supabase.instance.client
              .from('users')
              .select('target_diet')
              .eq('id', response.user!.id)
              .maybeSingle();

          if (cekProfil != null && cekProfil['target_diet'] != null) {
            // Pelanggan lama yang profilnya sudah ada -> Ke Beranda
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LayarBeranda()),
            );
          } else {
            // Pelanggan yang belum isi profil -> Ke Kalkulator
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LayarKalkulatorGizi()),
            );
          }
        }
      } else {
        // --- LOGIKA JIKA USER MEMILIH DAFTAR (REGISTER) ---
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          // User baru yang berhasil daftar langsung dipaksa ke Kalkulator
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LayarKalkulatorGizi()),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.food_bank, size: 100, color: Colors.green),
              const SizedBox(height: 10),
              const Text(
                'NutriBox',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: prosesAuth,
                      child: Text(
                        isLogin ? 'MASUK' : 'DAFTAR SEKARANG',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
              
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin
                      ? 'Belum punya akun? Daftar di sini'
                      : 'Sudah punya akun? Masuk di sini',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}