from werkzeug.security import check_password_hash, generate_password_hash
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv
import os
from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity, get_jwt
from datetime import datetime
from datetime import timedelta
from datetime import timezone

# Charger le fichier .env
load_dotenv()

# Utiliser les variables d'environnement
MYSQL_HOST = os.getenv('MYSQL_HOST')
MYSQL_PORT = os.getenv('MYSQL_PORT')
MYSQL_USER = os.getenv('MYSQL_USER')
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD')
MYSQL_DATABASE = os.getenv('MYSQL_DATABASE')

ACCESS_EXPIRES = timedelta(hours=1)
# Créer une instance de l'application Flask
app = Flask(__name__)

app.config["SQLALCHEMY_DATABASE_URI"] = f"mysql+mysqlconnector://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DATABASE}"
app.config["JWT_SECRET_KEY"] = "generate-a-random-string"
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = ACCESS_EXPIRES

db = SQLAlchemy(app)
migrate = Migrate(app, db)
jwt = JWTManager(app)


class TokenBlocklist(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    jti = db.Column(db.String(36), nullable=False, index=True)
    created_at = db.Column(db.DateTime, nullable=False)

class User(db.Model):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)

    def __init__(self, email, password):
        self.email = email
        self.password = generate_password_hash(password) # hash the password

    def check_password(self, password):
        return check_password_hash(self.password, password) 

# Route pour la page d'accueil
@app.route('/')
def home():
    # u = User()
    return "Bienvenue sur mon application Flask !"


@app.route("/login", methods=["POST"])
def login():
    email = request.json.get("email", None)
    password = request.json.get("password", None)
    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({"msg": "Bad email or password"}), 401

    access_token = create_access_token(identity=email)
    return jsonify(access_token=access_token)

@app.route("/register", methods=["POST"])
def register():
    email = request.json.get("email", None)
    password = request.json.get("password", None)

    if email is None or password is None:
        return jsonify({"msg": "Missing email or password"}), 400 # return 400 Bad request HTTP status code
    check_user = User.query.filter_by(email=email).first()
    if check_user:
        return jsonify({"msg": "Email already exists"}), 400
    
    user = User(email=email, password=password)
    db.session.add(user)
    db.session.commit()

    return jsonify({"msg": "User created successfully"}), 201

@app.route("/protected", methods=["GET"])
@jwt_required()
def protected():
    current_user = get_jwt_identity() # get the current user
    return jsonify(logged_in_as=current_user), 200


# Callback function to check if a JWT exists in the database blocklist
@jwt.token_in_blocklist_loader
def check_if_token_revoked(jwt_header, jwt_payload: dict) -> bool:
    jti = jwt_payload["jti"]
    token = db.session.query(TokenBlocklist.id).filter_by(jti=jti).scalar()

    return token is not None

@app.route("/logout", methods=["DELETE"])
@jwt_required()
def modify_token():
    jti = get_jwt()["jti"]
    now = datetime.now(timezone.utc)
    db.session.add(TokenBlocklist(jti=jti, created_at=now))
    db.session.commit()
    return jsonify(msg="JWT revoked")

# Lancer l'application
if __name__ == '__main__':
    app.run(debug=True)