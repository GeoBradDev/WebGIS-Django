#!/bin/bash
set -e  # Exit on error

# 🎯 Full-Stack Web Application Setup Script
# Combines Django backend with PostgreSQL/PostGIS and React frontend setup

echo "🚀 Starting Full-Stack Application Setup..."

# ────────────────────────── CONFIGURATION ──────────────────────────
# Database Configuration
PG_VER=14
DB_NAME="webgisdb"  # PostgreSQL converts to lowercase
DB_USER="myuser"
DB_PASS="mypassword"

# Django Configuration
DJANGO_PROJ="WebGIS"
DJANGO_SUPERUSER="admin"
DJANGO_SUPERPASS="adminpass"
DJANGO_SUPEREMAIL="admin@example.com"
PYTHON_VENV=".venv"

# Repository Configuration
FRONTEND_REPO="https://github.com/GeoBradDev/WebGIS-React.git"
BACKEND_REPO="https://github.com/GeoBradDev/WebGIS-Django.git"
FRONTEND_DIR="WebGIS-React"
BACKEND_DIR="WebGIS-Django"

# Development URLs
FRONTEND_URL="http://localhost:5173/WebGIS-React"
BACKEND_URL="http://localhost:8000"

# ────────────────────────── REQUIRED SOFTWARE CHECK ──────────────────────────
REQUIRED_TOOLS=("node" "npm" "git" "python3" "psql" "sudo")
echo "🔍 Checking for required tools..."
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "❌ Error: '$tool' is not installed. Please install it before running this script."
        exit 1
    fi
done
echo "✅ All required tools are installed."

# ────────────────────────── RENDER.YAML FOR DEPLOYMENT ──────────────────────────
echo "📝 Creating render.yaml for deployment..."

cat > render.yaml <<EOF
# render.yaml - Full-Stack Deployment Configuration
services:
  # ────────────────────────── Frontend (React + Vite) ──────────────────────────
  - name: webgis-frontend
    type: web
    runtime: static
    repo: https://github.com/YOUR_USERNAME/YOUR_FRONTEND_REPO
    branch: deploy
    autoDeploy: true
    buildCommand: npm install && npm run build
    staticPublishPath: dist
    pullRequestPreviewsEnabled: true
    healthCheckPath: /
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
    envVars:
      - key: VITE_API_URL
        value: https://webgis-backend.onrender.com/api

  # ────────────────────────── Backend (Django + PostGIS) ───────────────────────────
  - name: webgis-backend
    type: web
    plan: starter
    env: python
    region: ohio
    repo: https://github.com/YOUR_USERNAME/YOUR_BACKEND_REPO
    branch: deploy
    autoDeploy: true
    buildCommand: |
      pip install -r requirements.txt &&
      python manage.py collectstatic --no-input
    startCommand: |
      python manage.py migrate --no-input &&
      gunicorn $DJANGO_PROJ.asgi:application -k uvicorn.workers.UvicornWorker
    envVars:
      - key: SECRET_KEY
        generateValue: true
      - key: DEBUG
        value: False
      - key: CORS_ALLOWED_ORIGINS
        value: https://webgis-frontend.onrender.com

  # ────────────────────────── Cron Job (Optional Maintenance) ───────────────────────────
  - name: webgis-maintenance
    type: cron
    schedule: "0 4 * * *"  # every day at 4AM UTC
    env: python
    repo: https://github.com/YOUR_USERNAME/YOUR_BACKEND_REPO
    branch: deploy
    buildCommand: pip install -r requirements.txt
    startCommand: python manage.py cleanup_expired_data

databases:
  - name: webgis-database
    plan: basic-256mb
    region: ohio
    databaseName: webgisdb
EOF

echo "✅ render.yaml created. Update repository URLs and service names as needed."

# ────────────────────────── SYSTEM DEPENDENCIES ──────────────────────────
echo "🔧 Installing system dependencies..."
sudo apt update
sudo apt install -y postgresql-$PG_VER postgresql-$PG_VER-postgis-3 python3-venv python3-pip python3-dev build-essential

# ────────────────────────── POSTGRESQL & POSTGIS SETUP ──────────────────────────
echo "🛠️ Creating PostgreSQL user and database..."
ORIGINAL_DIR=$(pwd)
cd /tmp
sudo -u postgres psql <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}'
   ) THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
   END IF;
END
\$\$;

DROP DATABASE IF EXISTS ${DB_NAME};
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF

# Connect to the new database and add PostGIS extension
sudo -u postgres psql -d ${DB_NAME} <<EOF
CREATE EXTENSION IF NOT EXISTS postgis;
EOF

cd "$ORIGINAL_DIR"

echo "✅ PostgreSQL user and database created with PostGIS extension."

# ────────────────────────── REPOSITORY CLONING ──────────────────────────
echo "📥 Cloning repositories..."

if [ ! -d "$FRONTEND_DIR" ]; then
    echo "Cloning frontend repository..."
    git clone "$FRONTEND_REPO" "$FRONTEND_DIR"
else
    echo "Frontend directory already exists, skipping clone."
fi

if [ ! -d "$BACKEND_DIR" ]; then
    echo "Cloning backend repository..."
    git clone "$BACKEND_REPO" "$BACKEND_DIR"
else
    echo "Backend directory already exists, skipping clone."
fi

# ────────────────────────── FRONTEND SETUP (React + Vite) ──────────────────────────
echo "⚛️ Setting up React (Vite) frontend..."
cd "$FRONTEND_DIR"

# Install frontend dependencies
npm install

# Move render.yaml to frontend directory
mv ../render.yaml .

echo "✅ Frontend setup completed."
cd ..

# ────────────────────────── BACKEND SETUP (Django) ──────────────────────────
echo "🐍 Setting up Django backend..."
cd "$BACKEND_DIR" || { echo "Failed to enter backend directory"; exit 1; }

# Set up Python virtual environment
VENV_PYTHON="$PYTHON_VENV/bin/python"
VENV_PIP="$PYTHON_VENV/bin/pip"

if [ ! -f "$VENV_PYTHON" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$PYTHON_VENV"
    echo "✅ Virtual environment created at $PYTHON_VENV"
else
    echo "Virtual environment already exists at $PYTHON_VENV"
fi

# Verify virtual environment was created successfully
if [ ! -f "$VENV_PYTHON" ]; then
    echo "❌ Error: Failed to create virtual environment"
    exit 1
fi

# Install Python dependencies using venv's pip
echo "📦 Installing Python dependencies..."
"$VENV_PIP" install --upgrade pip
"$VENV_PIP" install python-dotenv  # For loading .env files
"$VENV_PIP" install -r requirements.txt

# Create backend .env file (copy from main directory or create new one)
if [ -f "../.env" ]; then
    cp ../.env .
    echo "✅ Copied .env file to backend directory."
else
    # Create .env file directly in backend directory matching Django settings
    cat > .env <<EOF
# Django settings
DEBUG=True
SECRET_KEY=$(openssl rand -hex 32)
CORS_ALLOWED_ORIGINS=$FRONTEND_URL

# Database settings (matching POSTGRES_* variables in settings.py)
POSTGRES_ENGINE=django.contrib.gis.db.backends.postgis
POSTGRES_DB=$DB_NAME
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# Email settings
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
DEFAULT_FROM_EMAIL=

# Development URLs
FRONTEND_URL=$FRONTEND_URL
BACKEND_URL=$BACKEND_URL

EOF
    echo "✅ Created .env file in backend directory."
fi

# Copy logs, static, and media folders to backend directory
mkdir -p logs static media

# Apply Django migrations using venv's Python
echo "⚙️ Applying Django migrations..."
DJANGO_SETTINGS_MODULE="$DJANGO_PROJ.settings" "$VENV_PYTHON" manage.py migrate

# Create Django superuser using venv's Python
echo "👤 Creating Django superuser..."
DJANGO_SETTINGS_MODULE="$DJANGO_PROJ.settings" "$VENV_PYTHON" manage.py shell <<EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='$DJANGO_SUPERUSER').exists():
    User.objects.create_superuser('$DJANGO_SUPERUSER', '$DJANGO_SUPEREMAIL', '$DJANGO_SUPERPASS')
    print("Superuser created successfully.")
else:
    print("Superuser already exists.")
EOF

# Collect static files using venv's Python
echo "🧹 Collecting static files..."
DJANGO_SETTINGS_MODULE="$DJANGO_PROJ.settings" "$VENV_PYTHON" manage.py collectstatic --noinput

echo "✅ Backend setup completed."
cd .. || exit 1

# ────────────────────────── DEVELOPMENT SERVER STARTUP ──────────────────────────
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "────────────────────── NEXT STEPS ──────────────────────"
echo ""
echo "To start the development servers:"
echo ""
echo "1. 🚀 Start Frontend (React + Vite):"
echo "   cd $FRONTEND_DIR"
echo "   npm run dev"
echo "   → Frontend will be available at: $FRONTEND_URL"
echo ""
echo "2. 🐍 Start Backend (Django):"
echo "   cd $BACKEND_DIR"
echo "   $VENV_PYTHON manage.py runserver"
echo "   → Backend will be available at: $BACKEND_URL"
echo "   → Admin panel: $BACKEND_URL/admin"
echo ""
echo "   💡 Or activate the virtual environment manually:"
echo "   source $PYTHON_VENV/bin/activate"
echo "   python manage.py runserver"
echo ""
echo "────────────────────── CREDENTIALS ──────────────────────"
echo "🔐 Django Admin:"
echo "   Username: $DJANGO_SUPERUSER"
echo "   Password: $DJANGO_SUPERPASS"
echo "   Email: $DJANGO_SUPEREMAIL"
echo ""
echo "🗄️ Database:"
echo "   Name: $DB_NAME"
echo "   User: $DB_USER"
echo "   Password: $DB_PASS"
echo ""
echo "────────────────────── DEPLOYMENT ──────────────────────"
echo "📤 For deployment:"
echo "1. Update repository URLs in render.yaml"
echo "2. Push your code to the specified repositories"
echo "3. Connect your Render account to deploy"
echo ""
echo "🔧 Configuration files created:"
echo "   • .env (Django backend configuration)"
echo "   • render.yaml (Deployment configuration)"
echo "   • $FRONTEND_DIR/.env (Frontend configuration)"
echo ""
echo "✨ Happy coding!"