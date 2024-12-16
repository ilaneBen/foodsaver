import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner OpenFoodFacts',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> scannedProducts = [];

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        await _fetchProductData(result.rawContent);
      }
    } catch (e) {
      print("Erreur de scan: $e");
    }
  }

  Future<void> _fetchProductData(String barcode) async {
    final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final productData = jsonDecode(response.body);
      final productName = productData['product']?['product_name'] ?? 'Produit inconnu';
      final brand = productData['product']?['brands'] ?? 'Marque inconnue';
      final categories = productData['product']?['categories'] ?? 'Non spécifié';
      final allergens = productData['product']?['allergens'] ?? 'Aucun';
      final additives = productData['product']?['additives_tags']?.join(', ') ?? 'Aucun';

      await _showDlcDialog(barcode, productName, brand, categories, allergens, additives);
    } else {
      print("Produit non trouvé.");
    }
  }

  Future<void> _showDlcDialog(String barcode, String productName, String brand, String categories, String allergens, String additives) async {
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Entrer la DLC"),
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
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: const Text("Sélectionner la date"),
              ),
              if (selectedDate != null) Text("Date sélectionnée: ${selectedDate!.toLocal().toString().split(' ')[0]}")
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedDate != null) {
                  setState(() {
                    scannedProducts.add({
                      "code": barcode,
                      "name": productName,
                      "brand": brand,
                      "categories": categories,
                      "allergens": allergens,
                      "additives": additives,
                      "dlc": selectedDate!.toLocal().toString().split(' ')[0],
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
            subtitle: Text("Code: ${item['code']}\nMarque: ${item['brand']}\nCatégories: ${item['categories']}\nAllergènes: ${item['allergens']}\nAdditifs: ${item['additives']}\nDLC: ${item['dlc']}"),
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
