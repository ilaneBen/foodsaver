## Lancer sans Docker

## Créer l'environnement virtuel Python 
`python -m venv .venv`

## Activer l'environnement virtuel
`source .venv/Scripts/activate` ou sous linux 'source .venv/bin/activate'

## Installer les dépendances
`pip install -r requirements.txt`

## Créer et remplir le ficher .env
`cp .env.example .env`

## Créer la base de donnée MySql ou utiliser Docker avec le fichier compose.yaml

## Créer les tables
`flask db upgrade`

## lancer l'API Flask
`python app.py`

### DOCKER

## Detruire tous les image docker trainant
`compose docker down`

## Installer les dépendances (pour eviter d'erreur dans interface visuel)
`pip install -r requirements.txt`

## Recreer l'image docker en lancant l'instalation des dependances
`docker compose up --build`

## Lancer les migration
`docker compose stop`
`docker-compose run flask-app flask db upgrade`

## Re Demarer le docker
`docker compose up`