import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'layar_auth.dart';

class LayarMitra extends StatefulWidget {
  const LayarMitra({super.key});

  @override
  State<LayarMitra> createState() => _LayarMitraState();
}

class _LayarMitraState extends State<LayarMitra> {
  bool isMemuat = true;
  String namaDapur = 'Memuat...';
  String hariIniString = '';
  
  // Variabel untuk menyimpan hasil rekap { "Bulking": 5, "Cutting": 3 }
  Map<String, int> rekapPesanan = {};
  int totalPorsi = 0;

  @override
  void initState() {
    super.initState();
    _ambilDataDasbor();
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

  Future<void> _ambilDataDasbor() async {
    setState(() => isMemuat = true);
    try {
      final mitraId = Supabase.instance.client.auth.currentUser!.id;
      hariIniString = dapatkanHariIni();

      // 1. Ambil Nama Dapur
      final dataDapur = await Supabase.instance.client
          .from('mitra_dapur')
          .select('nama_dapur')
          .eq('id', mitraId)
          .single();
      namaDapur = dataDapur['nama_dapur'] ?? 'Dapur Mitra';

      // 2. Ambil data User (Pelanggan) yang terhubung ke dapur ini dan punya paket aktif
      final hariIniISO = DateTime.now().toIso8601String();
      final daftarTransaksiAktif = await Supabase.instance.client
          .from('transaksi_langganan')
          .select('user_id')
          .eq('status_bayar', 'Lunas')
          .gte('tanggal_selesai', hariIniISO);

      // Buat list berisi ID user yang paketnya beneran aktif
      List<String> listUserAktif = [];
      for (var trx in daftarTransaksiAktif) {
        listUserAktif.add(trx['user_id'].toString());
      }

      // 3. Tarik jadwal pengiriman hari ini (gabung dengan tabel users untuk tahu dietnya)
      // Query ini akan otomatis mengambil target_diet dari tabel users
      final jadwalRaw = await Supabase.instance.client
          .from('jadwal_pengiriman')
          .select('''
            waktu_makan, 
            user_id,
            users!inner (target_diet),
            alamat_user!inner (mitra_id)
          ''')
          .eq('hari', hariIniString)
          .eq('alamat_user.mitra_id', mitraId); // Filter berdasarkan dapur yang menangani alamat tersebut

      // 4. Proses Rekap 
      Map<String, int> hitungSementara = {};
      int hitungTotal = 0;

      for (var jadwal in jadwalRaw) {
        final userId = jadwal['user_id'].toString();
        // Ambil target diet dari tabel users yang di-join
        final diet = jadwal['users']['target_diet'] ?? 'Tidak Diketahui';

        // Hanya hitung kalau user ini masuk di daftar langganan aktif
        if (listUserAktif.contains(userId)) {
          hitungSementara[diet] = (hitungSementara[diet] ?? 0) + 1;
          hitungTotal++;
        }
      }

      if (mounted) {
        setState(() {
          rekapPesanan = hitungSementara;
          totalPorsi = hitungTotal;
        });
      }

    } catch (e) {
      debugPrint('Error memuat dasbor mitra: $e');
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
        title: const Text('NutriBox - Mitra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _ambilDataDasbor, // Tombol refresh manual
          ),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _ambilDataDasbor,
              color: Colors.orange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      namaDapur,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Rekap Pesanan: $hariIniString',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    // KARTU TOTAL PORSI
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange.shade400]),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          const Text('TOTAL PORSI HARI INI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            '$totalPorsi',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Text('Porsi Makanan', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text('Rincian Berdasarkan Program Diet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),

                    // LIST RINCIAN PESANAN
                    rekapPesanan.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('Belum ada pesanan untuk hari ini.', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rekapPesanan.keys.length,
                            itemBuilder: (context, index) {
                              String namaDiet = rekapPesanan.keys.elementAt(index);
                              int jumlah = rekapPesanan[namaDiet]!;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 1,
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.orangeAccent,
                                    child: Icon(Icons.restaurant_menu, color: Colors.white),
                                  ),
                                  title: Text(namaDiet, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  trailing: Text(
                                    '$jumlah Porsi',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}