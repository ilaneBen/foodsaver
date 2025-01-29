from flask import Blueprint, request, jsonify
from . import db
from .models import Product, UserProduct
# from datetime import date
from flask_jwt_extended import jwt_required, get_jwt_identity
import requests

product = Blueprint("product", __name__)

@product.route("/products/search", methods=["GET"])
@jwt_required()
def search_products():
    """
    Recherche des produits par code-barres ou nom en français.
    """
    barcode = request.args.get("barcode")
    name_fr = request.args.get("name_fr")
    name_en = request.args.get("name_en")

    if not barcode and not name_fr:
        return jsonify({"msg": "Veuillez fournir un 'barcode' ou un 'name_fr'"}), 400

    # Recherche par code-barres si fourni
    if barcode:
        product = Product.query.filter_by(barcode=barcode).first()
    else:
        product = Product.query.filter_by(name_fr=name_fr).first()

    if product:
        return jsonify({"product": product.serialize()}), 200
    else:
        return jsonify({"msg": "Produit introuvable."}), 404    


@product.route("/products", methods=["POST"])
@jwt_required()
def add_product():
    try:
        data = request.get_json()

        # Vérifiez que le champ obligatoire est présent
        name_fr = data.get("name_fr")
        if not name_fr:
            return jsonify({"msg": "The field 'name_fr' is required."}), 400

        # Traduire automatiquement si nécessaire
        name_en = data.get("name_en")
        if not name_en:
            name_en = translate_to_english(name_fr)

        # Vérifier si un produit avec ce code-barres existe déjà
        barcode = data.get("barcode")
        if barcode:
            existing_product = Product.query.filter_by(barcode=barcode).first()
            if existing_product:
                return jsonify({
                    "msg": "Product with this barcode already exists.",
                    "product": existing_product.serialize()
                }), 409

        # Création d'un nouvel objet produit
        new_product = Product(
            name_en=name_en,
            name_fr=name_fr,
            img_url=data.get("img_url"),
            barcode=barcode,
            brand=data.get("brand"),
            categories=data.get("categories")
        )

        # Ajouter et valider
        db.session.add(new_product)
        db.session.flush()  # Générer l'ID sans valider les changements
        product_id = new_product.id  # Récupérer l'ID généré
        db.session.commit()  # Valider l'ajout

        print(f"Produit créé avec l'ID : {product_id}")

        return jsonify({
            "msg": "Product added successfully",
            "id": product_id,
            "product": new_product.serialize()
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"msg": f"An error occurred: {str(e)}"}), 500


def translate_to_english(text):
    """
    Traduit le texte en anglais en utilisant l'API Google Translate.
    """
    try:
        url = "https://translate.googleapis.com/translate_a/single"
        params = {
            "client": "gtx",
            "sl": "fr",
            "tl": "en",
            "dt": "t",
            "q": text
        }
        response = requests.get(url, params=params)
        if response.status_code == 200:
            # L'API retourne une liste imbriquée contenant la traduction
            translation = response.json()[0][0][0]
            return translation
        else:
            print(f"Erreur de traduction: {response.status_code}")
            return None  # Retourne None si la traduction échoue
    except Exception as e:
        print(f"Erreur lors de l'appel à l'API de traduction: {e}")
        return None  # Retourne None si une erreur survient



@product.route("/products", methods=["GET"])
@jwt_required()
def get_products():
    products = Product.query.all()
    return jsonify([product.serialize() for product in products]), 200

@product.route("/user/products", methods=["POST"])
@jwt_required()
def add_user_product():
    data = request.get_json()

    user_id = get_jwt_identity()

    # Vérifier les champs requis
    if not data.get("product_id") or not data.get("dlc"):
        return jsonify({"msg": "product_id et dlc sont obligatoires"}), 400

    # Vérifier si le produit existe
    product = Product.query.get(data["product_id"])
    if not product:
        return jsonify({"msg": "Produit introuvable"}), 404

    # Ajouter le produit à user/products
    new_user_product = UserProduct(
        user_id=user_id,
        product_id=data["product_id"],
        dlc=data["dlc"],
    )
    db.session.add(new_user_product)
    db.session.commit()

    return jsonify({"msg": "Produit ajouté avec succès à user/products"}), 201

@product.route("/user/products", methods=["GET"])
@jwt_required()
def get_user_products():
    """
    Récupérer les produits associés à l'utilisateur connecté.
    """
    user_id = get_jwt_identity()  # Récupérer l'ID de l'utilisateur connecté à partir du token

    try:
        # Filtrer les produits associés à l'utilisateur
        user_products = UserProduct.query.filter_by(user_id=user_id).all()

        if not user_products:
            return jsonify({"msg": "Aucun produit trouvé pour cet utilisateur."}), 404

        # Sérialiser les produits et retourner la réponse
        return jsonify([{
            "id": user_product.id,
            "product_id": user_product.product_id,
            "name_fr": user_product.product.name_fr,  # Supposez que vous avez une relation avec `Product`
            "name_en": user_product.product.name_en,  # Supposez que vous avez une relation avec `Product`
            "dlc": user_product.dlc,
            "brand": user_product.product.brand,
            "categories": user_product.product.categories
        } for user_product in user_products]), 200

    except Exception as e:
        return jsonify({"msg": f"Une erreur s'est produite : {str(e)}"}), 500
    
@product.route("/user/products/<int:id>", methods=["DELETE"])
@jwt_required()
def delete_user_product(id):
    """
    Supprimer un produit spécifique associé à l'utilisateur connecté.
    """
    user_id = get_jwt_identity()  # Récupérer l'ID de l'utilisateur connecté à partir du token

    try:
        # Rechercher le produit spécifique lié à l'utilisateur
        user_product = UserProduct.query.filter_by(user_id=user_id, id=id).first()

        if not user_product:
            return jsonify({"msg": "Produit introuvable ou non associé à cet utilisateur."}), 404

        # Supprimer le produit
        db.session.delete(user_product)
        db.session.commit()

        return jsonify({"msg": "Produit supprimé avec succès."}), 200

    except Exception as e:
        return jsonify({"msg": f"Une erreur s'est produite : {str(e)}"}), 500
    
@product.route("/user/products/duplicate/<int:id>", methods=["POST"])
@jwt_required()
def duplicate_user_product(id):
    """
    Dupliquer un produit spécifique associé à l'utilisateur connecté.
    """
    user_id = get_jwt_identity()  # Récupérer l'ID de l'utilisateur connecté à partir du token

    try:
        # Rechercher le produit spécifique lié à l'utilisateur
        user_product = UserProduct.query.filter_by(user_id=user_id, id=id).first()

        if not user_product:
            return jsonify({"msg": "Produit introuvable ou non associé à cet utilisateur."}), 404

        # Dupliquer le produit
        # Créer une nouvelle instance en copiant les champs nécessaires
        new_user_product = UserProduct(
            user_id=user_product.user_id,
            product_id=user_product.product_id,
            dlc=user_product.dlc,  # Date limite de consommation, par exemple
            # Ajoutez d'autres champs si nécessaires
        )

        # Ajouter le nouveau produit à la session
        db.session.add(new_user_product)
        db.session.commit()

        return jsonify({"msg": "Produit dupliqué avec succès."}), 201

    except Exception as e:
        return jsonify({"msg": f"Une erreur s'est produite : {str(e)}"}), 500
