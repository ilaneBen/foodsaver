from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required
from flask_jwt_extended import create_access_token, jwt_required, get_jwt
from datetime import datetime
from datetime import timezone
from .models import User, TokenBlocklist
from . import db
from flask import Flask, request, jsonify


auth = Blueprint("auth", __name__)

@auth.route("/login", methods=["POST"])
def login():
    email = request.json.get("email", None)
    password = request.json.get("password", None)
    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({"msg": "Bad email or password"}), 401

    access_token = create_access_token(identity= str(user.id))
    return jsonify(access_token=access_token)


# @auth.route("/register", methods=["POST"])
# def register():
#     email = request.json.get("email", None)
#     password = request.json.get("password", None)

#     if email is None or password is None:
#         return jsonify({"msg": "Missing email or password"}), 400 # return 400 Bad request HTTP status code
#     check_user = User.query.filter_by(email=email).first()
#     if check_user:
#         return jsonify({"msg": "Email already exists"}), 400
    
#     user = User(email=email, password=password)
#     db.session.add(user)
#     db.session.commit()

#     return jsonify({"msg": "User created successfully"}), 201

@app.route('/register', methods=['POST'])
def register():
    # Vérifier que le Content-Type est bien application/json
    if request.content_type != 'application/json':
        return jsonify({'error': 'Content-Type must be application/json'}), 415

    # Récupérer les données JSON
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Invalid JSON data'}), 400

    email = data.get('email')
    password = data.get('password')

    return jsonify({'message': f'User {email} registered successfully'}), 201

@auth.route("/logout", methods=["DELETE"])
@jwt_required()
def modify_token():
    jti = get_jwt()["jti"]
    now = datetime.now(timezone.utc)
    db.session.add(TokenBlocklist(jti=jti, created_at=now))
    db.session.commit()
    return jsonify(msg="JWT revoked")