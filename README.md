# ⚽ Sistema de Scouting — Football Manager

Script Python que se conecta a la API pública **TheSportsDB** para buscar jugadores de fútbol y mostrar su información detallada (equipo, posición, nacionalidad, dorsal, salario, etc.).

## 📋 Requisitos

- Python 3.10+
- Docker (opcional, para ejecutar en contenedor)

## 🚀 Cómo ejecutar

### Opción 1: Python directo

```bash
pip install -r requirements.txt
python usandoapi.py
```

### Opción 2: Docker

```bash
docker build -t scouting-app .
docker run -it scouting-app
```

## 🔧 Manejo de errores

El script maneja 4 tipos de error:

| Error | Causa | Manejo |
|-------|-------|--------|
| **Entrada vacía** | El usuario no escribió nada | Validación con `if not jugador.strip()` |
| **ConnectionError** | Sin internet o servidor caído | `except requests.exceptions.ConnectionError` |
| **Timeout** | El servidor tardó más de 10 segundos | `except requests.exceptions.Timeout` |
| **HTTP Error** | Código HTTP inesperado (500, 403, etc.) | `raise_for_status()` + `except HTTPError` |
| **No encontrado** | El jugador no existe en la base de datos | `if datos.get("player") is None` |

## 🗂️ Estructura del proyecto

```
.
├── usandoapi.py        # Script principal
├── requirements.txt    # Dependencias Python
├── Dockerfile          # Contenedor Docker
├── .gitignore          # Archivos excluidos de Git
└── README.md           # Este archivo
```

## 🌐 API utilizada

- **TheSportsDB** — [https://www.thesportsdb.com/api.php](https://www.thesportsdb.com/api.php)
- Gratuita, sin API key
- Endpoints usados:
  - `searchplayers.php?p={nombre}` — Búsqueda por nombre
  - `lookupplayer.php?id={id}` — Detalle por ID

## 👤 Autor

Ignacio Morales — DuocUC, Escuela de Informática y Telecomunicaciones
