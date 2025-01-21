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
          title: const Text("Entrer la DLC"),
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
                child: const Text("Sélectionner la date"),
              ),
              if (selectedDate != null) Text("Date sélectionnée: ${selectedDate.toString().split(' ')[0]}")
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
              child: const Text("Enregistrer"),
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
      appBar: AppBar(
        title: const Text('Scanner OpenFoodFacts'),
      ),
      body: ListView.builder(
        itemCount: scannedProducts.length,
        itemBuilder: (context, index) {
          final item = scannedProducts[index];
          return ListTile(
            title: Text(item['name']!),
            subtitle: Text(
                "Code: ${item['code']}\nMarque: ${item['brand']}\nCatégories: ${item['categories']}\nAllergènes: ${item['allergens']}\nAdditifs: ${item['additives']}\nDLC: ${item['dlc']}"),
            trailing: Text(item['date']!),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        tooltip: 'Scanner',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
