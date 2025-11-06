#!/bin/bash

# Script de configuration initiale pour Stack-IA
# Ce script automatise le démarrage et la configuration du stack

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║          Stack-IA - Configuration Initiale           ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Veuillez l'installer d'abord.${NC}"
    exit 1
fi

# Vérifier si Docker Compose est installé
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}Docker Compose n'est pas installé. Veuillez l'installer d'abord.${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Docker est installé${NC}"
echo -e "${GREEN}[OK] Docker Compose est installé${NC}"
echo ""

# Créer le fichier .env s'il n'existe pas
if [ ! -f .env ]; then
    echo -e "${YELLOW}Création du fichier .env...${NC}"
    cp env.example .env
    
    # Générer des clés aléatoires sécurisées
    N8N_KEY=$(openssl rand -base64 32 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    WEBUI_KEY=$(openssl rand -base64 32 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    
    # Remplacer les clés dans .env
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/your-encryption-key-change-this-min-32-chars/$N8N_KEY/g" .env
        sed -i '' "s/your-secret-key-change-this-min-32-chars/$WEBUI_KEY/g" .env
    else
        sed -i "s/your-encryption-key-change-this-min-32-chars/$N8N_KEY/g" .env
        sed -i "s/your-secret-key-change-this-min-32-chars/$WEBUI_KEY/g" .env
    fi
    
    echo -e "${GREEN}[OK] Fichier .env créé avec des clés sécurisées${NC}"
else
    echo -e "${GREEN}[OK] Fichier .env déjà existant${NC}"
fi
echo ""

# Demander si l'utilisateur a un GPU NVIDIA
echo -e "${YELLOW}Avez-vous un GPU NVIDIA avec CUDA installé ? (y/n)${NC}"
read -r has_gpu

if [[ ! $has_gpu =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Désactivation du support GPU dans docker-compose.yaml...${NC}"
    
    # Commenter la section GPU
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/deploy:/,/capabilities: \[gpu\]/s/^/#/' docker-compose.yaml
    else
        sed -i '/deploy:/,/capabilities: \[gpu\]/s/^/#/' docker-compose.yaml
    fi
    
    echo -e "${GREEN}[OK] Configuration sans GPU appliquée${NC}"
fi
echo ""

# Démarrer les services
echo -e "${BLUE}Démarrage des services Docker...${NC}"
docker compose up -d

echo ""
echo -e "${YELLOW}Attente du démarrage des services (30 secondes)...${NC}"
sleep 30

# Vérifier que les services sont en cours d'exécution
echo ""
echo -e "${BLUE}Statut des services :${NC}"
docker compose ps

# Attendre qu'Ollama soit prêt
echo ""
echo -e "${YELLOW}Attente qu'Ollama soit prêt...${NC}"
until docker exec ollama ollama list &> /dev/null; do
    echo -n "."
    sleep 2
done
echo ""
echo -e "${GREEN}[OK] Ollama est prêt${NC}"

# Demander quels modèles télécharger
echo ""
echo -e "${BLUE}Téléchargement des modèles Ollama${NC}"
echo -e "${YELLOW}Quels modèles souhaitez-vous télécharger ?${NC}"
echo ""
echo "1. llama3.2 (8GB) - Modèle général performant"
echo "2. mistral (4GB) - Bon pour le français"
echo "3. codellama (4GB) - Spécialisé pour le code"
echo "4. nomic-embed-text (274MB) - Pour les embeddings (REQUIS pour RAG)"
echo "5. phi3 (2.3GB) - Modèle léger et rapide"
echo "6. Tous les modèles recommandés"
echo "7. Passer cette étape"
echo ""
echo -e "${YELLOW}Votre choix (1-7) : ${NC}"
read -r model_choice

download_model() {
    local model=$1
    echo -e "${BLUE}Téléchargement de $model...${NC}"
    docker exec -it ollama ollama pull "$model"
    echo -e "${GREEN}[OK] $model téléchargé${NC}"
}

case $model_choice in
    1) download_model "llama3.2" ;;
    2) download_model "mistral" ;;
    3) download_model "codellama" ;;
    4) download_model "nomic-embed-text" ;;
    5) download_model "phi3" ;;
    6)
        download_model "llama3.2"
        download_model "mistral"
        download_model "nomic-embed-text"
        download_model "phi3"
        ;;
    7) echo -e "${YELLOW}Téléchargement des modèles ignoré${NC}" ;;
    *) echo -e "${RED}Choix invalide, téléchargement ignoré${NC}" ;;
esac

# Afficher le résumé
echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║            Installation terminée !                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${BLUE}Accès aux services :${NC}"
echo ""
echo -e "  ${GREEN}Open WebUI${NC}       http://localhost:3000"
echo -e "  ${GREEN}AnythingLLM${NC}     http://localhost:3001"
echo -e "  ${GREEN}n8n${NC}             http://localhost:5678"
echo -e "  ${GREEN}Adminer${NC}         http://localhost:8080"
echo -e "  ${GREEN}Qdrant${NC}          http://localhost:6333/dashboard"
echo ""
echo -e "${BLUE}Commandes utiles :${NC}"
echo ""
echo -e "  Voir les logs :           ${YELLOW}docker compose logs -f${NC}"
echo -e "  Arrêter les services :    ${YELLOW}docker compose down${NC}"
echo -e "  Redémarrer :              ${YELLOW}docker compose restart${NC}"
echo -e "  Télécharger un modèle :   ${YELLOW}docker exec -it ollama ollama pull <nom-modele>${NC}"
echo ""
echo -e "${BLUE}Documentation :${NC}"
echo ""
echo -e "  README.md - Guide complet"
echo -e "  WORKFLOWS.md - Exemples de workflows n8n"
echo ""
echo -e "${GREEN}Bon développement avec Stack-IA !${NC}"

