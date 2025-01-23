import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    // if (!mounted) return;
    // await Navigator.of(context).push(MaterialPageRoute(
    //   builder: (_) => MobileScanner(
    //     onDetect: (barcodeCapture) {
    //       if (barcodeCapture.barcodes.isNotEmpty) {
    //         final barcode = barcodeCapture.barcodes.first;
    //         if (barcode.rawValue != null && mounted) {
    //           _fetchProductData(barcode.rawValue!);
    //           Navigator.of(context, rootNavigator: true).pop();
    //         }
    //       }
    //     },
    //   ),
    // ));
    _fetchProductData("8594001022038");
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
    TextEditingController _dateController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Entrer la DLC", style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text("Sélectionner la date"),
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null && mounted) {
                    setState(() {
                      selectedDate = pickedDate;
                      _dateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              Padding(
                key: ValueKey(selectedDate),
                padding: const EdgeInsets.only(top: 10),
                child: TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: "Date sélectionnée:",
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))
                  ),
                  readOnly: true,
                  enabled: false,
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

  void _duplicateProduct(int index) {
    setState(() {
      final duplicatedProduct = Map<String, String>.from(scannedProducts[index]);
      scannedProducts.add(duplicatedProduct);
    });
  }

  void _deleteProduct(int index) {
    setState(() {
      scannedProducts.removeAt(index);
    });
  }

  Future<void> _addManualProduct() async {
    String? productName;
    String? brand;
    String? categories;
    String? dlc;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter un produit manuellement"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Nom du produit"),
                onChanged: (value) => productName = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Marque"),
                onChanged: (value) => brand = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Catégories"),
                onChanged: (value) => categories = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "DLC (yyyy-mm-dd)"),
                onChanged: (value) => dlc = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (productName != null && dlc != null) {
                  setState(() {
                    scannedProducts.add({
                      "code": "Manuel",
                      "name": productName!,
                      "brand": brand ?? "Non spécifié",
                      "categories": categories ?? "Non spécifié",
                      "allergens": "Non spécifié",
                      "additives": "Non spécifié",
                      "dlc": dlc!,
                      "date": DateTime.now().toString(),
                    });
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text("Ajouter"),
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
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: AssetImage('assets/images/woman_fridge.jpg'),
                  fit: BoxFit.cover,
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Scanné le: ${item['date']!.split(' ')[0]}",
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: () => _duplicateProduct(index),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.lightBlueAccent,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          textStyle: const TextStyle(fontSize: 12),
                                        ),
                                        child: const Text("Dupliquer"),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: () => _deleteProduct(index),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          textStyle: const TextStyle(fontSize: 12),
                                        ),
                                        child: const Text("Supprimer"),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                ElevatedButton(
                  onPressed: _addManualProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Text(
                    "Ajouter manuellement", 
                    style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 15, 78, 20))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

