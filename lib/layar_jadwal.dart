import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LayarJadwal extends StatefulWidget {
  final List<dynamic> daftarAlamat;
  
  const LayarJadwal({super.key, required this.daftarAlamat});

  @override
  State<LayarJadwal> createState() => _LayarJadwalState();
}

class _LayarJadwalState extends State<LayarJadwal> {
  final Map<String, Map<String, String?>> jadwalPengiriman = {};  
  final List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  final List<String> waktuMakan = ['Sarapan', 'Siang', 'Malam'];

  bool isMenyimpan = false;

  @override
  void initState() {
    super.initState();
    for (var h in hari) {
      jadwalPengiriman[h] = {};
      for (var w in waktuMakan) {
        jadwalPengiriman[h]![w] = null; 
      }
    }
  }

  Future<void> simpanJadwal() async {
    setState(() => isMenyimpan = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final List<Map<String, dynamic>> dataUntukDisimpan = [];

      for (var h in hari) {
        for (var w in waktuMakan) {
          final idAlamat = jadwalPengiriman[h]![w];
          if (idAlamat != null) {
            dataUntukDisimpan.add({
              'user_id': userId,
              'hari': h,
              'waktu_makan': w,
              'alamat_id': idAlamat,
            });
          }
        }
      }

      if (dataUntukDisimpan.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal satu jadwal pengiriman!'), backgroundColor: Colors.red),
        );
        setState(() => isMenyimpan = false);
        return;
      }

      await Supabase.instance.client.from('jadwal_pengiriman').delete().eq('user_id', userId);
      await Supabase.instance.client.from('jadwal_pengiriman').insert(dataUntukDisimpan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil disimpan! Lanjut ke Pembayaran.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan jadwal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isMenyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Jadwal Pengiriman', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hari.length,
              itemBuilder: (context, index) {
                final h = hari[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        const Divider(),
                        ...waktuMakan.map((w) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(w, style: const TextStyle(fontWeight: FontWeight.w500)),
                                ),
                                Expanded(
                                  // PERBAIKAN 2: Mengubah DropdownButtonFormField<int> menjadi <String>
                                  child: DropdownButtonFormField<String>(
                                    value: jadwalPengiriman[h]![w],
                                    hint: const Text('Pilih Alamat'),
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)
                                    ),
                                    // PERBAIKAN 3: Mengubah map<DropdownMenuItem<int>> menjadi <String>
                                    items: widget.daftarAlamat.map<DropdownMenuItem<String>>((alamat) {
                                      return DropdownMenuItem<String>(
                                        // Memastikan id diubah menjadi string (berjaga-jaga jika tipe datanya campuran)
                                        value: alamat['id'].toString(), 
                                        child: Text(alamat['label_alamat']),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        jadwalPengiriman[h]![w] = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: isMenyimpan
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, 
                      minimumSize: const Size.fromHeight(50)
                    ),
                    onPressed: simpanJadwal,
                    child: const Text('SIMPAN JADWAL', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
          )
        ],
      ),
    );
  }
}