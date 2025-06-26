#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# 🎯 WebGIS Full-Stack Web Application Setup Script
# Combines Django backend with PostgreSQL/PostGIS and React frontend setup

echo "🚀 Starting WebGIS Full-Stack Application Setup..."

# ────────────────────────── ERROR HANDLING ──────────────────────────
# Add error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo "❌ Error occurred in script at line $line_number (exit code: $exit_code)"
    echo "🧹 Cleaning up..."
    cleanup_on_error
    exit $exit_code
}

# Set up error trap
trap 'handle_error $LINENO' ERR

# Cleanup function for when things go wrong
cleanup_on_error() {
    echo "Performing cleanup operations..."
    # Kill any background processes if needed
    # Remove partial installations
    # Restore original state if possible
}

# Safe directory change function
safe_cd() {
    local target_dir="$1"
    if [[ ! -d "$target_dir" ]]; then
        echo "❌ Directory does not exist: $target_dir"
        return 1
    fi
    cd "$target_dir" || {
        echo "❌ Failed to change to directory: $target_dir"
        return 1
    }
    echo "📁 Changed to directory: $(pwd)"
}

# Function to run commands with better error reporting
run_command() {
    local description="$1"
    shift
    echo "🔄 $description..."
    if "$@"; then
        echo "✅ $description completed successfully"
    else
        local exit_code=$?
        echo "❌ $description failed (exit code: $exit_code)"
        echo "Command: $*"
        return $exit_code
    fi
}

# ────────────────────────── CONFIGURATION ──────────────────────────
# Database Configuration
PG_VER=17 #TODO: Check for the postgres version
DB_NAME="webgisdb" #TODO: Set database name
DB_USER="myuser" #TODO: Set database user
DB_PASS="mypassword" #TODO: Set database password

# Django Configuration
DJANGO_PROJ="WebGIS"
DJANGO_SUPERUSER="admin" #TODO: Set Django superuser username
DJANGO_SUPERPASS="adminpass" #TODO: Set Django superuser password
DJANGO_SUPEREMAIL="admin@example.com" #TODO: Set Django superuser email
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
check_required_tools() {
    local REQUIRED_TOOLS=("node" "npm" "git" "python3" "psql" "sudo" "gdal-config")
    echo "🔍 Checking for required tools..."
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "❌ Error: '$tool' is not installed. Please install it before running this script."
            exit 1
        fi
    done
    echo "✅ All required tools are installed."
}

# ────────────────────────── RENDER.YAML FOR DEPLOYMENT ──────────────────────────
create_render_config() {
    echo "📝 Creating render.yaml for deployment..."

    cat > render.yaml <<'EOF'
# render.yaml - WebGIS Full-Stack Deployment Configuration
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
      - key: REDIS_URL
        fromService:
          type: redis
          name: webgis-redis

  # ────────────────────────── Celery Worker (Async Tasks) ───────────────────────────
  - name: webgis-celery
    type: worker
    env: python
    region: ohio
    repo: https://github.com/YOUR_USERNAME/YOUR_BACKEND_REPO
    branch: deploy
    autoDeploy: true
    buildCommand: pip install -r requirements.txt
    startCommand: celery -A $DJANGO_PROJ worker --loglevel=info
    envVars:
      - key: REDIS_URL
        fromService:
          type: redis
          name: webgis-redis
      - key: SECRET_KEY
        sync: false  # optional — if you want to match backend
      - key: DEBUG
        value: False

  # ────────────────────────── Cron Job (Optional Maintenance) ───────────────────────────
  - name: webgis-maintenance
    type: cron
    schedule: "0 4 * * *"
    env: python
    repo: https://github.com/YOUR_USERNAME/YOUR_BACKEND_REPO
    branch: deploy
    buildCommand: pip install -r requirements.txt
    startCommand: python manage.py cleanup_expired_data
    envVars:
      - key: REDIS_URL
        fromService:
          type: redis
          name: webgis-redis

# ────────────────────────── Database (PostGIS) ───────────────────────────
databases:
  - name: webgis-database
    plan: basic-256mb
    region: ohio
    databaseName: webgisdb

# ────────────────────────── Redis (Celery Broker) ───────────────────────────
services:
  - name: webgis-redis
    type: redis
    plan: hobby
    region: ohio
EOF

    echo "✅ render.yaml created. Update repository URLs and service names as needed."
}

# ────────────────────────── SYSTEM DEPENDENCIES ──────────────────────────
install_system_dependencies() {
    echo "🔧 Installing system dependencies..."

    # Update package list
    run_command "Updating package list" sudo apt update

    # Install PostgreSQL, PostGIS, and build tools
    run_command "Installing PostgreSQL + PostGIS + build tools" sudo apt install -y \
        "postgresql-$PG_VER" \
        "postgresql-$PG_VER-postgis-3" \
        python3-venv \
        python3-pip \
        python3-dev \
        build-essential \
        libpq-dev

    # Install geospatial libraries required by GDAL, GeoDjango, and friends
    run_command "Installing GDAL and geospatial libraries" sudo apt install -y \
        gdal-bin \
        libgdal-dev \
        libgeos-dev \
        libproj-dev \
        libspatialindex-dev \
        binutils

    # Optional: install CLI tools for raster/vector work (e.g., ogr2ogr, gdal_translate)
    run_command "Verifying GDAL install" gdalinfo --version
}

# ────────────────────────── POSTGRESQL & POSTGIS SETUP ──────────────────────────
check_postgresql_service() {
    echo "🔍 Checking PostgreSQL service..."
    if ! sudo systemctl is-active --quiet postgresql; then
        echo "⚠️ PostgreSQL is not running. Starting it..."
        run_command "Starting PostgreSQL" sudo systemctl start postgresql
    fi
    echo "✅ PostgreSQL is running"
}

setup_postgresql() {
    echo "🛠️ Setting up PostgreSQL..."

    check_postgresql_service

    # Test PostgreSQL connection
    if ! sudo -u postgres psql -c "SELECT version();" >/dev/null 2>&1; then
        echo "❌ Cannot connect to PostgreSQL"
        return 1
    fi

    echo "🔄 Creating PostgreSQL user and database..."

    local ORIGINAL_DIR
    ORIGINAL_DIR=$(pwd)  # Set this before anything else
    cd /tmp || return 1

    if ! sudo -u postgres psql <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}'
   ) THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
      RAISE NOTICE 'User ${DB_USER} created successfully';
   ELSE
      RAISE NOTICE 'User ${DB_USER} already exists';
   END IF;
END
\$\$;

DROP DATABASE IF EXISTS ${DB_NAME};
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF
    then
        echo "❌ Failed to create PostgreSQL user/database"
        cd "$ORIGINAL_DIR"
        return 1
    fi

    # PostGIS extension
    if ! sudo -u postgres psql -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" ; then
        echo "❌ Failed to add PostGIS extension"
        cd "$ORIGINAL_DIR"
        return 1
    fi

    cd "$ORIGINAL_DIR" || return 1
    echo "✅ PostgreSQL user and database created with PostGIS extension."
}

# ────────────────────────── REPOSITORY MANAGEMENT ──────────────────────────
validate_git_repo() {
    local repo_url="$1"
    local repo_name="$2"

    echo "🔍 Validating $repo_name repository..."
    if ! git ls-remote "$repo_url" HEAD >/dev/null 2>&1; then
        echo "❌ Cannot access repository: $repo_url"
        echo "Please check the URL and your internet connection"
        return 1
    fi
    echo "✅ Repository is accessible: $repo_url"
}

safe_clone_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name="$3"

    validate_git_repo "$repo_url" "$repo_name"

    if [[ -d "$target_dir/.git" ]]; then
        echo "📁 $repo_name repository already exists, pulling latest changes..."
        safe_cd "$target_dir"
        run_command "Pulling latest changes" git pull
        cd .. || return 1
    else
        if [[ -d "$target_dir" ]]; then
            echo "⚠️ Directory exists but is not a git repository: $target_dir"
            echo "Please remove it manually and run the script again"
            return 1
        fi
        run_command "Cloning $repo_name repository" git clone "$repo_url" "$target_dir"
    fi
}

clone_repositories() {
    echo "📥 Cloning repositories..."
    safe_clone_repo "$FRONTEND_REPO" "$FRONTEND_DIR" "frontend"
    safe_clone_repo "$BACKEND_REPO" "$BACKEND_DIR" "backend"
}

# ────────────────────────── FRONTEND SETUP (React + Vite) ──────────────────────────
setup_frontend() {
    echo "⚛️ Setting up React (Vite) frontend..."

    safe_cd "$FRONTEND_DIR"

    # Check if package.json exists
    if [[ ! -f "package.json" ]]; then
        echo "❌ package.json not found in frontend directory"
        return 1
    fi

    # Install dependencies with error handling
    run_command "Installing frontend dependencies" npm install

    # Move render.yaml to frontend directory
    if [[ -f "../render.yaml" ]]; then
        run_command "Moving render.yaml to frontend directory" mv ../render.yaml .
    else
        echo "⚠️ render.yaml not found in parent directory"
    fi

    echo "✅ Frontend setup completed."
    cd .. || return 1
}

# ────────────────────────── BACKEND SETUP (Django) ──────────────────────────
create_backend_env() {
    echo "📝 Creating backend .env file..."

    # Create .env file or copy from parent directory
    if [[ -f "../.env" ]]; then
        cp ../.env .
        echo "✅ Copied .env file to backend directory."
    else
        # Create .env file directly in backend directory
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
}

setup_django_superuser() {
    local venv_python="$1"

    echo "👤 Creating Django superuser..."
    if ! DJANGO_SETTINGS_MODULE="$DJANGO_PROJ.settings" "$venv_python" manage.py shell <<EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='$DJANGO_SUPERUSER').exists():
    User.objects.create_superuser('$DJANGO_SUPERUSER', '$DJANGO_SUPEREMAIL', '$DJANGO_SUPERPASS')
    print("Superuser created successfully.")
else:
    print("Superuser already exists.")
EOF
    then
        echo "❌ Failed to create Django superuser"
        return 1
    fi
}

setup_backend() {
    echo "🐍 Setting up Django backend..."

    safe_cd "$BACKEND_DIR"

    # Check if requirements.txt exists
    if [[ ! -f "requirements.txt" ]]; then
        echo "❌ requirements.txt not found in backend directory"
        return 1
    fi

    # Set up virtual environment with error handling
    local VENV_PYTHON="$PYTHON_VENV/bin/python"
    local VENV_PIP="$PYTHON_VENV/bin/pip"


    if [[ ! -f "$VENV_PYTHON" ]]; then
        run_command "Creating Python virtual environment" python3 -m venv "$PYTHON_VENV"
    else
        echo "Virtual environment already exists at $PYTHON_VENV"
    fi

    # Verify virtual environment creation
    if [[ ! -f "$VENV_PYTHON" ]]; then
        echo "❌ Failed to create virtual environment"
        return 1
    fi

    # Verify gdal-config is available
    if ! command -v gdal-config >/dev/null 2>&1; then
        echo "❌ gdal-config not found. GDAL must be installed system-wide before proceeding."
        return 1
    fi

    # Install Python dependencies
    echo "📦 Installing Python dependencies..."
    run_command "Upgrading pip" "$VENV_PIP" install --upgrade pip
    run_command "Installing python-dotenv" "$VENV_PIP" install python-dotenv
    run_command "Installing Python dependencies" "$VENV_PIP" install -r requirements.txt
    GDAL_VERSION=$(gdal-config --version)
     run_command "Installing GDAL Python binding" "$VENV_PIP" install "GDAL==$GDAL_VERSION"

    # Create backend environment file
    create_backend_env

    # Create necessary directories
    run_command "Creating project directories" mkdir -p logs static media

    # Set Django settings module for all operations
    export DJANGO_SETTINGS_MODULE="$DJANGO_PROJ.settings"

    # Apply Django migrations
    echo "⚙️ Applying Django migrations..."
    run_command "Running Django migrations" "$VENV_PYTHON" manage.py migrate

    # Create Django superuser
    setup_django_superuser "$VENV_PYTHON"

    # Collect static files
    echo "🧹 Collecting static files..."
    run_command "Collecting static files" "$VENV_PYTHON" manage.py collectstatic --noinput

    echo "✅ Backend setup completed."
    cd .. || return 1
}

# ────────────────────────── FINAL INSTRUCTIONS ──────────────────────────
display_final_instructions() {
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
    echo "   $PYTHON_VENV/bin/python manage.py runserver"
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
    echo ""
    echo "✨ Happy coding!"
}

# ────────────────────────── MAIN EXECUTION ──────────────────────────
main() {
    echo "🎯 Full-Stack Web Application Setup Script"
    echo "Combines Django backend with PostgreSQL/PostGIS and React frontend setup"
    echo ""

    check_required_tools
    create_render_config
    install_system_dependencies
    setup_postgresql
    clone_repositories
    setup_frontend
    setup_backend
    display_final_instructions
}

# Run the main function
main "$@"