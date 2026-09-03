import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LayarInputMenu extends StatefulWidget {
  const LayarInputMenu({super.key});

  @override
  State<LayarInputMenu> createState() => _LayarInputMenuState();
}

class _LayarInputMenuState extends State<LayarInputMenu> {
  final _namaMenuController = TextEditingController();
  final _deskripsiController = TextEditingController();
  
  bool isMemproses = false;
  String targetDietTerpilih = 'Bulking';
  String waktuMakanTerpilih = 'Sarapan';

  final List<String> pilihanDiet = ['Bulking', 'Cutting', 'Jaga BB'];
  final List<String> pilihanWaktu = ['Sarapan', 'Siang', 'Malam'];

  Future<void> _simpanMenu() async {
    if (_namaMenuController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama menu tidak boleh kosong!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isMemproses = true);

    try {
      final tanggalHariIni = DateTime.now().toIso8601String().split('T')[0];

      // Kita pakai fungsi upsert (kalau menu untuk target dan waktu yang sama udah ada, dia bakal nge-update)
      await Supabase.instance.client.from('master_menu_harian').upsert({
        'tanggal': tanggalHariIni,
        'target_diet': targetDietTerpilih,
        'waktu_makan': waktuMakanTerpilih,
        'nama_menu': _namaMenuController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
      }, onConflict: 'id'); // Nanti kita sesuaikan constraintnya kalau perlu, sementara insert biasa/upsert

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu berhasil disimpan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Kembali ke dasbor
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan menu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isMemproses = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Menu Hari Ini', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Target Diet', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              value: targetDietTerpilih,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: pilihanDiet.map((diet) {
                return DropdownMenuItem(value: diet, child: Text(diet));
              }).toList(),
              onChanged: (val) => setState(() => targetDietTerpilih = val!),
            ),
            const SizedBox(height: 20),

            const Text('Waktu Makan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              value: waktuMakanTerpilih,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: pilihanWaktu.map((waktu) {
                return DropdownMenuItem(value: waktu, child: Text(waktu));
              }).toList(),
              onChanged: (val) => setState(() => waktuMakanTerpilih = val!),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _namaMenuController,
              decoration: const InputDecoration(
                labelText: 'Nama Menu (Cth: Ayam Bakar)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _deskripsiController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Singkat',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            isMemproses
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _simpanMenu,
                    child: const Text('SIMPAN MENU', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}