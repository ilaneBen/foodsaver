import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/screens/login_screen.dart';
import '/constants.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;

class ScanScreen extends StatefulWidget {
  static const String id = 'scan_screen';
  final Function(String)? onBarcodeScanned;

  const ScanScreen({super.key, this.onBarcodeScanned});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> scannedProducts = [];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  /// Vérifie si l'utilisateur est connecté
  Future<void> _checkAuthentication() async {
    final token = await storage.read(key: 'auth_token');

    if (token == null) {
      Navigator.pushReplacementNamed(context, LoginScreen.id);
      return;
    }
    _fetchUserProducts(token);
  }

//Affichage des produits de la table user/products deja en BDD
Future<void> _fetchUserProducts(String token) async {
  try {
    final url = Uri.parse('$apiUrl/user/products');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> products = jsonDecode(response.body);

      setState(() {
        // Convertir les produits en une liste de Map<String, dynamic>
        scannedProducts = products
            .map((product) => Map<String, dynamic>.from(product))
            .toList();

        // Trier les produits par DLC (du plus périmé au moins périmé)
        scannedProducts.sort((a, b) {
          DateTime dlcA = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(a['dlc']);
          DateTime dlcB = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(b['dlc']);
          return dlcA.compareTo(dlcB); // Trier du plus ancien au plus récent
        });
      });

      print('🔹 Produits triés : $scannedProducts');
    } else {
      print("❌ Erreur HTTP (${response.statusCode}) lors de la récupération des produits.");
    }
  } catch (e) {
    print("❌ Erreur réseau : $e");
  }
}


  //fonction de verification et enregistrement des produits dans la bdd
  Future<void> _handleProductSubmission({
    required String? barcode,
    required String nameFr,
    String? categories,
    String? brand,
    String? img_url,
    required String dlc,
  }) async {
    final token = await storage.read(key: 'auth_token');

    if (token == null) {
      print("Erreur : Token d'authentification non trouvé.");
      return;
    }

    try {
      final searchUrl = Uri.parse('$apiUrl/products/search');
      final productsUrl = Uri.parse('$apiUrl/products');
      final userProductsUrl = Uri.parse('$apiUrl/user/products');

      // Rechercher le produit dans la BDD
      final queryParameters = {
        if (barcode != null) 'barcode': barcode,
        if (nameFr.isNotEmpty) 'name_fr': nameFr,
      };

      final productResponse = await http.get(
        searchUrl.replace(queryParameters: queryParameters),
        headers: {'Authorization': 'Bearer $token'},
      );

      Map<String, dynamic>? product;
      String? productId;

      if (productResponse.statusCode == 200) {
        // Produit trouvé dans la BDD
        final responseData = jsonDecode(productResponse.body);
        product = responseData['product'];
        if (product != null && product.containsKey('id')) {
          productId = product['id'].toString();
        }
      } else if (productResponse.statusCode == 404) {
        // Produit non trouvé, vérifiez OpenFoodFacts si un code-barres est disponible
        if (barcode != null) {
          print("Produit inconnu, vérification via OpenFoodFacts.");
          final openFoodFactsUrl = Uri.parse(
              'https://world.openfoodfacts.org/api/v0/product/$barcode.json');
          final openFoodResponse = await http.get(openFoodFactsUrl);

          if (openFoodResponse.statusCode == 200) {
            final openFoodData = jsonDecode(openFoodResponse.body)['product'];
            nameFr = openFoodData['product_name'] ?? nameFr;
            brand = openFoodData['brands'] ?? brand;
            img_url = openFoodData['image_front_url'] ?? img_url;
            categories = openFoodData['categories'] ?? categories;
          } else {
            print(
                "Erreur lors de la récupération des données depuis OpenFoodFacts.");
          }
        }

        // Ajouter à la BDD des produits avec code barre ou avec ajouter manuellement
        final response = await http.post(
          productsUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'barcode': barcode,
            'name_fr': nameFr,
            'categories': categories,
            'brand': brand,
            'img_url': img_url,
          }),
        );

        if (response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          if (responseData.containsKey('id')) {
            productId = responseData['id'].toString();
            print(
                "Produit ajouté à la base de données avec succès, ID : $productId");
          } else {
            print("Erreur : L'ID du produit est absent dans la réponse.");
            return;
          }
        } else {
          print(
              "Erreur lors de l'ajout du produit dans la BDD (Code HTTP : ${response.statusCode}).");
          return;
        }
      } else {
        print(
            "Erreur lors de la recherche du produit : ${productResponse.body}");
        return;
      }

      if (productId == null) {
        print("Erreur : ID produit non récupéré ou invalide.");
        return;
      }

      // Afficher une pop up pour entrer la DLC
      final selectedDlc = await _promptDlcInput();

      // Vérifie si une valeur a été saisie
      if (selectedDlc == null) {
        // Affiche une modal si aucune valeur n'a été saisie
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Erreur"),
              content: Text("Aucune DLC saisie."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Ferme la modal
                    _promptDlcInput(); // Relance la sélection DLC
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
        return; // Arrête l'exécution si la valeur est null
      }

      // Si une valeur est saisie, vous pouvez poursuivre votre logique
      print("DLC sélectionnée : $selectedDlc");

      // Ajout dans user/products
      final userProductResponse = await http.post(
        userProductsUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'dlc': selectedDlc,
        }),
      );
      if (userProductResponse.statusCode == 201) {
        print("Produit enregistré avec succès dans user/products.");
        _fetchUserProducts(token);
        _showSuccessDialog("Produit ajouté avec succès !");
      } else {
        print(
            "Erreur lors de l'enregistrement dans user/products : ${userProductResponse.body}");
      }
    } catch (e) {
      print("Erreur lors du traitement du produit : $e");
    }
  }

//pop up pour la saisie de la date de péremption
  Future<String?> _promptDlcInput() async {
    if (!mounted) return "Error: Composant DLC Input not mounted";
    DateTime? selectedDate;
    TextEditingController _dateController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Entrer la DLC",
                  style: TextStyle(color: Colors.black)),
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
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                          _dateController.text =
                              "${pickedDate.day}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
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
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30))),
                      readOnly: true,
                      enabled: false,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Annuler"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(selectedDate);
                  },
                  child: const Text("Valider"),
                ),
              ],
            );
          },
        );
      },
    );

    return "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day}";
  }

  //fonction de duplication et suppression des produits
  Future<void> _duplicateProduct(String productId) async {
    final token = await storage.read(key: 'auth_token');

    if (token == null) {
      print("Erreur : Token d'authentification non trouvé.");
      return;
    }

    try {
      final url = Uri.parse('$apiUrl/user/products/duplicate/$productId');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 201) {
        print("Produit dupliqué avec succès.");
        _fetchUserProducts(token);
      } else {
        print(
            "Erreur lors de la duplication du produit (Code HTTP : ${response.statusCode}).");
      }
    } catch (e) {
      print("Erreur lors de la duplication du produit : $e");
    }
  }

  Future<void> _deleteProduct(String productId, int index) async {
    final token = await storage.read(key: 'auth_token');

    if (token == null) {
      print("Erreur : Token d'authentification non trouvé.");
      return;
    }

    if (productId.isEmpty) {
      print("Produit ID ou Token manquant.");
      return;
    }

    try {
      print('Suppression du produit: $productId avec le token: $token');

      final url = Uri.parse('$apiUrl/user/products/$productId');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Produit supprimé avec succès.");
        _fetchUserProducts(token);
        // Mise à jour de la liste des produits
        setState(() {
          scannedProducts.removeAt(index);
        });
      } else if (response.statusCode == 404) {
        print("Produit introuvable (Code HTTP : 404).");
      } else {
        print(
            "Erreur lors de la suppression (Code HTTP : ${response.statusCode}). Réponse : ${response.body}");
      }
    } catch (e) {
      print("Erreur lors de la suppression du produit : $e");
    }
  }

  //ajout manuel d'un produit
  Future<void> _addManualProduct() async {
    String? productName;
    String? brand;
    String? categories;
    String? barcode;

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
                decoration: const InputDecoration(labelText: "Code Barre"),
                onChanged: (value) => barcode = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (productName != null) {
                  await _handleProductSubmission(
                    barcode: barcode,
                    nameFr: productName!,
                    categories: categories,
                    brand: brand,
                    dlc: '', // DLC sera demandée plus tard
                  );
                  Navigator.of(context).pop();
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

  //ajout via scan
  void _scanBarcode() async {
    if (!mounted) return;

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MobileScanner(
        onDetect: (barcodeCapture) {
          if (barcodeCapture.barcodes.isNotEmpty) {
            final barcode = barcodeCapture.barcodes.first;
            if (barcode.rawValue != null && mounted) {
              _handleProductSubmission(
                barcode: barcode.rawValue!,
                nameFr: "", // Remplir avec un nom par défaut si nécessaire
                categories: null,
                brand: null,
                img_url: null,
                dlc: "", // Remplir avec une DLC par défaut si nécessaire
              );
              Navigator.of(context, rootNavigator: true).pop();
            }
          }
        },
      ),
    ));
    //DEBUG
    // _handleProductSubmission(
    //             barcode: "3175681186583",
    //             nameFr: "", // Remplir avec un nom par défaut si nécessaire
    //             categories: null,
    //             brand: null,
    //             img_url: null,
    //             dlc: "", // Remplir avec une DLC par défaut si nécessaire
    //           );
  }

  //pop up de confirmation
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

  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  String _formatDate(String? date) {
    if (date == null) return "Inconnu";

    try {
      // Définir le format de la chaîne de date
      final parsedDate =
          DateFormat("EEE, dd MMM yyyy HH:mm:ss").parse(date, true);
      // Retourner la date formatée
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return "Invalide"; // En cas d'erreur
    }
  }

  // Ajoutez ici votre logique de déconnexion
  void _logout() async {
    try {
      await storage.delete(key: 'auth_token'); // Suppression du token

      if (mounted) {
        Navigator.pushReplacementNamed(context, LoginScreen.id);
      }
    } catch (e) {
      print("Erreur lors de la déconnexion : $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecipes(
      String? name_en, String? dlc) async {
    if (name_en == null || dlc == null || name_en.isEmpty || dlc.isEmpty) {
      print("⚠️ Nom de l'ingrédient ou DLC invalide.");
      return [];
    }

    try {
      // Vérifier si l'ingrédient est bien formatté
      final encodedIngredient = Uri.encodeComponent(name_en);
      final url = Uri.parse(
          'https://www.themealdb.com/api/json/v1/1/filter.php?i=$encodedIngredient');

      print("🔍 URL API appelée : $url");

      // Appel à l'API
      final response = await http.get(url);
      print("📨 Réponse API : ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('meals') && data['meals'] != null) {
          print("✅ Recettes trouvées : ${data['meals']}");
          return List<Map<String, dynamic>>.from(data['meals']);
        } else {
          print("⚠️ Aucune recette trouvée pour l'ingrédient : $name_en");
        }
      } else {
        print(
            "❌ Erreur HTTP ${response.statusCode} : ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❌ Erreur lors de la récupération des recettes : $e");
    }

    return [];
  }


Future<Map<String, dynamic>?> _fetchRecipeDetails(String idMeal) async {
  final url = Uri.parse('https://www.themealdb.com/api/json/v1/1/lookup.php?i=$idMeal');

  try {
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['meals'] != null && data['meals'].isNotEmpty) {
        return data['meals'][0]; // Retourne les détails de la recette
      }
    }
  } catch (e) {
    print("❌ Erreur lors de la récupération des détails de la recette : $e");
  }

  return null; // Retourne `null` en cas d'erreur
}

int _countExpiringSoon(List<Map<String, dynamic>> scannedProducts) {
  final now = DateTime.now();
  final threeDaysLater = now.add(Duration(days: 3));

  return scannedProducts.where((item) {
    if (item['dlc'] == null) return false;

    DateTime dlc = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(item['dlc']);
    return dlc.isBefore(threeDaysLater) && dlc.isAfter(now);
  }).length;
}

int _countExpired(List<Map<String, dynamic>> scannedProducts) {
  final now = DateTime.now(); // Date actuelle

  return scannedProducts.where((item) {
    if (item['dlc'] == null) return false;

    DateTime dlc = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(item['dlc']);
    
    return dlc.isBefore(now); // Si la DLC est avant aujourd'hui, c'est périmé
  }).length;
}



void _showExpiringSoonDialog(BuildContext context) {
  final now = DateTime.now();
  final threeDaysLater = now.add(Duration(days: 3));

  List<Map<String, dynamic>> expiringProducts = scannedProducts.where((item) {
    if (item['dlc'] == null) return false;

    DateTime dlc = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(item['dlc']);
    return dlc.isBefore(threeDaysLater) && dlc.isAfter(now);
  }).toList();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Produits périmant bientôt"),
        content: expiringProducts.isEmpty
            ? Text("Aucun produit ne périme dans les 3 jours.")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: expiringProducts.map((product) {
                  return ListTile(
                    leading: product['img_url'] != null
                        ? Image.network(product['img_url'], width: 40, height: 40)
                        : Icon(Icons.fastfood),
                    title: Text(product['name_fr'] ?? "Nom inconnu"),
                    subtitle: Text("DLC: ${_formatDate(product['dlc'])}"),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer"),
          ),
        ],
      );
    },
  );
}


void _showExpiredDialog(BuildContext context) {
  final now = DateTime.now();

  List<Map<String, dynamic>> expiredProducts = scannedProducts.where((item) {
    if (item['dlc'] == null) return false;

    DateTime dlc = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(item['dlc']);
    
    return dlc.isBefore(now);
  }).toList();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Produits périmés"),
        content: expiredProducts.isEmpty
            ? Text("Aucun produit périmé.")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: expiredProducts.map((product) {
                  return ListTile(
                    leading: product['img_url'] != null
                        ? Image.network(product['img_url'], width: 40, height: 40)
                        : Icon(Icons.fastfood),
                    title: Text(product['name_fr'] ?? "Nom inconnu"),
                    subtitle: Text("DLC: ${_formatDate(product['dlc'])}"),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer"),
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
        title: const Text(
          'Scanner Foodsaver',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                _showExpiringSoonDialog(context); // Ouvre la liste des produits périmant bientôt
              },
              child: badges.Badge(
                badgeContent: Text(
                  _countExpiringSoon(scannedProducts).toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                showBadge: _countExpiringSoon(scannedProducts) > 0,
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: Colors.red,
                ),
                position: badges.BadgePosition.topEnd(top: 0, end: 0),
                child: const Icon(Icons.warning, size: 28, color: Colors.white), // Icône d'alerte
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                _showExpiredDialog(context); // Ouvre la liste des produits périmant bientôt
              },
              child: badges.Badge(
                badgeContent: Text(
                  _countExpired(scannedProducts).toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                showBadge: _countExpired(scannedProducts) > 0,
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: Colors.orange,
                ),
                position: badges.BadgePosition.topEnd(top: 0, end: 0),
                child: Icon(Icons.warning, size: 28, color: Colors.white), // Icône d'alerte
              ),
            ),
          ),
        ],
      ),

      body: FutureBuilder<String?>(
        future: _getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text("Erreur lors de la récupération du token."),
            );
          }

          return Column(
            children: [
              Expanded(
                child: scannedProducts.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun produit enregistré.",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: scannedProducts.length,
                      itemBuilder: (context, index) {
                        final item = scannedProducts[index];
                              DateTime dlc = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(item['dlc']);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child:
                          
                          Container(
                            color: Colors.white,
                            child: 
                            Column(
                              children: [
                                ExpansionTile(
                                  trailing: SizedBox.shrink(),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: item['img_url'] != null && item['img_url'].isNotEmpty
                                        ? Image.network(
                                            item['img_url'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                '${prefixImage}assets/images/defaut.jpg',
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            '${prefixImage}assets/images/defaut.jpg',
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  title: Text(item['name_fr'] ?? "Nom inconnu"),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      dlc.isBefore(DateTime.now())
                                          ? const Text(
                                              "Produit périmé",
                                              style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                                            )
                                          : Text(
                                              "DLC: ${_formatDate(item['dlc'])}",
                                              style: TextStyle(fontSize: 16),
                                            ),
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                        future: _fetchRecipes(item['name_en'] ?? '', item['dlc']),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(
                                              child: Text('Aucune recette disponible',  style: TextStyle(color: Colors.red, fontSize: 15))
                                            ); // Ne rien afficher pendant le chargement
                                          }

                                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                            return const Center(
                                              child: Text('Aucune recette disponible',  style: TextStyle(color: Colors.red, fontSize: 15))
                                            ); // Ne rien afficher pendant le chargement 
                                          }

                                          // Affichage de "Recettes" et de l'icône seulement si des recettes existent
                                          return const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Recettes',
                                                style: TextStyle(color: Colors.green, fontSize: 15),
                                              ),
                                              Icon(Icons.arrow_drop_down),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  children: [
                                    // FutureBuilder pour afficher les recettes
                                    FutureBuilder<List<Map<String, dynamic>>>(
                                      future: _fetchRecipes(item['name_en'] ?? '', item['dlc']),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        }

                                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                          return const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'Aucune recette disponible',
                                              style: TextStyle(color: Colors.red, fontSize: 15),
                                            ),
                                          );
                                        }

                                        // ExpansionTile pour afficher les recettes
                                        return Column(
                                          children: snapshot.data!.map((recipe) {
                                            return ExpansionTile(
                                              leading: Image.network(recipe['strMealThumb'], width: 50, height: 50),
                                              title: Text(recipe['strMeal'] ?? "Nom inconnu"),
                                              children: [
                                                // FutureBuilder pour afficher les détails de la recette
                                                FutureBuilder<Map<String, dynamic>?>(
                                                  future: _fetchRecipeDetails(recipe['idMeal']),
                                                  builder: (context, detailsSnapshot) {
                                                    if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                                                      return const Padding(
                                                        padding: EdgeInsets.all(8.0),
                                                        child: Center(child: CircularProgressIndicator()),
                                                      );
                                                    }

                                                    if (!detailsSnapshot.hasData || detailsSnapshot.data == null) {
                                                      return const Padding(
                                                        padding: EdgeInsets.all(8.0),
                                                        child: Text("Aucune information détaillée trouvée."),
                                                      );
                                                    }

                                                    final recipeDetails = detailsSnapshot.data!;

                                                    return Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            const Text(
                                                            "Ingrédients :",
                                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                          ),
                                                          ...List.generate(20, (index) {
                                                            final ingredient = recipeDetails['strIngredient${index + 1}'];
                                                            final measure = recipeDetails['strMeasure${index + 1}'];

                                                            if (ingredient != null && ingredient.isNotEmpty) {
                                                              return Text("$measure $ingredient");
                                                            }
                                                            return SizedBox.shrink();
                                                          }),
                                                          const Text(
                                                            "Instructions :",
                                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                          ),
                                                          Text(recipeDetails['strInstructions'] ?? "Aucune instruction disponible"),
                                                          const SizedBox(height: 10),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            )
                          )
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
                      backgroundColor: kTextColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    child: const Text("Scanner un produit",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: _addManualProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    child: const Text("Ajouter manuellement",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Ajoute un espace de 20 pixels en bas
            ],
          );
        },
      ),
    );
  }
}