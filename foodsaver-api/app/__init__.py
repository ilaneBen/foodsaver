import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from datetime import timedelta
from flask_swagger_ui import get_swaggerui_blueprint
from flask_cors import CORS
from flask_apscheduler import APScheduler
import psycopg2
import requests
from datetime import datetime, timedelta

# Initialisation des extensions Flask
db = SQLAlchemy()
migrate = Migrate()
cors = CORS()
scheduler = APScheduler()

# Charger les variables d'environnement
load_dotenv()

# Configuration PostgreSQL
DB_CONFIG = {
    "dbname": os.getenv("DB_NAME", "mydatabase"),
    "user": os.getenv("DB_USER", "username"),
    "password": os.getenv("DB_PASSWORD", "password"),
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", 5432)
}



def check_near_expiration():
    """ Vérifie la BDD et envoie un email si des produits expirent dans 2 jours """
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()

        target_date = (datetime.today() + timedelta(days=2)).date()

        # Correction de la requête SQL
        cursor.execute("""
            SELECT u.email, p.name_fr, up.dlc 
            FROM user_product up
            JOIN "user" u ON up.user_id = u.id
            JOIN "product" p ON up.product_id = p.id
            WHERE up.dlc = CURRENT_DATE + INTERVAL '2 days';
        """)

        products_to_notify = cursor.fetchall()
        print(f"🔍 Produits trouvés pour notification : {products_to_notify}")

        if products_to_notify:
            user_notifications = {}

            # Regrouper les produits par utilisateur
            for email, product, dlc in products_to_notify:
                if email not in user_notifications:
                    user_notifications[email] = []
                user_notifications[email].append(f"{product} (DLC : {dlc})")

            # Envoyer les emails aux utilisateurs
            for user_email, product_list in user_notifications.items():
                send_email(user_email, product_list)

        cursor.close()
        conn.close()
    except Exception as e:
        print(f"❌ Erreur dans le cron job : {e}")


SENDKIT_API_KEY = "1nbgptnu3tetvi38s6v18180ub88z9ya0x4st3uoqkyk"
SENDKIT_API_URL = "https://api.sarbacane.com/sendkit/email/send"
SENDKIT_FROM_EMAIL = "contact@foodsaver.com"
SENDKIT_FROM_NAME = "Food Saver"


def send_email(to_email, product_list):
    """ Envoie un email via Sendkit """
    email_body = ("Bonjour,\n\nVos produits suivants vont expirer dans 2 jours :\n\n"
                  + "\n".join(product_list))

    payload = {
        "to": [{"address": to_email, "personalName": "Destinataire"}],
        "msg": {
            "from": {"personalName": SENDKIT_FROM_NAME, "address": SENDKIT_FROM_EMAIL},
            "subject": "Alerte DLC : Produits bientôt périmés",
            "text": email_body,
            "html": email_body.replace("\n", "<br>")
        }
    }

    headers = {
        "Content-Type": "application/json",
        "x-apikey": SENDKIT_API_KEY
    }

    response = requests.post(SENDKIT_API_URL, json=payload, headers=headers)

    print(f"📧 Email envoyé à {to_email}: {response.status_code}, {response.text}")


# Fonction pour créer l'application Flask
def create_app():
    app = Flask(__name__)

    # Activation du CORS
    CORS(app, resources={r"/*": {"origins": "*"}})

    # Vérifier si la base de données est bien configurée
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise ValueError("⚠️ DATABASE_URL n'est pas défini dans les variables d'environnement.")

    app.config["SQLALCHEMY_DATABASE_URI"] = database_url
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    print(f"✅ DATABASE_URL: {database_url}")

    # Configuration JWT
    ACCESS_EXPIRES = timedelta(hours=1)
    app.config["JWT_ACCESS_TOKEN_EXPIRES"] = ACCESS_EXPIRES
    app.config["SECRET_KEY"] = os.environ.get("FLASK_SECRET_KEY", "default_secret")
    app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY", "default_jwt_secret")

    jwt = JWTManager(app)

    # Initialiser les extensions
    db.init_app(app)
    migrate.init_app(app, db)
    cors.init_app(app, resources={r"/*": {"origins": "*"}})

    # Swagger configuration
    SWAGGER_URL = "/swagger"
    API_URL = "/static/swagger.yaml"
    swagger_ui_blueprint = get_swaggerui_blueprint(SWAGGER_URL, API_URL)
    app.register_blueprint(swagger_ui_blueprint, url_prefix=SWAGGER_URL)

    # Importer les modèles
    from .models import User, TokenBlocklist

    # Callback pour vérifier si un JWT est dans la blocklist
    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload: dict) -> bool:
        jti = jwt_payload["jti"]
        token = db.session.query(TokenBlocklist.id).filter_by(jti=jti).scalar()
        return token is not None

    # Importer et enregistrer les routes
    from .auth import auth
    app.register_blueprint(auth, url_prefix="/")
    from .product import product
    app.register_blueprint(product, url_prefix="/")

    # Ajouter le cron job dans Flask
    scheduler.init_app(app)
    scheduler.start()
    scheduler.add_job(id="check_near_expiration", func=check_near_expiration, trigger="interval", days=1)
    print("🔄 Cron job programmé une fois par jour.")

    return app


if __name__ == "__main__":
    # Créer l'application Flask
    app = create_app()

    # Récupérer le port depuis les variables d'environnement (pour Render)
    port = int(os.environ.get("PORT", 5000))  # Port 5000 par défaut si non défini
    print(f"🚀 Serveur démarré sur le port {port}")

    # Lancer l'application
    app.run(host="0.0.0.0", port=port)
