# Base image
FROM python:3.11

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y gdal-bin libgdal-dev postgresql-client && apt-get clean

# Set the working directory
WORKDIR /app

# Install dependencies
COPY ../requirements.txt ./requirements.txt
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

## Run migrations and collect static files
#RUN python manage.py migrate
#RUN python manage.py collectstatic --noinput

# Expose port
EXPOSE 8000

# Run Uvicorn
CMD ["uvicorn", "WebGIS.asgi:application", "--host", "0.0.0.0", "--port", "8000"]
