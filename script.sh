#!/usr/bin/env bash
# ============================================================
# script.sh — Automatización Docker para el Sistema de Scouting
# Construye imagen, crea y ejecuta contenedor, y proporciona
# utilidades para gestionar el ciclo de vida completo.
# ============================================================

set -euo pipefail

# ── CONFIGURACIÓN ──────────────────────────────────────────────
IMAGE_NAME="scouting-fm"
IMAGE_TAG="latest"
CONTAINER_NAME="scouting-fm-app"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
DOCKERFILE_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── COLORES ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # Sin color

# ── FUNCIONES AUXILIARES ───────────────────────────────────────

banner() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}⚽  DOCKER — SISTEMA DE SCOUTING (Football Manager)${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

info()    { echo -e "  ${GREEN}✔${NC} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC} $1"; }
error()   { echo -e "  ${RED}✖${NC} $1"; }
step()    { echo -e "\n  ${CYAN}▶${NC} ${BOLD}$1${NC}"; }

check_docker() {
    if ! command -v docker &>/dev/null; then
        error "Docker no está instalado. Instálelo primero."
        exit 1
    fi
    if ! docker info &>/dev/null 2>&1; then
        error "El daemon de Docker no está corriendo. Inícielo con: sudo systemctl start docker"
        exit 1
    fi
}

# ── VERIFICAR ARCHIVOS NECESARIOS ─────────────────────────────

check_files() {
    step "Verificando archivos necesarios..."

    local missing=0
    for file in Dockerfile requirements.txt usandoapi.py; do
        if [[ -f "${DOCKERFILE_DIR}/${file}" ]]; then
            info "Encontrado: ${file}"
        else
            error "Falta: ${file}"
            missing=1
        fi
    done

    if [[ $missing -eq 1 ]]; then
        error "Faltan archivos. Abortando."
        exit 1
    fi
}

# ── CONSTRUIR IMAGEN ──────────────────────────────────────────

build_image() {
    step "Construyendo imagen Docker: ${FULL_IMAGE}"

    docker build \
        -t "${FULL_IMAGE}" \
        -f "${DOCKERFILE_DIR}/Dockerfile" \
        "${DOCKERFILE_DIR}"

    if [[ $? -eq 0 ]]; then
        info "Imagen construida exitosamente: ${FULL_IMAGE}"
    else
        error "Error al construir la imagen."
        exit 1
    fi
}

# ── DETENER Y ELIMINAR CONTENEDOR ANTERIOR ────────────────────

cleanup_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        step "Eliminando contenedor anterior: ${CONTAINER_NAME}"
        docker rm -f "${CONTAINER_NAME}" &>/dev/null
        info "Contenedor anterior eliminado."
    fi
}

# ── CREAR Y EJECUTAR CONTENEDOR ───────────────────────────────

run_container() {
    step "Creando y ejecutando contenedor: ${CONTAINER_NAME}"
    echo -e "  ${YELLOW}ℹ${NC}  El script es interactivo. Escriba nombres de jugadores."
    echo -e "  ${YELLOW}ℹ${NC}  Escriba 'salir' dentro del programa para terminar.\n"

    docker run \
        -it \
        --name "${CONTAINER_NAME}" \
        "${FULL_IMAGE}"
}

# ── MOSTRAR INFO ──────────────────────────────────────────────

show_info() {
    step "Información del entorno Docker"

    echo ""
    echo -e "  ${BOLD}── Imágenes ──${NC}"
    docker images --filter "reference=${IMAGE_NAME}" --format "  {{.Repository}}:{{.Tag}}   {{.Size}}   {{.CreatedSince}}"

    echo ""
    echo -e "  ${BOLD}── Contenedores (todos) ──${NC}"
    docker ps -a --filter "name=${CONTAINER_NAME}" --format "  {{.Names}}   {{.Status}}   {{.Image}}"

    echo ""
}

# ── LIMPIEZA TOTAL ────────────────────────────────────────────

full_cleanup() {
    step "Limpieza completa: contenedor + imagen"

    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker rm -f "${CONTAINER_NAME}" &>/dev/null
        info "Contenedor eliminado: ${CONTAINER_NAME}"
    else
        warn "No existe contenedor: ${CONTAINER_NAME}"
    fi

    if docker images -q "${FULL_IMAGE}" &>/dev/null && [[ -n "$(docker images -q "${FULL_IMAGE}")" ]]; then
        docker rmi -f "${FULL_IMAGE}" &>/dev/null
        info "Imagen eliminada: ${FULL_IMAGE}"
    else
        warn "No existe imagen: ${FULL_IMAGE}"
    fi

    info "Limpieza completada."
}

# ── MENÚ PRINCIPAL ────────────────────────────────────────────

show_menu() {
    echo ""
    echo -e "  ${BOLD}Uso:${NC}  ./script.sh ${CYAN}[comando]${NC}"
    echo ""
    echo -e "  ${CYAN}build${NC}      Construir la imagen Docker"
    echo -e "  ${CYAN}run${NC}        Construir (si es necesario) y ejecutar el contenedor"
    echo -e "  ${CYAN}start${NC}      Re-iniciar un contenedor detenido"
    echo -e "  ${CYAN}stop${NC}       Detener el contenedor en ejecución"
    echo -e "  ${CYAN}logs${NC}       Ver los logs del contenedor"
    echo -e "  ${CYAN}info${NC}       Mostrar imágenes y contenedores del proyecto"
    echo -e "  ${CYAN}clean${NC}      Eliminar contenedor e imagen"
    echo -e "  ${CYAN}all${NC}        Hacer todo: build + run (ciclo completo)"
    echo -e "  ${CYAN}help${NC}       Mostrar este menú"
    echo ""
}

# ── PUNTO DE ENTRADA ──────────────────────────────────────────

main() {
    banner
    check_docker

    local cmd="${1:-all}"

    case "${cmd}" in
        build)
            check_files
            build_image
            show_info
            ;;
        run)
            check_files
            if [[ -z "$(docker images -q "${FULL_IMAGE}" 2>/dev/null)" ]]; then
                build_image
            fi
            cleanup_container
            run_container
            ;;
        start)
            step "Re-iniciando contenedor: ${CONTAINER_NAME}"
            docker start -ai "${CONTAINER_NAME}"
            ;;
        stop)
            step "Deteniendo contenedor: ${CONTAINER_NAME}"
            docker stop "${CONTAINER_NAME}"
            info "Contenedor detenido."
            ;;
        logs)
            step "Logs del contenedor: ${CONTAINER_NAME}"
            docker logs "${CONTAINER_NAME}"
            ;;
        info)
            show_info
            ;;
        clean)
            full_cleanup
            ;;
        all)
            check_files
            build_image
            cleanup_container
            run_container
            ;;
        help|--help|-h)
            show_menu
            ;;
        *)
            error "Comando desconocido: '${cmd}'"
            show_menu
            exit 1
            ;;
    esac
}

main "$@"
