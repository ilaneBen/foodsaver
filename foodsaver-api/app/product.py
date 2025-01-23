from flask import Blueprint, request, jsonify
from . import db
from .models import Product, UserProduct
# from datetime import date
from flask_jwt_extended import jwt_required, get_jwt_identity
import requests

product = Blueprint("product", __name__)



@product.route("/products", methods=["POST"])
@jwt_required()
def add_product():
    try:
        # Récupérer les données de la requête JSON
        data = request.get_json()

        # Vérifier que le nom en français est présent (obligatoire)
        name_fr = data.get("name_fr")
        if not name_fr:
            return jsonify({"msg": "The field 'name_fr' is required."}), 400

        # Traduire automatiquement le nom en anglais si 'name_eng' n'est pas fourni
        name_eng = data.get("name_eng")
        if not name_eng:
            name_eng = translate_to_english(name_fr)

        # Vérifier si un code-barres est fourni
        barcode = data.get("barcode")
        if barcode:
            # Rechercher si un produit avec ce code-barres existe déjà
            existing_product = Product.query.filter_by(barcode=barcode).first()
            if existing_product:
                return jsonify({
                    "msg": "Product with this barcode already exists.",
                    "product": existing_product.serialize()
                }), 409

        # Création d'un nouvel objet produit
        new_product = Product(
            name_eng=name_eng,  # Peut être traduit ou None
            name_fr=name_fr,    # Obligatoire
            img_url=data.get("img_url"),  # Optionnel
            barcode=barcode      # Optionnel
        )

        # Ajouter le produit à la base de données
        db.session.add(new_product)
        db.session.commit()

        return jsonify({
            "msg": "Product added successfully",
            "product": new_product.serialize()
        }), 201

    except Exception as e:
        # Gestion des erreurs générales
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

    # Assurez-vous que l'utilisateur a fourni un produit_id et un dlc
    if not data.get("product_id") or not data.get("dlc"):
        return jsonify({"msg": "Missing product_id or dlc"}), 400
    
    # Récupérer l'ID de l'utilisateur à partir du token JWT
    user_id = get_jwt_identity()

    # Vérifier que le produit existe dans la base de données
    product = Product.query.get(data["product_id"])
    if not product:
        return jsonify({"msg": "Product not found"}), 404

    # Créer une nouvelle entrée dans la table UserProduct
    new_user_product = UserProduct(
        user_id=user_id,  # Utiliser l'ID de l'utilisateur du token JWT
        product_id=data["product_id"],  # ID du produit fourni dans le corps de la requête
        dlc=data["dlc"],  # Date limite de consommation fournie
    )
    
    # Ajouter l'entrée dans la base de données et valider
    db.session.add(new_user_product)
    db.session.commit()

    return jsonify({
        "msg": "Product added successfully",
        "product": product.serialize(),
        "dlc": data["dlc"]
    }), 201

@product.route("/user/products", methods=["GET"])
@jwt_required()
def get_user_products():
    user_id = get_jwt_identity()
    user_products = UserProduct.query.filter_by(user_id=user_id).all()
    return jsonify([user_product.serialize() for user_product in user_products]), 200