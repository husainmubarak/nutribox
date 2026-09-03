import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'layar_jadwal.dart';

class LayarAlamat extends StatefulWidget {

  final int paketId;
  final String namaPaket;
  final int hargaPaket;

  const LayarAlamat({
    super.key,
    required this.paketId,
    required this.namaPaket,
    required this.hargaPaket,
  });

  @override
  State<LayarAlamat> createState() => _LayarAlamatState();
}

class _LayarAlamatState extends State<LayarAlamat> {
  final _labelController = TextEditingController();
  final _detailController = TextEditingController();
  
  List<dynamic> daftarAlamat = [];
  bool isMenyimpan = false;
  bool isMemuat = true;

  @override
  void initState() {
    super.initState();
    ambilDataAlamat();
  }

  Future<void> ambilDataAlamat() async {
    setState(() => isMemuat = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('alamat_user')
          .select()
          .eq('user_id', userId)
          .order('id', ascending: false);
          
      setState(() {
        daftarAlamat = response;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isMemuat = false);
    }
  }

  Future<void> simpanAlamat() async {
    if (_labelController.text.isEmpty || _detailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label dan Detail Alamat wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isMenyimpan = true);
    FocusScope.of(context).unfocus();

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      await Supabase.instance.client.from('alamat_user').insert({
        'user_id': userId,
        'label_alamat': _labelController.text,
        'alamat_lengkap': _detailController.text,
      });

      _labelController.clear();
      _detailController.clear();
      
      await ambilDataAlamat();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil disimpan!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan alamat: $e'), backgroundColor: Colors.red),
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
        title: const Text('Buku Alamat Pengiriman', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tambah Alamat Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label (Contoh: Rumah, Kantor)', 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _detailController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap', 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 15),
            isMenyimpan
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: simpanAlamat,
                    child: const Text('SIMPAN ALAMAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(thickness: 2),
            ),

            const Text('Alamat Tersimpan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            isMemuat
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : daftarAlamat.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Belum ada alamat yang disimpan.'),
                      ))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), 
                        itemCount: daftarAlamat.length,
                        itemBuilder: (context, index) {
                          final alamat = daftarAlamat[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.green),
                              title: Text(alamat['label_alamat'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(alamat['alamat_lengkap']),
                            ),
                          );
                        },
                      ),

            const SizedBox(height: 20),

            if (daftarAlamat.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LayarJadwal(daftarAlamat: daftarAlamat, paketId: widget.paketId, namaPaket: widget.namaPaket, hargaPaket: widget.hargaPaket)),
                  );
                },
                child: const Text('LANJUT ATUR JADWAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
          ],
        ),
      ),
    );
  }
}