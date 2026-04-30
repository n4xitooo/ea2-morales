# ============================================================
# SISTEMA DE SCOUTING - FOOTBALL MANAGER
# Conecta a la API gratuita TheSportsDB para buscar jugadores
# de futbol y obtener su informacion actual.
# API: https://www.thesportsdb.com/api.php (gratuita, sin key)
# ============================================================

import sys
from datetime import date, datetime

import requests  # pip install requests

# Forzar UTF-8 en consola de Windows
sys.stdout.reconfigure(encoding='utf-8')


def calcular_edad(fecha_nacimiento):
    if not fecha_nacimiento or fecha_nacimiento == "N/A":
        return "N/A"

    try:
        nacimiento = datetime.strptime(fecha_nacimiento, "%Y-%m-%d").date()
    except ValueError:
        return "N/A"

    hoy = date.today()
    edad = hoy.year - nacimiento.year

    if (hoy.month, hoy.day) < (nacimiento.month, nacimiento.day):
        edad -= 1

    if edad < 0:
        return "N/A"

    return f"{edad} años"

# ──────────────────────────────────────────────────────────────
# ZONA AZUL — Presentacion del sistema
# ──────────────────────────────────────────────────────────────

print("=" * 55)
print("  ⚽  SISTEMA DE SCOUTING — FOOTBALL MANAGER  ⚽")
print("  Busca cualquier jugador de futbol del mundo")
print("  Escribe 'salir' para terminar")
print("=" * 55)

# ──────────────────────────────────────────────────────────────
# LOOP PRINCIPAL — Permite buscar multiples jugadores
# ──────────────────────────────────────────────────────────────

while True:
    jugador = input("\n🔎 Nombre del jugador (o 'salir'): ")

    # ── ERROR 1: entrada vacia ──────────────────────────────
    if not jugador.strip():
        print("  ❌ Debe ingresar un nombre. Ej: Lionel Messi")
        continue

    # Salir del programa
    if jugador.strip().lower() == "salir":
        print("\n  👋 Hasta la proxima, mister!")
        break

    # ──────────────────────────────────────────────────────────
    # ZONA VERDE — Llamada HTTP y recepcion JSON
    # ──────────────────────────────────────────────────────────

    jugador_formateado = jugador.strip().replace(" ", "_")
    url_busqueda = f"https://www.thesportsdb.com/api/v1/json/3/searchplayers.php?p={jugador_formateado}"

    # ── ERROR 2: error de conexion / red ────────────────────
    try:
        respuesta = requests.get(url_busqueda, timeout=10)
        respuesta.raise_for_status()
    except requests.exceptions.ConnectionError:
        print("  ❌ Error de conexion. Verifique su internet.")
        continue
    except requests.exceptions.Timeout:
        print("  ❌ Timeout. Intente de nuevo.")
        continue
    except requests.exceptions.HTTPError as e:
        print(f"  ❌ Error HTTP: {respuesta.status_code} - {e}")
        continue

    datos = respuesta.json()

    # ──────────────────────────────────────────────────────────
    # ZONA ROJA — Parseo y transformacion del JSON
    # ──────────────────────────────────────────────────────────

    # ── ERROR 3: jugador no encontrado ──────────────────────
    if datos.get("player") is None:
        print(f"  ❌ No se encontro: '{jugador}'")
        print("  Intente en ingles. Ej: Kylian Mbappe, Arturo Vidal")
        continue

    # Filtrar solo futbolistas
    futbolistas = [j for j in datos["player"] if j.get("strSport") == "Soccer"]

    if not futbolistas:
        print(f"  ❌ '{jugador}' no es futbolista registrado.")
        continue

    player = futbolistas[0]

    # Datos basicos de la busqueda
    nombre       = player.get("strPlayer", "N/A")
    equipo       = player.get("strTeam", "N/A")
    nacionalidad = player.get("strNationality", "N/A")
    posicion     = player.get("strPosition", "N/A")
    edad         = calcular_edad(player.get("dateBorn", "N/A"))
    estado       = player.get("strStatus", "N/A")

    # Segunda llamada para datos detallados
    id_jugador = player.get("idPlayer")
    url_detalle = f"https://www.thesportsdb.com/api/v1/json/3/lookupplayer.php?id={id_jugador}"

    try:
        respuesta2 = requests.get(url_detalle, timeout=10)
        detalle = respuesta2.json().get("players", [{}])[0]
    except Exception:
        detalle = {}

    numero    = detalle.get("strNumber", "N/A")
    fichaje   = detalle.get("strSigning", "N/A") or "No disponible"
    salario   = detalle.get("strWage", "N/A") or "No disponible"
    altura    = detalle.get("strHeight", "N/A") or "No disponible"
    peso      = detalle.get("strWeight", "N/A") or "No disponible"
    pie       = detalle.get("strSide", "N/A") or "No disponible"
    equipo2   = detalle.get("strTeam2", "N/A") or "N/A"
    # ──────────────────────────────────────────────────────────
    # ZONA MORADA — Formateo y salida al usuario
    # ──────────────────────────────────────────────────────────

    print("\n" + "═" * 55)
    print("  📋  INFORME DE SCOUTING")
    print("═" * 55)
    print(f"  ⚽ Jugador        : {nombre}")
    print(f"  🏟️  Equipo Actual  : {equipo}")
    if equipo2 != "N/A":
        print(f"  🌐 Seleccion      : {equipo2}")
    print(f"  🔢 Dorsal         : #{numero}")
    print(f"  📍 Posicion        : {posicion}")
    print(f"  🌍 Nacionalidad   : {nacionalidad}")
    print(f"  📅 Edad           : {edad}")
    print(f"  📊 Estado         : {estado}")
    print(f"  📏 Altura         : {altura}")
    print(f"  ⚖️  Peso           : {peso}")
    print(f"  🦶 Pie dominante  : {pie}")
    print(f"  💰 Costo fichaje  : {fichaje}")
    print(f"  💵 Salario        : {salario}")
    print("═" * 55)
