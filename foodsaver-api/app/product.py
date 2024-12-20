from flask import Blueprint, request, jsonify
from . import db
from .models import Product, UserProduct
# from datetime import date
from flask_jwt_extended import jwt_required, get_jwt_identity

product = Blueprint("product", __name__)

@product.route("/products", methods=["POST"])
@jwt_required()
def add_product():
    data = request.get_json()
    if not data["name"] or not data["img_url"]:
        return jsonify({"msg": "Bad name or img_url"}), 400
    # Étape 1 : Ajouter le produit à la table Product
    new_product = Product(name=data["name"], img_url=data["img_url"])
    db.session.add(new_product)
    db.session.commit()  # On commite pour enregistrer le produit dans la base de données

    return new_product.serialize(), 201

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