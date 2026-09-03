import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'layar_pilih_paket.dart';
import 'layar_auth.dart';

class LayarKalkulatorGizi extends StatefulWidget {
  const LayarKalkulatorGizi({super.key});

  @override
  State<LayarKalkulatorGizi> createState() => _LayarKalkulatorGiziState();
}

class _LayarKalkulatorGiziState extends State<LayarKalkulatorGizi> {
  final _formKey = GlobalKey<FormState>();
  final _tglLahirController = TextEditingController();
  
  String namaLengkap = '';
  String gender = 'L';
  DateTime? tanggalLahir; 
  int umur = 0;
  double beratBadan = 65;
  double tinggiBadan = 170;
  double pengaliAktivitas = 1.2;

  bool isMenyimpan = false;

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        tanggalLahir = picked;
        _tglLahirController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        
        umur = DateTime.now().year - picked.year;
        if (DateTime.now().month < picked.month || (DateTime.now().month == picked.month && DateTime.now().day < picked.day)) {
          umur--;
        }
      });
    }
  }

  Future<void> hitungDanSimpan() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      FocusScope.of(context).unfocus();

      double tinggiMeter = tinggiBadan / 100;
      double bmi = beratBadan / (tinggiMeter * tinggiMeter);
      
      String statusBmi;
      int nilaiTarget; 
      String namaTarget; 
      
      if (bmi < 18.5) {
        statusBmi = 'Kurus';
        nilaiTarget = 500; 
        namaTarget = 'Bulking';
      } else if (bmi < 25) {
        statusBmi = 'Ideal';
        nilaiTarget = 0;
        namaTarget = 'Jaga BB';
      } else if (bmi < 30) {
        statusBmi = 'Overweight';
        nilaiTarget = -500;
        namaTarget = 'Diet';
      } else {
        statusBmi = 'Obesitas';
        nilaiTarget = -500;
        namaTarget = 'Diet';
      }

      double bmr;
      if (gender == 'L') {
        bmr = (10 * beratBadan) + (6.25 * tinggiBadan) - (5 * umur) + 5;
      } else {
        bmr = (10 * beratBadan) + (6.25 * tinggiBadan) - (5 * umur) - 161;
      }
      double tdee = bmr * pengaliAktivitas;

      int hasilKalori = (tdee + nilaiTarget).round();

      setState(() => isMenyimpan = true);

      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        await Supabase.instance.client.from('users').upsert({
          'id': userId,
          'nama_lengkap': namaLengkap,
          'gender': gender,
          'tanggal_lahir': _tglLahirController.text,
          'tinggi_badan': tinggiBadan,
          'berat_badan': beratBadan,
          'status_bmi': statusBmi, 
          'target_diet': namaTarget, 
          'tingkat_aktivitas': pengaliAktivitas.toString(),
          'target_kalori_harian': hasilKalori,
        });

        if (mounted) {
          tampilkanPopUpHasil(hasilKalori, statusBmi, namaTarget);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => isMenyimpan = false);
      }
    }
  }

  void tampilkanPopUpHasil(int kalori, String bmiStatus, String targetProgram) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Analisa Kebutuhan Gizi', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status Tubuh: $bmiStatus', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 5),
            Text('Program: $targetProgram', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 15),
            const Text('Target Kalori Harian:', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            Text('$kalori Kkal', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 10),
            const Text('Kami menyusun menu otomatis sesuai data di atas!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size.fromHeight(45)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LayarPilihPaket()),
              );
            },
            child: const Text('LANJUT PILIH PAKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Fisik', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                onSaved: (val) => namaLengkap = val!,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _tglLahirController,
                readOnly: true,
                onTap: _pilihTanggal,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir', 
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, color: Colors.green),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Pilih tanggal lahir!' : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: gender,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (val) => setState(() => gender = val!),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Berat (kg)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      initialValue: beratBadan.toString(),
                      onSaved: (val) => beratBadan = double.parse(val!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Tinggi (cm)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      initialValue: tinggiBadan.toString(),
                      onSaved: (val) => tinggiBadan = double.parse(val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<double>(
                value: pengaliAktivitas,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Aktivitas Harian', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 1.2, child: Text('Jarang Olahraga / Kerja Duduk')),
                  DropdownMenuItem(value: 1.375, child: Text('Olahraga Ringan (1-3x/minggu)')),
                  DropdownMenuItem(value: 1.55, child: Text('Olahraga Sedang (3-5x/minggu)')),
                  DropdownMenuItem(value: 1.725, child: Text('Sangat Aktif (Tiap Hari)')),
                ],
                onChanged: (val) => setState(() => pengaliAktivitas = val!),
              ),
              const SizedBox(height: 25),

              isMenyimpan
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: hitungDanSimpan,
                      child: const Text('HITUNG & SIMPAN PROFIL', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}