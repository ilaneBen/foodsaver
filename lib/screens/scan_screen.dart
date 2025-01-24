import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/screens/login_screen.dart';
import '/constants.dart';

class ScanScreen extends StatefulWidget {
  static const String id = 'scan_screen';
  final Function(String)? onBarcodeScanned;

  const ScanScreen({super.key, this.onBarcodeScanned});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<Map<String, dynamic>> scannedProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProductsFromDatabase();
  }

  Future<void> _fetchProductsFromDatabase() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');

    if (token == null) {
      print("Erreur : Token d'authentification non trouvé.");
      return;
    }

    try {
      final url = Uri.parse('http://127.0.0.1:5000/products');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> products = jsonDecode(response.body);
        setState(() {
          scannedProducts = products
              .map((product) => Map<String, dynamic>.from(product))
              .toList();
        });
      } else {
        print(
            "Erreur lors de la récupération des produits (Code HTTP : ${response.statusCode}).");
      }
    } catch (e) {
      print("Erreur réseau lors de la récupération des produits : $e");
    }
  }

  void _logout() {
    // Ajoutez ici votre logique de déconnexion
    Navigator.pushReplacementNamed(
        context, LoginScreen.id); // Redirige vers la page de connexion
  }

  Future<void> _fetchProductData(String barcode) async {
    if (!mounted) return;

    try {
      final url = Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final productData = jsonDecode(response.body);
        final productName =
            productData['product']?['product_name'] ?? 'Produit inconnu';
        final brand = productData['product']?['brands'] ?? 'Marque inconnue';
        final categories =
            productData['product']?['categories'] ?? 'Non spécifié';
        final allergens = productData['product']?['allergens'] ?? 'Aucun';
        final additives =
            productData['product']?['additives_tags']?.join(', ') ?? 'Aucun';

        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'auth_token');

        if (token != null) {
          await _saveProductToDatabase(
            barcode: barcode,
            productName: productName,
            brand: brand,
            categories: categories,
            allergens: allergens,
            additives: additives,
          );
        } else {
          print("Token d'authentification non trouvé.");
        }
      } else {
        print("Produit non trouvé (Code HTTP : ${response.statusCode}).");
      }
    } catch (e) {
      print("Erreur lors de la récupération des données : $e");
    }
  }

  Future<void> _saveProductToDatabase({
    required String barcode,
    required String productName,
    required String brand,
    required String categories,
    required String allergens,
    required String additives,
  }) async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');

    if (token != null) {
      try {
        final saveUrl = Uri.parse('http://127.0.0.1:5000/products');
        final response = await http.post(
          saveUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'barcode': barcode,
            'name_fr': productName,
            'brand': brand,
            'categories': categories,
            'allergens': allergens,
            'additives': additives,
          }),
        );

        if (response.statusCode == 201) {
          print("Produit enregistré en BDD.");
          _showSuccessDialog("Produit ajouté avec succès !");
          await _fetchProductsFromDatabase();
        } else {
          print(
              "Erreur lors de l'enregistrement en BDD (Code HTTP : ${response.statusCode}).");
        }
      } catch (e) {
        print("Erreur lors de l'enregistrement en BDD : $e");
      }
    } else {
      print("Erreur : Token d'authentification non trouvé.");
    }
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
                decoration:
                    const InputDecoration(labelText: "DLC (yyyy-mm-dd)"),
                onChanged: (value) => dlc = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
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

                  _showSuccessDialog("Produit ajouté avec succès !");
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

  void _scanBarcode() async {
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

  Future<void> _showSuccessDialog(String message) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Succès"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: kTextColor,
        title: const Text('Scanner Foodsaver',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: _logout,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: scannedProducts.isEmpty
                ? const Center(
                    child: Text("Aucun produit scanné.",
                        style: TextStyle(color: Colors.black54, fontSize: 16)),
                  )
                : ListView.builder(
                    itemCount: scannedProducts.length,
                    itemBuilder: (context, index) {
                      final item = scannedProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(item['name_fr'] ?? "Nom inconnu"),
                          subtitle:
                              Text("Code: ${item['barcode'] ?? "Inconnu"}"),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _scanBarcode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTextColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                  child: const Text("Scanner un produit",
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
                const SizedBox(width: 50),
                ElevatedButton(
                  onPressed: _addManualProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                  child: const Text("Ajouter manuellement",
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
