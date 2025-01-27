# Connected Fridge Flutter Frontend

This repository contains the frontend for the **Connected Fridge** project, developed using Flutter. The application allows users to interact with a backend system, enabling features such as login, scanning items, and managing fridge content.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Running the App](#running-the-app)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Features

- User authentication (login functionality).
- Integration with a backend API.
- Scanning functionality for managing fridge content.
- Interactive and responsive UI.
- Loading indicators and error handling.

---

## Requirements

- **Flutter SDK**: 3.x or later
- **Dart SDK**: 2.x or later
- A running backend server for API interactions ([backend repository link](#)).

### Dependencies
The following dependencies are used in this project:

- `http`: For API communication.
- `loading_overlay`: For showing loading indicators.
- `provider`: For state management (if applicable).

---

## Installation

### Step 1: Clone the Repository
```bash
$ git clone https://github.com/ilaneBen/foodsaver.git
$ cd foodsaver
```

### Step 2: Install Dependencies
```bash
$ flutter pub get
```

---

## Project Structure

```plaintext
lib/
├── components/            # Reusable widgets and UI components
├── constants.dart         # App-wide constants (e.g., API URLs)
├── main.dart              # Entry point of the application
├── screens/               # Individual screens (e.g., Login, Scan, Home)
```

---

## Configuration

Ensure the backend server is running and accessible. To start the backend server:
```bash
$ flask run --host=0.0.0.0 --port=5000
```


---

## Running the App

To run the application on a specific device:

### For Web:
```bash
$ flutter run -d chrome
```

### For Android:
```bash
$ flutter run -d emulator-5554
```

### For iOS:
```bash
$ flutter run -d <device-id>
```

---

## Contributing

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature-name`).
3. Commit your changes (`git commit -m 'Add some feature'`).
4. Push to the branch (`git push origin feature/your-feature-name`).
5. Open a Pull Request.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contact

For inquiries or issues, please contact:

- **Ilane**
- Email: [your-email@example.com](mailto:your-email@example.com)

---

Thank you for contributing to the Connected Fridge project!

