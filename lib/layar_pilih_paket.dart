import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'layar_alamat.dart';

class LayarPilihPaket extends StatefulWidget {
  const LayarPilihPaket({super.key});

  @override
  State<LayarPilihPaket> createState() => _LayarPilihPaketState();
}

class _LayarPilihPaketState extends State<LayarPilihPaket> {
  final _futurePaket = Supabase.instance.client
      .from('paket_langganan')
      .select()
      .order('harga', ascending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Pilih Paket Langganan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: _futurePaket,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          }
          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return const Center(child: Text('Belum ada paket tersedia.'));
          }

          final daftarPaket = snapshot.data as List<dynamic>;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: daftarPaket.length,
            itemBuilder: (context, index) {
              final paket = daftarPaket[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paket['nama_paket'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 16, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            '${paket['durasi_hari']} Hari Pengiriman',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rp ${paket['harga']}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LayarAlamat(
                                    paketId: paket['id'],
                                    namaPaket: paket['nama_paket'],
                                    hargaPaket: paket['harga'],
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'PILIH',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
    );
  }
}
