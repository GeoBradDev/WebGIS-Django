# WebGIS-Django 🛰️

A backend starter template for building full-stack WebGIS applications using **Django**, **Django Ninja**, and **Django Allauth**. Designed to work seamlessly with a companion [React frontend](https://github.com/GeoBradDev/WebGIS-React), this project provides a fully integrated geospatial platform for modern web development.

---

## ⚡ Quick Start

Use the included [`bootstrap.sh`](scripts/bootstrap.sh) script to set up the entire development stack in minutes.

### 🛠 Prerequisites

Ensure you have the following software installed:

- PostgreSQL + PostGIS (v14+)
- Python 3.10+
- Node.js and npm
- Git
- sudo privileges

---

## 🚀 Bootstrap Setup (Recommended)

Run the following command in your terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/GeoBradDev/WebGIS-Django/main/scripts/bootstrap.sh)
````

This script performs the following:

* ✅ Verifies required tools are installed
* ✅ Installs system packages (PostgreSQL, PostGIS, Python build tools)
* ✅ Configures PostgreSQL and creates PostGIS-enabled database
* ✅ Clones both frontend and backend repositories
* ✅ Sets up Python virtual environment
* ✅ Installs backend Python dependencies
* ✅ Creates `.env` for Django environment variables
* ✅ Runs migrations and creates a Django superuser
* ✅ Installs frontend Node dependencies
* ✅ Generates `render.yaml` for cloud deployment via [Render](https://render.com)

---

## 🧰 Tech Stack

### Backend

* **Django 5.2** – High-level Python web framework
* **Django Ninja** – Fast API framework built on Pydantic
* **Django Allauth** – User authentication and registration (headless)
* **PostGIS** – Spatial database extensions for PostgreSQL
* **Uvicorn** – ASGI development server
* **Gunicorn** – Production WSGI server
* **Whitenoise** – Static file serving for production environments

### Frontend (in companion repo)

* **React** + **Vite**
* RESTful API integration using token-based auth

👉 [GeoBradDev/WebGIS-React](https://github.com/GeoBradDev/WebGIS-React)

---

## 📦 Python Dependencies

Some key packages included:

| Package               | Purpose                                      |
| --------------------- | -------------------------------------------- |
| `django-ninja`        | Fast and type-safe API framework             |
| `django-allauth`      | User authentication and registration         |
| `dj-database-url`     | Easy DB configuration using URL strings      |
| `psycopg2-binary`     | PostgreSQL/PostGIS database driver           |
| `python-dotenv`       | Manage environment variables via `.env` file |
| `gunicorn`, `uvicorn` | Web server deployment                        |
| `whitenoise`          | Static file handling                         |
| `nltk`, `numpy`       | Optional natural language + numeric tooling  |

View `requirements.txt` for the complete list.

---

## 🔐 Default Admin Access

Once setup completes, the Django superuser account is:

```
Username: admin
Password: adminpass
Email: admin@example.com
URL: http://localhost:8000/admin
```

> You can change these credentials in the `bootstrap.sh` configuration section.

---

## 🌍 Deployment via Render

The setup script generates a `render.yaml` with preconfigured services for:

* Frontend (React/Vite, static site)
* Backend (Django/PostGIS, auto migrations)
* Optional cron job for automated tasks
* Database (PostgreSQL + PostGIS)

### To deploy:

1. Push frontend/backend repos to your GitHub
2. Update the `render.yaml` URLs
3. Connect to [Render](https://render.com) and import your repo

---

## 🧪 Running Tests

To run backend tests using `pytest`:

```bash
pytest
```

---

## 🛠 Development Tips

### Activate virtual environment

```bash
source .venv/bin/activate
```

### Run Django development server

```bash
cd WebGIS-Django
python manage.py runserver
```

### Start React frontend

```bash
cd WebGIS-React
npm run dev
```

---

## 📁 Project Structure

```
WebGIS-Django/
├── api/               # Django Ninja API routes
├── core/              # Django settings and URLs
├── templates/         # Template files (email, admin overrides)
├── static/            # Static files (optional)
├── media/             # Uploaded media (optional)
├── .env               # Environment variables (auto-generated)
├── render.yaml        # Deployment config for Render.com
└── manage.py          # Django management tool
```

---

## 🧭 Related Projects

* [GeoBradDev/WebGIS-React](https://github.com/GeoBradDev/WebGIS-React) – Companion frontend repo

---

## 📄 License

MIT © [GeoBrad.dev](https://geobrad.dev)