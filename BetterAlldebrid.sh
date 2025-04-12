#!/data/data/com.termux/files/usr/bin/bash

# ========= CONFIGURATION =========
API_KEY="xFtbwg0wRYTcx6umhLOX"
USER_AGENT="BetterAlldebrid"
MAX_RETRIES=3
CONFIG_FILE="$HOME/.alldebrid_config"
LOG_FILE="$HOME/alldebrid_log.txt"
# =================================


# ========= COULEURS =========
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"
# ============================

print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════╗"
    echo "║         BetterAlldebrid            ║"
    echo "╚════════════════════════════════════╝"
    echo -e "${RESET}"
}


clear
print_header

# Chargement ou création du dossier de téléchargement
if [ -f "$CONFIG_FILE" ]; then
    DOWNLOAD_DIR=$(cat "$CONFIG_FILE")
else
    echo "Aucun dossier de téléchargement défini."
    read -rp "Entrez un chemin pour les téléchargements : " DOWNLOAD_DIR
    mkdir -p "$DOWNLOAD_DIR"
    echo "$DOWNLOAD_DIR" > "$CONFIG_FILE"
fi

# Demander le lien à débrider
read -rp "Colle le lien à débrider : " ORIGINAL_LINK

# Obtenir le lien débridé via l'API
RESPONSE=$(curl -s -A "$USER_AGENT" "https://api.alldebrid.com/v4/link/unlock?agent=$USER_AGENT&apikey=$API_KEY&link=$ORIGINAL_LINK")

# Extraire le lien débridé avec jq (installer avec `pkg install jq`)
UNLOCKED_LINK=$(echo "$RESPONSE" | jq -r '.data.link')

if [[ "$UNLOCKED_LINK" == "null" ]]; then
    echo "Erreur : Lien invalide ou problème avec l'API."
    echo "$RESPONSE" >> "$LOG_FILE"
    exit 1
fi

echo "Lien débridé : $UNLOCKED_LINK"

# Télécharger le fichier
cd "$DOWNLOAD_DIR" || exit 1

for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "Téléchargement (tentative $i)..."
    curl -LO --user-agent "$USER_AGENT" "$UNLOCKED_LINK" && break
    echo "Échec du téléchargement. Nouvelle tentative..."
done

echo "Téléchargement terminé."
