from flask import Blueprint

auth = Blueprint("auth", __name__)

@auth.route("/products", methods=["POST"])
def add_product():
    return "add product"