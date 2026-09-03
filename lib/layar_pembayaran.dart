import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'layar_kalkulator.dart'; 

class LayarPembayaran extends StatefulWidget {
  const LayarPembayaran({super.key});

  @override
  State<LayarPembayaran> createState() => _LayarPembayaranState();
}

class _LayarPembayaranState extends State<LayarPembayaran> {
  bool isMemproses = false;
  String metodePembayaran = 'Transfer Bank';

  Future<void> prosesPembayaran() async {
    setState(() => isMemproses = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Simulasi ID paket dan harga (Nanti datanya dioper dari layar Pilih Paket)
      const int dummyPaketId = 1; 
      const int dummyHarga = 500000;

      // Simpan riwayat transaksi ke database
      await Supabase.instance.client.from('transaksi_langganan').insert({
        'user_id': userId,
        'paket_id': dummyPaketId,
        'total_harga': dummyHarga,
        'status_bayar': 'Menunggu Konfirmasi',
      });

      if (mounted) {
        // Tampilkan pop-up sukses
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Pesanan Berhasil!', textAlign: TextAlign.center),
            content: const Text(
              'Terima kasih! Jadwal pengiriman makanan sehat Anda sudah kami terima. Silakan selesaikan pembayaran.',
              textAlign: TextAlign.center,
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(45)
                ),
                onPressed: () {
                  // Kembali ke layar paling awal (Kalkulator/Beranda) dan hapus riwayat layar sebelumnya
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LayarKalkulatorGizi()),
                    (route) => false,
                  );
                },
                child: const Text('KEMBALI KE BERANDA', style: TextStyle(color: Colors.white), textAlign: TextAlign.center,),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaksi gagal: $e'), backgroundColor: Colors.red),
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
        title: const Text('Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ringkasan Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paket Langganan', style: TextStyle(fontSize: 16)),
                        Text('Rp 500.000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ongkos Kirim', style: TextStyle(fontSize: 16)),
                        Text('Gratis', style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Bayar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Rp 500.000', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            DropdownButtonFormField<String>(
              value: metodePembayaran,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Transfer Bank', child: Text('Transfer Bank (BCA/Mandiri)')),
                DropdownMenuItem(value: 'E-Wallet', child: Text('E-Wallet (GoPay/OVO)')),
              ],
              onChanged: (val) => setState(() => metodePembayaran = val!),
            ),

            const Spacer(),

            isMemproses
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: prosesPembayaran,
                    child: const Text('BAYAR SEKARANG', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}