# ============================================================
# Dockerfile — Sistema de Scouting (Football Manager)
# Empaqueta el script Python en un contenedor liviano
# ============================================================

# Imagen base: Python 3.10 slim (liviana, ~45 MB)
FROM python:3.10-slim

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar solo requirements primero (aprovecha cache de Docker)
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir --progress=off -r requirements.txt

# Copiar el script principal
COPY usandoapi.py .

# Ejecutar el script en modo interactivo
CMD ["python", "-u", "usandoapi.py"]
