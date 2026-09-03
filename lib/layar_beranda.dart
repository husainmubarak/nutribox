import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'layar_kalkulator.dart';
import 'layar_auth.dart';

class LayarBeranda extends StatefulWidget {
  const LayarBeranda({super.key});

  @override
  State<LayarBeranda> createState() => _LayarBerandaState();
}

class _LayarBerandaState extends State<LayarBeranda> {
  bool isMemuat = true;
  String namaUser = 'Pelanggan';
  String targetDiet = '-';
  String hariIniString = '';
  
  List<dynamic> jadwalHariIni = [];
  Map<String, String> mapAlamat = {}; 
  bool adaPaketAktif = false;
  
  // TAMBAHAN: Menyimpan menu harian. Format: { 'Sarapan': 'Oatmeal...', 'Siang': 'Ayam...' }
  Map<String, String> mapMenuHariIni = {}; 

  @override
  void initState() {
    super.initState();
    ambilDataBeranda();
  }

  String dapatkanHariIni() {
    int hariKe = DateTime.now().weekday;
    switch (hariKe) {
      case 1: return 'Senin';
      case 2: return 'Selasa';
      case 3: return 'Rabu';
      case 4: return 'Kamis';
      case 5: return 'Jumat';
      case 6: return 'Sabtu';
      case 7: return 'Minggu';
      default: return 'Senin';
    }
  }

  Future<void> ambilDataBeranda() async {
    setState(() => isMemuat = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      hariIniString = dapatkanHariIni();
      
      // Ambil tanggal hari ini dengan format YYYY-MM-DD
      final tanggalHariIni = DateTime.now().toIso8601String().split('T')[0];

      // 1. Tarik profil user (termasuk target diet)
      final responseProfil = await Supabase.instance.client
          .from('users')
          .select('nama_lengkap, target_diet')
          .eq('id', user.id)
          .maybeSingle();

      if (responseProfil != null) {
        namaUser = responseProfil['nama_lengkap'] ?? 'Pelanggan';
        targetDiet = responseProfil['target_diet'] ?? 'Belum ada target';
      }

      // 2. Cek status paket aktif
      final cekPaket = await Supabase.instance.client
          .from('transaksi_langganan')
          .select('id')
          .eq('user_id', user.id)
          .eq('status_bayar', 'Lunas')
          .gte('tanggal_selesai', DateTime.now().toIso8601String())
          .maybeSingle();
          
      adaPaketAktif = cekPaket != null;

      // 3. Tarik Master Menu Harian khusus untuk target diet user ini dan hari ini
      if (targetDiet != 'Belum ada target') {
        final responseMenu = await Supabase.instance.client
            .from('master_menu_harian')
            .select('waktu_makan, nama_menu')
            .eq('tanggal', tanggalHariIni)
            .eq('target_diet', targetDiet);

        for (var menu in responseMenu) {
          mapMenuHariIni[menu['waktu_makan']] = menu['nama_menu'];
        }
      }

      // 4. Tarik daftar alamat
      final responseAlamat = await Supabase.instance.client
          .from('alamat_user')
          .select('id, label_alamat')
          .eq('user_id', user.id);

      for (var alamat in responseAlamat) {
        mapAlamat[alamat['id'].toString()] = alamat['label_alamat'];
      }

      // 5. Tarik jadwal pengiriman
      final responseJadwal = await Supabase.instance.client
          .from('jadwal_pengiriman')
          .select()
          .eq('user_id', user.id)
          .eq('hari', hariIniString);

      final urutanWaktu = {'Sarapan': 1, 'Siang': 2, 'Malam': 3};
      List<dynamic> jadwalMentah = List.from(responseJadwal);
      jadwalMentah.sort((a, b) {
        int nilaiA = urutanWaktu[a['waktu_makan']] ?? 99;
        int nilaiB = urutanWaktu[b['waktu_makan']] ?? 99;
        return nilaiA.compareTo(nilaiB);
      });

      if (mounted) {
        setState(() {
          jadwalHariIni = jadwalMentah;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat beranda: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isMemuat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriBox', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LayarAuth()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: isMemuat
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: ambilDataBeranda,
              color: Colors.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Halo, $namaUser!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('Program Aktif: $targetDiet', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pengiriman Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(hariIniString, style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),

                    jadwalHariIni.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              adaPaketAktif 
                                ? 'Tidak ada jadwal pengiriman untuk hari ini.'
                                : 'Belum ada jadwal pengiriman.\nYuk mulai langganan!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: jadwalHariIni.length,
                            itemBuilder: (context, index) {
                              final jadwal = jadwalHariIni[index];
                              final idAlamat = jadwal['alamat_id'].toString();
                              final namaAlamat = mapAlamat[idAlamat] ?? 'Alamat tidak diketahui';
                              
                              // Ambil nama menu dari map yang sudah kita tarik dari DB
                              final waktuMakan = jadwal['waktu_makan'];
                              final namaMenu = mapMenuHariIni[waktuMakan] ?? 'Menu spesial Chef (Kejutan!)';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        radius: 20,
                                        child: Icon(Icons.restaurant, color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(waktuMakan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text(namaMenu, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text('Dikirim ke: $namaAlamat', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    const SizedBox(height: 40),

                    if (adaPaketAktif)
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: const Text(
                          'Paket langganan Anda sedang aktif. Selesaikan paket saat ini untuk memesan program baru.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LayarKalkulatorGizi()));
                        },
                        child: const Text('PILIH PAKET LANGGANAN BARU', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}