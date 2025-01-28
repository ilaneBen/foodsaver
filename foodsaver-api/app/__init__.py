from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv
import os
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from datetime import timedelta
from flask_swagger_ui import get_swaggerui_blueprint
from flask_cors import CORS

db = SQLAlchemy()
cors = CORS()

# Fonction pour créer l'application Flask
def create_app():
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

    # Configurer SQLAlchemy
    app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    # Configurer JWT
    app.config["JWT_ACCESS_TOKEN_EXPIRES"] = ACCESS_EXPIRES

    # Initialiser les extensions
    db.init_app(app)
    migrate = Migrate(app, db)
    jwt = JWTManager(app)
    cors.init_app(app, resources={r"/*": {"origins": "*"}})

    # Swagger configuration
    SWAGGER_URL = "/swagger"  # URL for accessing Swagger UI
    API_URL = "/static/swagger.yaml"  # Path to your Swagger spec
    swagger_ui_blueprint = get_swaggerui_blueprint(SWAGGER_URL, API_URL)
    app.register_blueprint(swagger_ui_blueprint, url_prefix=SWAGGER_URL)

    # Importer les modèles nécessaires
    from .models import User, TokenBlocklist

    # Callback pour vérifier si un JWT est dans la blocklist
    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload: dict) -> bool:
        jti = jwt_payload["jti"]
        token = db.session.query(TokenBlocklist.id).filter_by(jti=jti).scalar()
        return token is not None

    # Importer les routes
    from .auth import auth
    app.register_blueprint(auth, url_prefix="/")
    from .product import product
    app.register_blueprint(product, url_prefix="/")

    return app
