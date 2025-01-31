# Connected Fridge - README General

Bienvenue dans le projet **Connected Fridge**, une application permettant de gérer vos aliments de manière intuitive et intelligente grâce à une interface utilisateur conviviale et une API performante. Ce document vous guidera sur la façon de configurer et d'exécuter les parties **backend** et **frontend** de ce projet, qui sont regroupées dans un seul dépôt.

---

## Table des Matières

1. [Prérequis](#prérequis)
2. [Configuration Backend](#configuration-backend)
   - [Installation et Lancement](#installation-et-lancement)
   - [Utilisation de Docker](#utilisation-de-docker)
3. [Configuration Frontend](#configuration-frontend)
   - [Installation et Exécution](#installation-et-exécution)
4. [Contribuer](#contribuer)
5. [License](#license)

---

## Prérequis

Avant de commencer, assurez-vous d'avoir les éléments suivants installés sur votre machine :

- **Docker** : pour l'exécution et le déploiement des conteneurs backend.
- **Flutter SDK** : pour exécuter et développer le frontend.
- **Python 3** : requis pour exécuter le backend 
- **Git** : pour cloner les dépôts du projet.

### Cloner le dépôt

1. **Clonez le dépôt du projet :**
   ```bash
   git clone https://github.com/ilaneBen/foodsaver.git
   ```

---

## Configuration Backend

Le backend est une API REST développée avec Flask. Il se trouve dans le dossier `foodsaver-api` du dépôt et est conteneurisé pour une exécution simple et rapide à l'aide de Docker.

### Installation et Lancement

1. **Accédez au dossier backend :**
   ```bash
   cd foodsaver-api
   ```

2. **Copiez le fichier `.env.example` :**
   ```bash
   cp .env.example .env
   ```
   Remplissez les variables d'environnement selon vos besoins.

3. **Installez les dépendances (optionnel sans Docker) :**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

### Utilisation de Docker

1. **Revenez à la racine du projet et exécutez Docker Compose :**
   ```bash
   docker-compose up --build
   ```

2. **L'API est disponible sur :**
   ```
   http://localhost:5000
   ```

---

## Configuration Frontend

Le frontend est développé avec **Flutter**, offrant une interface utilisateur moderne et responsive. Il se trouve à la racine du dépôt.

### Installation et Exécution

1. **Assurez-vous d'être à la racine du projet :**
   ```bash
   cd ../
   ```

2. **Installez les dépendances Flutter :**
   ```bash
   flutter pub get
   ```

3. **Lancez l'application sur l'appareil de votre choix :**

   - **Pour le web :**
     ```bash
     flutter run -d chrome
     ```

   - **Pour Android :**
     ```bash
     flutter run -d emulator-5554
     ```

   - **Pour iOS :**
     ```bash
     flutter run -d <device-id>
     ```

---

## Contribuer

1. **Forkez le dépôt.**
2. **Créez une nouvelle branche :**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Effectuez vos modifications et committez :**
   ```bash
   git commit -m 'Add some feature'
   ```
4. **Poussez vos modifications :**
   ```bash
   git push origin feature/your-feature-name
   ```
5. **Ouvrez une Pull Request.**

Merci de contribuer au projet **Connected Fridge** !

---

## License

Ce projet est sous licence [MIT](LICENSE).

---
## Documentation annexe

[Documentation du projet](#https://docs.google.com/document/d/10WK1TIf48ZmF6MZunEQcbuqjy8V09d_elKhwGRWMXCQ/edit?usp=sharing) (cahier des charges, budget, mode d emploi, ...)
[Slide de présentation](#https://docs.google.com/presentation/d/1JxPr1LYyJETx1AS_mChZM3OzcLFEZHRMet7D79T-RqI/edit?usp=sharing) du projet 
