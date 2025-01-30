## Gitbash Windows

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
## dans le container docker
`docker-compose run flask-app flask db upgrade`

## lancer l'API Flask
`python app.py`