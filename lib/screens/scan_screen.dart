import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanScreen extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  static const String id = 'scan_screen';

  const ScanScreen({required this.onBarcodeScanned, Key? key}) : super(key: key);

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<Map<String, String>> scannedProducts = [];

  Future<void> _scanBarcode() async {
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MobileScanner(
        onDetect: (barcodeCapture) {
          if (barcodeCapture.barcodes.isNotEmpty) {
            final barcode = barcodeCapture.barcodes.first;
            if (barcode.rawValue != null && mounted) {
              _fetchProductData(barcode.rawValue!);
              Navigator.of(context, rootNavigator: true).pop();
            }
          }
        },
      ),
    ));
  }

  Future<void> _fetchProductData(String barcode) async {
    if (!mounted) return;
    final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final productData = jsonDecode(response.body);
      final productName = productData['product']?['product_name'] ?? 'Produit inconnu';
      final brand = productData['product']?['brands'] ?? 'Marque inconnue';
      final categories = productData['product']?['categories'] ?? 'Non spécifié';
      final allergens = productData['product']?['allergens'] ?? 'Aucun';
      final additives = productData['product']?['additives_tags']?.join(', ') ?? 'Aucun';

      if (mounted) {
        await _showDlcDialog(barcode, productName, brand, categories, allergens, additives);
      }
    } else {
      print("Produit non trouvé.");
    }
  }

  Future<void> _showDlcDialog(String barcode, String productName, String brand, String categories, String allergens, String additives) async {
    if (!mounted) return;
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Entrer la DLC", style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null && mounted) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text("Sélectionner la date"),
              ),
              if (selectedDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Date sélectionnée: ${selectedDate.toString().split(' ')[0]}",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedDate != null && mounted) {
                  setState(() {
                    scannedProducts.add({
                      "code": barcode,
                      "name": productName,
                      "brand": brand,
                      "categories": categories,
                      "allergens": allergens,
                      "additives": additives,
                      "dlc": selectedDate.toString().split(' ')[0],
                      "date": DateTime.now().toString(),
                    });
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text("Enregistrer", style: TextStyle(color: Colors.lightBlueAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    scannedProducts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: const Text('Scanner OpenFoodFacts', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 500,
              width: 300, // Augmenter la hauteur pour une image plus grande
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: AssetImage('assets/images/woman_fridge.jpg'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: scannedProducts.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun produit scanné.",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: scannedProducts.length,
                      itemBuilder: (context, index) {
                        final item = scannedProducts[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(height: 5),
                                Text("Code: ${item['code']}", style: const TextStyle(color: Colors.black54)),
                                Text("Marque: ${item['brand']}", style: const TextStyle(color: Colors.black54)),
                                Text("Catégories: ${item['categories']}", style: const TextStyle(color: Colors.black54)),
                                Text("Allergènes: ${item['allergens']}", style: const TextStyle(color: Colors.black54)),
                                Text("Additifs: ${item['additives']}", style: const TextStyle(color: Colors.black54)),
                                Text("DLC: ${item['dlc']}", style: const TextStyle(color: Colors.black54)),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    "Scanné le: ${item['date']!.split(' ')[0]}",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: _scanBarcode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(15),
              ),
              child: const Text("Scanner un produit", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
