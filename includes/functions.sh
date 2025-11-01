#!/bin/bash
##########

function logo() {

  color1='\033[1;31m' # Bold RED
  color2='\033[1;35m' # Bold PURPLE
  color3='\033[0;33m' # Regular YELLOW
  nocolor='\033[0m'   # no color
  colorp='\033[1;34m' # Bold BLUE
  colora='\033[1;32m' # Bold GREEN
  projetname='SSD - V2.2'
  authors='Authors: laster13 - Merrick'

  printf " \n"
  printf " ${color1}███████╗ ${color2}███████╗ ${color3}██████╗  ${colorp}${projetname}${nocolor}\n"
  printf " ${color1}██╔════╝ ${color2}██╔════╝ ${color3}██╔══██╗ ${colora}${authors}${nocolor}\n"
  printf " ${color1}███████╗ ${color2}███████╗ ${color3}██║  ██║ ${nocolor}\n"
  printf " ${color1}╚════██║ ${color2}╚════██║ ${color3}██║  ██║ $(uname -srmo)${nocolor}\n"
  printf " ${color1}███████║ ${color2}███████║ ${color3}██████╔╝ $(lsb_release -sd)${nocolor}\n"
  printf " ${color1}╚══════╝ ${color2}╚══════╝ ${color3}╚═════╝  ${nocolor}Uptime: $(/usr/bin/uptime -p)${nocolor}\n"
  printf " \n"

}

function update_system() {
  #Mise à jour systeme
  echo -e "${BLUE}###" $(gettext "MISE A JOUR DU SYSTEME") "###${NC}"
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/roles/system/tasks/main.yml
  checking_errors $?
}

function status() {
  # Créé les fichiers de service, comme quoi rien n'est encore installé
  create_dir ${SETTINGS_STORAGE}/status
  sudo chown -R ${USER}: ${SETTINGS_STORAGE}/status
  for app in $(cat "${SETTINGS_SOURCE}/includes/config/services-available" | cut -d' ' -f1); do
    echo "0" >${SETTINGS_STORAGE}/status/$app
  done
}

function update_status() {

  for i in $(docker ps --format "{{.Names}}" --filter "network=traefik_proxy"); do
    echo "2" >${SETTINGS_STORAGE}/status/${i}

  done

}

function cloudflare() {
  #####################################
  # Récupère les infos de cloudflare
  # Pour utilisation ultérieure
  ######################################
  echo -e "${BLUE}###" $(gettext "Gestion des DNS") "###${NC}"
  echo ""
  echo -e "${CCYAN}------------------------------------------------------------------${CEND}"
  echo -e "${CCYAN}"   $(gettext "CloudFlare protège et accélère les sites internet.")      "${CEND}"
  echo -e "${CCYAN}"   $(gettext "CloudFlare optimise automatiquement la déliverabilité")   "${CEND}"
  echo -e "${CCYAN}"   $(gettext "de vos pages web afin de diminuer le temps de chargement")"${CEND}"
  echo -e "${CCYAN}"   $(gettext "et d’améliorer les performances. CloudFlare bloque aussi")"${CEND}"
  echo -e "${CCYAN}"   $(gettext "les menaces et empêche certains robots illégitimes de")   "${CEND}"
  echo -e "${CCYAN}"   $(gettext "consommer votre bande passante et les ressources serveur.")"${CEND}"
  echo -e "${CCYAN}------------------------------------------------------------------${CEND}"
  echo ""
  echo >&2 -n -e "${BWHITE}"$(gettext "Souhaitez vous utiliser les DNS Cloudflare ? (y/n)") "${CEND}"
  read OUI

  if [[ "$OUI" == "y" ]] || [[ "$OUI" == "Y" ]]; then

    if [ -z "$cloud_email" ] || [ -z "$cloud_api" ]; then
      cloud_email=$1
      cloud_api=$2
    fi

    while [ -z "$cloud_email" ]; do
      echo >&2 -n -e "${BWHITE}"$(gettext "Votre Email Cloudflare:") "${CEND}"
      read cloud_email
      manage_account_yml cloudflare.login "$cloud_email"
      update_seedbox_param "cf_login" $cloud_email
    done

    while [ -z "$cloud_api" ]; do
      echo >&2 -n -e "${BWHITE}"$(gettext "Votre API Cloudflare:") "${CEND}"
      read cloud_api
      manage_account_yml cloudflare.api "$cloud_api"
    done
  fi
  echo ""
}

function oauth() {
  #######################################
  # Récupère les infos oauth
  #######################################

  echo -e "${BLUE}###" $(gettext "Google OAuth2 avec Traefik – Secure SSO pour les services Docker") "###${NC}"
  echo ""
  echo -e "${CCYAN}------------------------------------------------------------------${CEND}"
  echo -e "${CCYAN}"$(gettext "Protocole d'identification via Google OAuth2")    "${CEND}"
  echo -e "${CCYAN}"$(gettext "Securisation SSO pour les services Docker")       "${CEND}"
  echo -e "${CCYAN}------------------------------------------------------------------${CEND}"
  echo ""
  echo -e "${CRED}------------------------------------------------------------------${CEND}"
  echo -e "${CRED}"IMPORTANT: $(gettext "Au préalable créer un projet et vos identifiants")"${CEND}"
  echo -e "${CRED}https://github.com/laster13/patxav/wiki 		             ${CEND}"
  echo -e "${CRED}------------------------------------------------------------------${CEND}"
  echo ""
  echo >&2 -n -e "${BWHITE}"$(gettext "Souhaitez vous sécuriser vos Applis avec Google OAuth2 ? (y/n)") "${CEND}"
  read OUI

  if [[ "$OUI" == "y" ]] || [[ "$OUI" == "Y" ]]; then
    if [ -z "$oauth_client" ] || [ -z "$oauth_secret" ] || [ -z "$email" ]; then
      oauth_client=$1
      oauth_secret=$2
      email=$3
    fi

    while [ -z "$oauth_client" ]; do
      echo >&2 -n -e "${BWHITE}Oauth_client: ${CEND}"
      read oauth_client
      manage_account_yml oauth.client "$oauth_client"
    done

    while [ -z "$oauth_secret" ]; do
      echo >&2 -n -e "${BWHITE}Oauth_secret: ${CEND}"
      read oauth_secret
      manage_account_yml oauth.secret "$oauth_secret"
    done

    while [ -z "$email" ]; do
      echo >&2 -n -e "${BWHITE}"$(gettext "Compte Gmail utilisé(s), séparés d'une virgule si plusieurs:") "${CEND}"
      read email
      manage_account_yml oauth.account "$email"
    done

    openssl=$(openssl rand -hex 16)
    manage_account_yml oauth.openssl "$openssl"

    echo ""
    echo -e "${CRED}---------------------------------------------------------------${CEND}"
    echo -e "${CCYAN}"    IMPORTANT:	$(gettext "Avant la 1ere connexion")"${CEND}"
    echo -e "${CCYAN}"    		- $(gettext "Nettoyer l'historique de votre navigateur")"${CEND}"
    echo -e "${CCYAN}"   		- $(gettext "déconnection de tout compte google")"${CEND}"
    echo -e "${CRED}---------------------------------------------------------------${CEND}"
    echo ""
    echo -e "\n $(gettext "Appuyer sur") ${CCYAN}[$(gettext "ENTREE")]${CEND} $(gettext "pour continuer")"
    read -r
  fi

  echo ""
}

function install-rtorrent-cleaner() {
  #configuration de rtorrent-cleaner avec ansible
  echo -e "${BLUE}### RTORRENT-CLEANER ###${NC}"
  echo ""
  echo -e " ${BWHITE}"* $(gettext "Installation") RTORRENT-CLEANER"${NC}"

  ## choix de l'utilisateur
  #SEEDUSER=$(ls ${SETTINGS_STORAGE}/media* | cut -d '-' -f2)
  sudo cp -r ${SETTINGS_SOURCE}/includes/config/rtorrent-cleaner/rtorrent-cleaner /usr/local/bin
  sudo sed -i "s|%SEEDUSER%|${USER}|g" /usr/local/bin/rtorrent-cleaner
  sudo sed -i "s|%SETTINGS_STORAGE%|${SETTINGS_STORAGE}|g" /usr/local/bin/rtorrent-cleaner
}

function sauve() {
  create_dir "/var/backup/local"
  #configuration Sauvegarde
  echo -e "${BLUE}### BACKUP ###${NC}"
  echo -e " ${BWHITE}"* $(gettext "Mise en place Sauvegarde")"${NC}"
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/roles/backup/tasks/main.yml
  checking_errors $?
  echo ""
}

function debug() {
  echo "### DEBUG ${1}"
  pause
}

function plex_dupefinder() {
  #configuration plex_dupefinder avec ansible
  echo -e "${BLUE}### PLEX_DUPEFINDER ###${NC}"
  echo -e " ${BWHITE}"* $(gettext "Installation") plex_dupefinder"${NC}"
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/roles/plex_dupefinder/tasks/main.yml
  checking_errors $?
}

function update_logrotate() {
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/playbooks/logrotate.yml
}

function autoscan() {
  #configuration plex_autoscan avec ansible
  echo -e "${BLUE}### AUTOSCAN ###${NC}"
  echo -e " ${BWHITE}"* $(gettext "Installation") autoscan"${NC}"
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/roles/autoscan/tasks/main.yml
  checking_errors $?
}

function install_cloudplow() {
  #configuration plex_autoscan avec ansible
  echo -e "${BLUE}### CLOUDPLOW ###${NC}"
  echo -e " ${BWHITE}"* $(gettext "Installation") cloudplow"${NC}"
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/roles/cloudplow/tasks/main.yml
  sudo chown -R ${USER} ${HOME}/scripts/cloudplow
  checking_errors $?
}

function check_dir() {
  if [[ $1 != "${SETTINGS_SOURCE}" ]]; then
    # shellcheck disable=SC2164
    cd "${SETTINGS_SOURCE}"
  fi
}

function create_dir() {
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/playbooks/create_directory.yml" \
    --extra-vars '{"DIRECTORY":"'${1}'"}'
}

function conf_dir() {
  create_dir "${SETTINGS_STORAGE}"
}

function create_file() {
  TMPMYUID=$(whoami)
  MYGID=$(id -g)
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/playbooks/create_file.yml" \
    --extra-vars '{"FILE":"'${1}'","UID":"'${TMPMYUID}'","GID":"'${MYGID}'"}'
}

function change_file_owner() {
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/playbooks/chown_file.yml" \
    --extra-vars '{"FILE":"'${1}'"}'

}

function make_dir_writable() {
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/playbooks/change_rights.yml" \
    --extra-vars '{"DIRECTORY":"'${1}'"}'

}

function install_base_packages() {
  echo ""
  echo -e "${BLUE}"### $(gettext "INSTALLATION DES") PACKAGES ###"${NC}"
  echo ""
  echo -e " ${BWHITE}"* $(gettext "Installation") apache2-utils, unzip, git, curl ..."${NC}"
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/roles/install/tasks/main.yml"
  checking_errors $?
  echo ""
}

function checking_errors() {
  if [[ "$1" == "0" ]]; then
    echo -e "	${GREEN}--> Operation success !${NC}"
    CURRENT_ERROR=0
  else
    echo -e "	${RED}--> Operation failed !${NC}"
    CURRENT_ERROR=1
  fi
}

function install_fail2ban() {
  echo -e "${BLUE}### FAIL2BAN ###${NC}"
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/roles/fail2ban/tasks/main.yml"
  checking_errors $?
  echo ""
}

function install_ufw() {
  #clear
  echo -e "${CCYAN}---------------------------------------------------------------${CEND}"
  echo -e "${CCYAN}" $(gettext "UFW sera installé avec les valeurs par défaut uniquement") "${CEND}"
  echo -e "${CCYAN}" $(gettext "et permettra les accès suivants :") "${CEND}"
  echo -e "${CCYAN} ssh, http, https, plex ${CEND}"
  echo -e "${CCYAN}" $(gettext "Vous pourrez le modifier en éditant le fichier")" ${SETTINGS_STORAGE}/conf/ufw.yml ""${CEND}"
  echo -e "${CCYAN}" $(gettext "pour ajouter des ports/ip supplémentaires") "${CEND}"
  echo -e "${CCYAN}" $(gettext "avant de relancer ce script") "${CEND}"
  echo -e "${CCYAN}---------------------------------------------------------------${CEND}"
  echo -e "\n $(gettext "Appuyer sur") ${GREEN}[$(gettext "ENTREE")]${CEND} $(gettext "pour continuer")"
  read -r
  echo -e "${BLUE}### UFW ###${NC}"
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/roles/ufw/tasks/main.yml"
  ansible-playbook "${SETTINGS_STORAGE}/conf/ufw.yml"
  checking_errors $?
  echo ""
}

function install_traefik() {
  create_dir "${SETTINGS_STORAGE}/docker/traefik/acme/"
  echo -e "${BLUE}### TRAEFIK ###${NC}"

  ansible-playbook "${SETTINGS_SOURCE}/includes/dockerapps/templates/ansible/ansible.yml"
  DOMAIN=$(cat "${TMPDOMAIN}")

  # choix sous domaine traefik
  echo ""
  echo -e "${BWHITE}"$(gettext "Adresse par défault:") "https://traefik.${DOMAIN} ${CEND}"
  echo ""
  echo >&2 -n -e "${BWHITE}"$(gettext "Souhaitez vous personnaliser le sous domaine ? (y/n)") "${CEND}"
  read OUI

  if [[ "$OUI" == "y" ]] || [[ "$OUI" == "Y" ]]; then

    while [ -z "$SUBDOMAIN" ]; do
      echo >&2 -n -e "${BWHITE}"$(gettext "Sous Domaine:") "${CEND}"
      read SUBDOMAIN
    done

    if [ ! -z "$SUBDOMAIN" ]; then
      manage_account_yml sub.traefik.traefik $SUBDOMAIN
    fi
  else
    manage_account_yml sub.traefik.traefik traefik
  fi

  # choix authentification traefik
  echo ""
  echo >&2 -n -e "${BWHITE}"$(gettext "Choix de Authentification pour traefik") "[ Enter ] 1 => basique | 2 => oauth | 3 => authelia :${CEND}"
  read AUTH
  case $AUTH in
  1)
    TYPE_AUTH=basique
    ;;

  2)
    TYPE_AUTH=oauth
    ;;

  3)
    TYPE_AUTH=authelia
    ;;

  *)
    TYPE_AUTH=basique
    echo -e "${BWHITE}"$(gettext "Pas de choix sélectionné, on passe sur une auth basique")"${CEND}"
    ;;
  esac
  manage_account_yml sub.traefik.auth ${TYPE_AUTH}

  echo ""
  echo -e " ${BWHITE}"* $(gettext "Installation") Traefik"${NC}"
  ansible-playbook ${SETTINGS_SOURCE}/includes/dockerapps/traefik.yml
  checking_errors $?
  if [[ ${CURRENT_ERROR} -eq 1 ]]; then
    echo -e "${CCYAN}"$(gettext "Cette étape peut ne pas aboutir lors d'une première installation")"${CEND}"
    echo -e "${CCYAN}"$(gettext "Suite à l'installation de docker, il faut se déloguer/reloguer pour que cela fonctionne")"${CEND}"
    echo -e "${CCYAN}"$(gettext "Cette erreur est bloquante, impossible de continuer")"${CEND}"
    exit 1
  fi

  echo ""
}

function install_watchtower() {
  echo -e "${BLUE}### WATCHTOWER ###${NC}"
  echo -e " ${BWHITE}"* $(gettext "Installation") Watchtower"${NC}"
  ansible-playbook ${SETTINGS_SOURCE}/includes/dockerapps/watchtower.yml
  checking_errors $?
  echo ""
}

function install_rclone() {
ARCHITECTURE=$(dpkg --print-architecture)
RCLONE_VERSION=$(get_from_account_yml rclone.architecture)
  if [ ${RCLONE_VERSION} == notfound ]; then
    manage_account_yml rclone.architecture "${ARCHITECTURE}"
  fi
  fusermount -uz ${SETTINGS_STORAGE} }}/seedbox/zurg >>/dev/null 2>&1
  manage_account_yml rclone.architecture "${ARCHITECTURE}"
  if [ ! -f  "${SETTINGS_STORAGE}/status/rclone" ]; then
    echo -e "\e[32m"$(gettext "INSTALLATION") ZURG"\e[0m"   				
    install_zurg
    ansible-playbook "${SETTINGS_SOURCE}/includes/config/roles/rclone/tasks/main.yml"
  else
    echo -e "\e[32m"$(gettext "INSTALLATION") RCLONE"\e[0m"   				
    ansible-playbook "${SETTINGS_SOURCE}/includes/config/roles/rclone/tasks/main.yml"
  fi
    checking_errors $?
  echo ""
}

function install_common() {
  source "${SETTINGS_SOURCE}/venv/bin/activate"
  # on contre le bug de debian et du venv qui ne trouve pas les paquets installés par galaxy
  temppath=$(ls ${SETTINGS_SOURCE}/venv/lib)
  pythonpath=${SETTINGS_SOURCE}/venv/lib/${temppath}/site-packages
  export PYTHONPATH=${pythonpath}
  # toutes les installs communes
  # installation des dépendances, permet de créer les docker network via ansible
  ansible-galaxy collection install community.general
  #ansible-galaxy collection install community.docker
  # dépendence permettant de gérer les fichiers yml
  ansible-galaxy install kwoodson.yedit
  ansible-galaxy role install geerlingguy.docker

  manage_account_yml settings.storage "${SETTINGS_STORAGE}"
  manage_account_yml settings.source "${SETTINGS_SOURCE}"

  # On vérifie que le user ait bien les droits d'écriture
  make_dir_writable "${SETTINGS_SOURCE}"
  # on vérifie que le user ait bien les droits d'écriture dans la db
  change_file_owner "${SETTINGS_SOURCE}/ssddb"
  # On crée le conf dir (par défaut /opt/seedbox) s'il n'existe pas
  conf_dir

  stocke_public_ip
  # On part à la pêche aux infos....
  ${SETTINGS_SOURCE}/includes/config/scripts/get_infos.sh
  #pause
  echo ""
  # On crée les fichier de status à 0
  status
  # Mise à jour du système
  update_system
  # Installation des packages de base
  install_base_packages
  # Installation de docker
  install_docker
  # install de traefik
  if docker ps | grep -q traefik; then
    # on ne fait rien, traefik est déjà isntallé
    :
  else
    install_traefik
  fi
  #unionfs_fuse

}

function unionfs_fuse() {
  echo -e "${BLUE}### Unionfs-Fuse ###${NC}"
  echo -e " ${BWHITE}"* $(gettext "Installation") Mergerfs"${NC}"
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/roles/unionfs/tasks/main.yml
  checking_errors $?
  echo ""
}

function install_docker() {
  echo -e "${BLUE}### DOCKER ###${NC}"
  echo -e " ${BWHITE}"* $(gettext "Installation") Docker"${NC}"
  file="/usr/bin/docker"
  if [ ! -e "$file" ]; then
    ansible-playbook ${SETTINGS_SOURCE}/includes/config/roles/docker/tasks/main.yml
  else
    echo -e " ${YELLOW}"* $(gettext "docker est déjà installé !")"${NC}"
  fi
  echo ""
}

function subdomain() {

  echo ""
  echo >&2 -n -e "${BWHITE}-->" $(gettext "Personnaliser les sous domaines: (y/n) ?") "${CEND}"
  read OUI

  echo ""
  if [[ "$OUI" == "y" ]] || [[ "$OUI" == "Y" ]]; then
    echo -e " ${CRED}-->"$(gettext "NE PAS SAISIR LE NOM DE DOMAINE - LES POINTS NE SONT PAS ACCEPTES")"${NC}"
    echo ""
    for line in $(cat $SERVICESPERUSER); do

      while [ -z "$SUBDOMAIN" ]; do
        echo >&2 -n -e "${BWHITE}"$(gettext "Sous domaine pour") ${line} "${CEND}"
        read SUBDOMAIN
      done
      manage_account_yml sub.${line}.${line} $SUBDOMAIN
    done
  else
    for line in $(cat $SERVICESPERUSER); do
      SUBDOMAIN=${line}
      manage_account_yml sub.${line}.${line} $SUBDOMAIN
    done
  fi
}

function subdomain_unitaire() {
  line=$1
  echo ""
  echo >&2 -n -e "${BWHITE}-->" $(gettext "Personnaliser le sous domaine pour") "${line} : (y/n) ?" "${CEND}"
  read OUI

  echo ""
  if [[ "$OUI" == "y" ]] || [[ "$OUI" == "Y" ]]; then
    echo -e " ${CRED}-->"$(gettext "NE PAS SAISIR LE NOM DE DOMAINE - LES POINTS NE SONT PAS ACCEPTES")"${NC}"
    echo ""
    echo >&2 -n -e "${BWHITE}-->" $(gettext "Sous domaine pour") "${line} : " "${CEND}"
    read SUBDOMAIN
  else
    SUBDOMAIN=${line}
  fi
  manage_account_yml sub.${line}.${line} $SUBDOMAIN
}

function auth() {

  echo ""
  for line in $(cat $SERVICESPERUSER); do

    read -rp $'\e\033[1;37m --> Authentification '${line}' [ Enter ] 1 => basique (défaut) | 2 => oauth | 3 => authelia | 4 => aucune: ' AUTH

    case $AUTH in
    1)
      TYPE_AUTH=basique
      ;;

    2)
      TYPE_AUTH=oauth
      ;;

    3)
      TYPE_AUTH=authelia

      ;;

    4)
      TYPE_AUTH=aucune
      ;;

    *)
      TYPE_AUTH=basique
      echo -e "${BWHITE}"$(gettext "Pas de choix sélectionné, on passe sur une auth basique")"${CEND}"
      ;;
    esac

    manage_account_yml sub.${line}.auth ${TYPE_AUTH}
  done
}

function auth_unitaire() {
  line=$1
  echo ""

  read -rp $'\e\033[1;37m --> Authentification '${line}' [ Enter ] 1 => basique (défaut) | 2 => oauth | 3 => authelia | 4 => aucune: ' AUTH

  case $AUTH in
  1)
    TYPE_AUTH=basique
    ;;

  2)
    TYPE_AUTH=oauth
    ;;

  3)
    TYPE_AUTH=authelia

    ;;

  4)
    TYPE_AUTH=aucune
    ;;

  *)
    TYPE_AUTH=basique
    echo -e "${BWHITE}"$(gettext "Pas de choix sélectionné, on passe sur une auth basique")"${CEND}"
    ;;
  esac

  manage_account_yml sub.${line}.auth ${TYPE_AUTH}

}

function choose_services() {
  echo -e "${BLUE}### SERVICES ###${NC}"
  echo -e " ${BWHITE}-->" $(gettext "Services en cours d'installation") ":${NC}"
  rm -Rf "${SERVICESPERUSER}" >/dev/null 2>&1
  touch $SERVICESPERUSER
  jq -r '.selected_lines[] | split("-")[0] | gsub("\""; "")' output.json > $SERVICESPERUSER
  echo -e "${GREEN}$(cat $SERVICESPERUSER)${NC}"
}

function install_services() {
  if [ -f "$SERVICESPERUSER" ]; then

    if [[ ! -d "${SETTINGS_STORAGE}/conf" ]]; then
      mkdir -p "${SETTINGS_STORAGE}/conf" >/dev/null 2>&1
    fi

    if [[ ! -d "${SETTINGS_STORAGE}/vars" ]]; then
      mkdir -p "${SETTINGS_STORAGE}/vars" >/dev/null 2>&1
    fi

    create_file "${SETTINGS_STORAGE}/temp.txt"

    for line in $(cat $SERVICESPERUSER); do
      launch_service "${line}"
    done
  fi
  rm $SERVICESPERUSER
}

function launch_service() {

  line=$1
  log_write "Installation de ${line}" >/dev/null 2>&1
  error=0

# Définir les chemins à vérifier
  paths=(
    "${SETTINGS_SOURCE}/includes/dockerapps/vars/${line}.yml"
    "${SETTINGS_SOURCE}/includes/dockerapps/${line}.yml"
    "/home/${USER}/seedbox/vars/${line}.yml"
  )

  for path in "${paths[@]}"; do
    # Vérifie la présence de "traefik_labels_enabled: false" dans le fichier
    grep "traefik_labels_enabled: false" "$path" >/dev/null 2>&1
    if [ $? -eq 1 ]; then
      tempsubdomain=$(get_from_account_yml sub.${line}.${line})
      if [ "${tempsubdomain}" = notfound ]; then
        subdomain_unitaire ${line}
      fi
      tempauth=$(get_from_account_yml sub.${line}.auth)
      if [ "${tempauth}" = notfound ]; then
        auth_unitaire ${line}
      fi
    else
      # Vérifie également la présence de "labels" dans le fichier si "traefik_labels_enabled: false" est trouvé
      grep "labels:" "$path" >/dev/null 2>&1
      if [ $? -eq 0 ]; then
        tempsubdomain=$(get_from_account_yml sub.${line}.${line})
        if [ "${tempsubdomain}" = notfound ]; then
          subdomain_unitaire ${line}
        fi
        tempauth=$(get_from_account_yml sub.${line}.auth)
        if [ "${tempauth}" = notfound ]; then
          auth_unitaire ${line}
        fi
      fi
    fi
  done

  if [[ "${line}" == "plex" ]]; then
    echo ""
    echo -e "${BLUE}### CONFIG POST COMPOSE PLEX ###${NC}"
    echo -e " ${BWHITE}* Processing plex config file...${NC}"
    echo ""
    echo -e " ${GREEN}"$(gettext "ATTENTION IMPORTANT - NE PAS FAIRE D'ERREUR - SINON DESINSTALLER ET REINSTALLER")"${NC}"
    "${SETTINGS_SOURCE}/includes/config/scripts/plex_token.sh"
    ansible-playbook "${SETTINGS_SOURCE}/includes/dockerapps/plex.yml"
    echo "2" >"${SETTINGS_STORAGE}/status/plex"
  else
    # On est dans le cas générique
    # on regarde s'i y a un playbook existant
    if [[ -f "${SETTINGS_STORAGE}/vars/${line}.yml" ]]; then
      # il y a des variables persos, on les lance
      ansible-playbook "${SETTINGS_SOURCE}/includes/dockerapps/generique.yml" --extra-vars "@${SETTINGS_STORAGE}/vars/${line}.yml"
    elif [[ -f "${SETTINGS_SOURCE}/includes/dockerapps/${line}.yml" ]]; then
      # pas de playbook perso ni de vars perso
      # puis on le lance
      ansible-playbook "${SETTINGS_SOURCE}/includes/dockerapps/${line}.yml"
    elif [[ -f "${SETTINGS_SOURCE}/includes/dockerapps/vars/${line}.yml" ]]; then
      echo 
      # puis on lance le générique avec ce qu'on vient de copier
      ansible-playbook "${SETTINGS_SOURCE}/includes/dockerapps/generique.yml" --extra-vars "@${SETTINGS_SOURCE}/includes/dockerapps/vars/${line}.yml"
    else
      log_write "Aucun fichier de configuration trouvé dans les sources, abandon"
      error=1
    fi
  fi
  if [ ${error} = 0 ]; then
    temp_subdomain=$(get_from_account_yml "sub.${line}.${line}")
    DOMAIN=$(get_from_account_yml user.domain)
    echo "2" >"${SETTINGS_STORAGE}/status/${line}"

    FQDNTMP="${temp_subdomain}.$DOMAIN"

  fi
  FQDNTMP=""
}

function manage_apps() {
  echo -e "${BLUE}#################################${NC}"
  echo -e "${BLUE}"$(gettext "GESTION DES APPLIS")"${NC}"
  echo -e "${BLUE}#################################${NC}"

  ansible-playbook ${SETTINGS_SOURCE}/includes/dockerapps/templates/ansible/ansible.yml

}

function suppression_appli() {

  sousdomaine=$(get_from_account_yml sub.${APPSELECTED}.${APPSELECTED})
  domaine=$(get_from_account_yml user.domain)

  APPSELECTED=$1
  DELETE=0
  if [[ $# -eq 2 ]]; then
    if [ "$2" = "1" ]; then
      DELETE=1
    fi
  fi
  manage_account_yml sub.${APPSELECTED} " "

  docker rm -f "$APPSELECTED" >/dev/null 2>&1
  if [ $DELETE -eq 1 ]; then
    log_write "Suppresion de ${APPSELECTED}, données supprimées" >/dev/null 2>&1
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/$APPSELECTED >/dev/null 2>&1
  else
    log_write "Suppresion de ${APPSELECTED}, données conservées" >/dev/null 2>&1
  fi

  rm ${SETTINGS_STORAGE}/conf/$APPSELECTED.yml >/dev/null 2>&1
  rm ${SETTINGS_STORAGE}/vars/$APPSELECTED.yml >/dev/null 2>&1
  echo "0" >${SETTINGS_STORAGE}/status/$APPSELECTED

  case $APPSELECTED in
  oauth)
    manage_account_yml oauth.client " "
    manage_account_yml oauth.secret " "
    manage_account_yml oauth.openssl " "
    manage_account_yml oauth.account " "
    ;;
  seafile)
    docker rm -f memcached >/dev/null 2>&1
    ;;
  varken)
    docker rm -f influxdb telegraf grafana >/dev/null 2>&1
    if [ $DELETE -eq 1 ]; then
      sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/telegraf
      sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/grafana
      sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/influxdb
    fi
    ;;
  jitsi)
    docker rm -f prosody jicofo jvb
    rm -rf ${SETTINGS_STORAGE}/docker/${USER}/.jitsi-meet-cfg
    ;;
  nextcloud)
    docker rm -f collabora coturn office
    rm -rf ${SETTINGS_STORAGE}/docker/${USER}/coturn
    ;;
  rtorrentvpn)
    rm ${SETTINGS_STORAGE}/conf/rutorrent-vpn.yml
    ;;
  jackett)
    docker rm -f flaresolverr >/dev/null 2>&1
    ;;
  petio)
    docker rm -f mongo >/dev/null 2>&1
    ;;
  vinkunja)
    docker rm -f vikunja-api >/dev/null 2>&1
    ;;
  zurg)
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/zurg
    ;;
  piped*)
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/piped
    docker rm -f nginx piped-frontend piped-backend postgres piped-proxy hyperpipe-backend hyperpipe-frontend >/dev/null 2>&1
    manage_account_yml sub.piped " "
    ;;
  nginx)
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/piped
    docker rm -f nginx piped-frontend piped-backend postgres piped-proxy hyperpipe-backend hyperpipe-frontend >/dev/null 2>&1
    manage_account_yml sub.piped " "
    ;;
  hyperpipe*)
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/piped
    docker rm -f nginx piped-frontend piped-backend postgres piped-proxy hyperpipe-backend hyperpipe-frontend >/dev/null 2>&1
    manage_account_yml sub.piped " "
    ;;
  jellygrail)
    sudo fusermount -uz ${SETTINGS_STORAGE}/docker/${USER}/jellygrail/Video_Library
    sudo fusermount -uz ${SETTINGS_STORAGE}/docker/${USER}/jellygrail/Video_Library
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/jellygrail
    ;;
  espocrm*)
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/mysql
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/espocrm >/dev/null 2>&1
    docker rm -f espocrm espocrm-websocket espocrm-daemon mysql >/dev/null 2>&1
    manage_account_yml sub.piped " "
    ;;
  paperless)
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/mariadb
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/paperless >/dev/null 2>&1
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/redis >/dev/null 2>&1
    docker rm -f mariadb paperless broker >/dev/null 2>&1
    manage_account_yml sub.paperless " "
    ;;
  immich_server)
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/immich-app >/dev/null 2>&1
    docker rm -f immich_server database redis immich-machine-learning >/dev/null 2>&1
    docker volume prune -f >/dev/null 2>&1
    docker volume rm model-cache >/dev/null 2>&1
    manage_account_yml sub.immich " "
    ;;
  streamfusion)
    docker rm -f warp streamfusion >/dev/null 2>&1
    if [ $DELETE -eq 1 ]; then
        sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/${APPSELECTED}
        docker volume rm warp-data >/dev/null 2>&1
        # Il faut gérer les DB postgres dans la fonction 'check_and_remove_shared_containers'
        check_and_remove_shared_containers ${APPSELECTED}
        docker volume prune -f >/dev/null 2>&1
    fi
    ;;
  stremiocatalogs)
    docker rm -f ${APPSELECTED} >/dev/null 2>&1
    if [ $DELETE -eq 1 ]; then
        sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/${APPSELECTED}
        # Il faut gérer les DB postgres dans la fonction 'check_and_remove_shared_containers'
        check_and_remove_shared_containers ${APPSELECTED}
    fi
    ;;
  stremiotrakt)
    docker rm -f ${APPSELECTED} >/dev/null 2>&1
    if [ $DELETE -eq 1 ]; then
        sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/${APPSELECTED}
        # Il faut gérer les DB postgres dans la fonction 'check_and_remove_shared_containers'
        check_and_remove_shared_containers ${APPSELECTED}
    fi
    ;;
  zilean)
    docker rm -f zilean >/dev/null 2>&1
    if [ $DELETE -eq 1 ]; then
        sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/${APPSELECTED}
        # Il faut gérer les DB postgres dans la fonction 'check_and_remove_shared_containers'
        check_and_remove_shared_containers ${APPSELECTED}
        docker volume prune -f >/dev/null 2>&1
    fi
    ;;
  coolify)
    # Supprimer tous les conteneurs dont le nom contient 'coolify'
    docker ps -a --filter "name=coolify" --format "{{.ID}}" | xargs -r docker rm -f

    if [ "$DELETE" -eq 1 ]; then
      # Supprimer le dossier d'installation
      sudo rm -rf "${SETTINGS_STORAGE}/docker/${USER}/${APPSELECTED}"

      # Supprimer tous les volumes Docker liés à 'coolify'
      docker volume ls --format "{{.Name}}" | grep -i 'coolify' | xargs -r docker volume rm -f
    fi
    ;;
  esac

  if docker ps | grep -q db-$APPSELECTED; then
    docker rm -f db-$APPSELECTED >/dev/null 2>&1
  fi

  if docker ps | grep -q redis-$APPSELECTED; then
    docker rm -f redis-$APPSELECTED >/dev/null 2>&1
  fi

  if docker ps | grep -q memcached-$APPSELECTED; then
    docker rm -f memcached-$APPSELECTED >/dev/null 2>&1
  fi

  checking_errors $?

  ansible-playbook -e pgrole=${APPSELECTED} ${SETTINGS_SOURCE}/includes/config/playbooks/remove_cf_record.yml
  docker system prune -af >/dev/null 2>&1

  echo""
  echo -e "${BLUE}### $APPSELECTED" $(gettext "a été supprimée") "###${NC}"
  echo ""

  req1="delete from applications where name='"
  req2="'"
  req=${req1}${APPSELECTED}${req2}
  sqlite3 ${SETTINGS_SOURCE}/ssddb <<EOF
$req

EOF

}

function check_and_remove_shared_containers() {
  local app="$1"
  # Stremio Base Removal
  local stremio_apps=("zilean" "streamfusion" "stremiocatalogs" "stremiotrakt")
  local stremio_apps_running=false

  for stremio_app in "${stremio_apps[@]}"; do
    if [ "$stremio_app" != "$app" ] && docker ps -q --filter name="$stremio_app" | grep -q .; then
      stremio_apps_running=true
      break
    fi
  done

  if docker ps -a --filter "name=stremio-postgres" --format "{{.Names}}" | grep -q "stremio-postgres"; then
      case "$app" in
        streamfusion)
          docker exec -e PGPASSWORD=stremio stremio-postgres psql -U stremio -d postgres -c "DROP DATABASE IF EXISTS \"streamfusion\";" || echo "Failed to drop streamfusion database."
          ;;
        stremiocatalogs)
          docker exec -e PGPASSWORD=stremio stremio-postgres psql -U stremio -d postgres -c "DROP DATABASE IF EXISTS \"stremio-catalog-db\";" || echo "Failed to drop stremio-catalog-db database."
          ;;
        stremiotrakt)
          docker exec -e PGPASSWORD=stremio stremio-postgres psql -U stremio -d postgres -c "DROP DATABASE IF EXISTS \"stremio-trakt-db\";" || echo "Failed to drop stremio-trakt-db database."
          ;;
        zilean)
          docker exec -e PGPASSWORD=stremio stremio-postgres psql -U stremio -d postgres -c "DROP DATABASE IF EXISTS \"zilean\";" || echo "Failed to drop zilean database."
          ;;
        *)
          docker exec -e PGPASSWORD=stremio stremio-postgres psql -U stremio -d postgres -c "DROP DATABASE IF EXISTS \"$app-db\";" || echo "Failed to drop $app-db database."
          ;;
      esac
  fi

  if ! $stremio_apps_running; then
    docker rm -f stremio-postgres stremio-redis >/dev/null 2>&1 || echo "Failed to remove containers."
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/stremio-redis >/dev/null 2>&1
    sudo rm -rf ${SETTINGS_STORAGE}/docker/${USER}/stremio-postgres >/dev/null 2>&1
  fi
}

function pause() {
  echo ""
  echo -e "${YELLOW}###  --> "$(gettext "APPUYER SUR ENTREE POUR CONTINUER")" <--  ###${NC}"
  read
  echo ""
}

select_seedbox_param() {
  if [ ! -f ${SETTINGS_SOURCE}/ssddb ]; then
    # le fichier de base de données n'est pas là
    # on sort avant de faire une requête, sinon il va se créer
    # et les tests ne seront pas bons
    return 0
  fi
  request="select value from seedbox_params where param ='"${1}"'"
  RETURN=$(sqlite3 ${SETTINGS_SOURCE}/ssddb "${request}")
  if [ $? != 0 ]; then
    echo 0
  else
    echo $RETURN
  fi
}

function update_seedbox_param() {
  # shellcheck disable=SC2027
  request="replace into seedbox_params (param,value) values ('"${1}"','"${2}"')"
  sqlite3 "${SETTINGS_SOURCE}/ssddb" "${request}"
}

function manage_account_yml() {
  # usage
  # manage_account_yml key value
  # key séparées par des points (par exemple user.name ou sub.application.subdomain)
  # pour supprimer une clé, il faut que le value soit égale à un espace
  # ex : manage_account_yml sub.toto.toto toto => va créer la clé sub.toto.toto et lui mettre à la valeur toto
  # ex : manage_account_yml sub.toto.toto " " => va supprimer la clé sub.toto.toto et toutes les sous clés
  if [ -f ${SETTINGS_STORAGE}/.account.lock ]; then
    echo $(gettext "Fichier account locké, impossible de continuer")
    echo "----------------------------------------------"
    echo $(gettext "Présence du fichier") "${SETTINGS_STORAGE}/.account.lock"
    exit 1
  else
    touch ${SETTINGS_STORAGE}/.account.lock
    ansible-vault decrypt "${ANSIBLE_VARS}" >/dev/null 2>&1
    if [ "${2}" = " " ]; then
      ansible-playbook "${SETTINGS_SOURCE}/includes/config/playbooks/manage_account_yml.yml" -e "account_key=${1} account_value=${2}  state=absent"
    else
      ansible-playbook "${SETTINGS_SOURCE}/includes/config/playbooks/manage_account_yml.yml" -e "account_key=${1} account_value=${2} state=present"
    fi
    ansible-vault encrypt "${ANSIBLE_VARS}" >/dev/null 2>&1
    rm -f ${SETTINGS_STORAGE}/.account.lock
  fi
}

function get_from_account_yml() {
  tmpfile=$(mktemp)
  tempresult=$(ansible-playbook ${SETTINGS_SOURCE}/includes/config/playbooks/get_var.yml \
    -e myvar=$1 -e tempfile=${tmpfile} | grep "##RESULT##" | awk -F'##RESULT##' '{print $2}' | xargs)
  rm -f "$tmpfile"

  if [ -z "$tempresult" ]; then
    tempresult=notfound
  fi
  echo "$tempresult"
}

function install_gui() {
  domain=$(get_from_account_yml user.domain)
  tempsubdomain=$(get_from_account_yml sub.gui.gui)
  if [ "${tempsubdomain}" = notfound ]; then
    subdomain_unitaire gui
  fi
  tempauth=$(get_from_account_yml sub.gui.auth)
  if [ "${tempauth}" = notfound ]; then
    auth_unitaire gui
  fi
  subomain=$(get_from_account_yml sub.gui.gui})

  set +a
  export gui_subdomain=$subdomain
  # On install nginx
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/roles/nginx/tasks/main.yml

  echo -e "${CRED}---------------------------------------------------------------${CEND}"
  echo -e "${CRED}          /!\ INSTALLATION EFFECTUEE AVEC SUCCES /!\           ${CEND}"
  echo -e "${CRED}---------------------------------------------------------------${CEND}"
  echo ""
  echo -e "${CRED}---------------------------------------------------------------${CEND}"
  echo -e "${CCYAN}              Adresse de l'interface WebUI                    ${CEND}"
  echo -e "${CCYAN}              https://${subdomain}.${domain}              ${CEND}"
  echo -e "${CRED}---------------------------------------------------------------${CEND}"
  echo ""

  echo -e "\nAppuyer sur ${CCYAN}[ENTREE]${CEND} pour sortir du script..."
  read -r
  exit 0
}

function premier_lancement() {

  sudo chown -R ${USER}: ${SETTINGS_SOURCE}/

  echo $(gettext "Certains composants doivent encore être installés/réglés")
  echo $(gettext "Cette opération va prendre plusieurs minutes selon votre système")
  echo "=================================================================="
  echo -e "\n"$(gettext "Appuyer sur")"${CCYAN}["$(gettext "ENTREE")"]${CEND}" $(gettext "pour continuer")
  read -r

  # installation des paquets nécessaires
  # on passe le user en parametre pour pouvoir créer le /etc/sudoers.d/${USER}
  sudo "${SETTINGS_SOURCE}/includes/config/scripts/prerequis_root.sh" "${USER}"

  # création d'un vault_pass vide

  if [ ! -f "${HOME}/.vault_pass" ]; then
    mypass=$(
      tr -dc A-Za-z0-9 </dev/urandom | head -c 25
      echo ''
    )
    echo "$mypass" >"${HOME}/.vault_pass"

  fi
  
  # création d'un virtualenv
  python3 -m venv ${SETTINGS_SOURCE}/venv

  # activation du venv
  source ${SETTINGS_SOURCE}/venv/bin/activate

  temppath=$(ls ${SETTINGS_SOURCE}/venv/lib)
  pythonpath=${SETTINGS_SOURCE}/venv/lib/${temppath}/site-packages
  export PYTHONPATH=${pythonpath}

  ## Constants
  python3 -m pip install --disable-pip-version-check --upgrade --force-reinstall \
    pip
  pip install wheel
  pip install ansible \
    docker \
    shyaml \
    netaddr \
    dnspython \
    configparser \
    inquirer \
    jsons \
    colorama \
    requests==2.31
  # requests bloqué sur version 2.31 au 28/05/2024, jusqu'à résolution

  ##########################################
  # Pas de configuration existante
  # On installe les prérequis
  ##########################################

  echo $(gettext "Installation en cours ....")

  mkdir -p ~/.ansible/inventories

  ###################################
  # Configuration ansible
  # Pour le user courant uniquement
  ###################################
  mkdir -p /etc/ansible/inventories/ 1>/dev/null 2>&1
  cat << EOF >~/.ansible/inventories/local
  [local]
  127.0.0.1 ansible_connection=local
EOF

  cat <<EOF >~/.ansible.cfg
  [defaults]
  command_warnings = False
  callback_whitelist = profile_tasks
  deprecation_warnings=False
  inventory = ~/.ansible/inventories/local
  interpreter_python=/usr/bin/python3
  vault_password_file = ~/.vault_pass
  log_path=${SETTINGS_SOURCE}/logs/ansible.log
EOF

  echo $(gettext "Création de la configuration en cours")
  # On créé la database
  sqlite3 "${SETTINGS_SOURCE}/ssddb" <<EOF
    create table seedbox_params(param varchar(50) PRIMARY KEY, value varchar(50));
    replace into seedbox_params (param,value) values ('installed',0);
    create table applications(name varchar(50) PRIMARY KEY,
      status integer,
      subdomain varchar(50),
      port integer);
    create table applications_params (appname varchar(50),
      param varachar(50),
      value varchar(50),
      FOREIGN KEY(appname) REFERENCES applications(name));
EOF

  ##################################################
  # Account.yml
  sudo mkdir "${SETTINGS_SOURCE}/logs" > /dev/null 2>&1
  sudo chown -R ${user}: "${SETTINGS_SOURCE}/logs"
  sudo chmod 755 "${SETTINGS_SOURCE}/logs"

  create_dir "${SETTINGS_STORAGE}"
  create_dir "${SETTINGS_STORAGE}/variables"
  create_dir "${SETTINGS_STORAGE}/conf"
  create_dir "${SETTINGS_STORAGE}/vars"
  if [ ! -f "${ANSIBLE_VARS}" ]; then
    mkdir -p "${HOME}/.ansible/inventories/group_vars"
    cp ${SETTINGS_SOURCE}/includes/config/account.yml "${ANSIBLE_VARS}"
  fi

  if [[ -d "${HOME}/.cache" ]]; then
    sudo chown -R "${USER}": "${HOME}/.cache"
  fi
  if [[ -d "${HOME}/.local" ]]; then
    sudo chown -R "${USER}": "${HOME}/.local"
  fi
  if [[ -d "${HOME}/.ansible" ]]; then
    sudo chown -R "${USER}": "${HOME}/.ansible"
  fi

  touch "${SETTINGS_SOURCE}/.prerequis.lock"

  install_common
  # shellcheck disable=SC2162
  echo -e "\e[33m"$(gettext "Les composants sont maintenants tous installés/réglés, poursuite de l'installation")"\e[0m"
  echo""
  # fin du venv
}

function usage() {
  echo ""
  echo "########################################"
  echo "# SSD: Script Seedbox Docker           #"
  echo "# USAGE                                #"
  echo "########################################"
  echo "./seedbox.sh [OPTIONS]"
  echo ""
  echo "Si aucune options passée, le script se lance en interactif"
  echo "----------------------------------------"
  echo "./seedbox.sh [OPTIONS]"
  echo ""
  echo "Si aucune options passée, le script se lance en interactif"
  echo "----------------------------------------"
  echo "Options possibles : "
  echo "--help"
  echo "  Affiche cette aide"
  echo "--migrate"
  echo "  gère la migration de la V1 vers la V2"
  echo ""
  exit 0
}

function log_write() {
  DATE=$(date +'%F %T')
  FILE=${SETTINGS_SOURCE}/logs/seedbox.log
  echo "${DATE} - ${1}" >>${FILE}
  echo "${1}"
}

function check_docker_group() {
  error=0
  if getent group docker >/dev/null 2>&1; then
    if getent group docker | grep ${USER} >/dev/null 2>&1; then
      :
    else
      error=1
      sudo usermod -aG docker ${USER}
    fi
  else
    error=1
    sudo groupadd docker
    sudo usermod -aG docker ${USER}
  fi
  if [ "${error}" = 1 ]; then
    echo "IMPORTANT !"
    echo "==================================================="
    echo $(gettext "Votre utilisateur n'était pas dans le groupe docker")
    echo $(gettext "Il a été ajouté, mais vous devez vous déconnecter/reconnecter pour que la suite du process puisse fonctionner")
    echo "===================================================="
    exit 1
  fi
}

function stocke_public_ip() {
  echo $(gettext "Stockage des adresses ip publiques")
  IPV4=$(curl -s -4 https://ip4.mn83.fr)
  echo "IPV4 = ${IPV4}"
  manage_account_yml network.ipv4 ${IPV4}
  #IPV6=$(dig @resolver1.ipv6-sandbox.opendns.com AAAA myip.opendns.com +short -6)
  #IPV6=$(curl -6 https://ip6.mn83.fr)
  #if [ $? -eq 0 ]; then
  #  echo "IPV6 = ${IPV6}"
  #  manage_account_yml network.ipv6 "a[${IPV6}]"
  #else
  #  echo $(gettext "Aucune adresse ipv6 trouvée")
  #fi
}

function install_environnement() {
  clear
  echo ""
  source "${SETTINGS_SOURCE}/profile.sh"
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/roles/user_environment/tasks/main.yml"
  echo $(gettext "Pour bénéficer des changements, vous devez vous déconnecter/reconnecter")
}

webui() {
    domain=$(get_from_account_yml user.domain)

    PATCH_FILE="${HOME}/.config/ssd/patches"
    PATCH_KEY="20250630_webui"
    FLAG_FILE="${HOME}/.config/ssd/.webui_done"

    local MODE="$1"

    if [ "$MODE" = "force" ]; then
        echo -e "\033[1;31m⚠ Relance forcée de l'installation et de l'animation\033[0m"
        FORCE_PATCH=1 apply_patches
    elif [ "$MODE" = "reinstall" ]; then
        echo -e "\033[1;31m⚠ Réinstallation sélective du patch ${PATCH_KEY}\033[0m"
        FORCE_PATCH="$PATCH_KEY" apply_patches
    fi

    # Vérifie si le patch est présent
    if ! grep -q "$PATCH_KEY" "$PATCH_FILE" 2>/dev/null; then
        [ "$MODE" != "force" ] && [ "$MODE" != "reinstall" ] && return 0
    fi

    # Si déjà installé et pas en mode forcé/réinstall → sortie silencieuse
    if [ -f "$FLAG_FILE" ] && [ "$MODE" != "force" ] && [ "$MODE" != "reinstall" ]; then
        return 0
    fi

    # -------------------------------------------------------------------
    # Ici → soit première fois, soit relance forcée, soit réinstall sélective
    # -------------------------------------------------------------------

    logo_frames=("[SSD]" "<SSD>" "(SSD)" "{SSD}")
    logo_length=${#logo_frames[@]}
    i=0

    duration=120
    interval_ms=200
    steps=$(( (duration * 1000) / interval_ms ))
    bar_length=30

    progress=0
    start_time=$(date +%s)

    for ((count=0; count<=steps; count++)); do
        logo=${logo_frames[$((i % logo_length))]}
        i=$((i+1))

        progress=$((count * 100 / steps))
        if [ $progress -gt 100 ]; then progress=100; fi

        if   [ $progress -lt 30 ]; then phase="Préparation de l’interface..."
        elif [ $progress -lt 70 ]; then phase="Compilation du frontend..."
        elif [ $progress -lt 100 ]; then phase="Optimisation des assets..."
        else phase="Finalisation..."
        fi

        now=$(date +%s)
        elapsed=$((now - start_time))
        remaining=$((duration - elapsed))
        if [ $remaining -lt 0 ]; then remaining=0; fi
        min=$((remaining / 60))
        sec=$((remaining % 60))
        time_left=$(printf "%dm%02ds restantes" "$min" "$sec")

        filled=$((progress * bar_length / 100))
        empty=$((bar_length - filled))
        bar=$(printf "%0.s#" $(seq 1 $filled))
        spaces=$(printf "%0.s." $(seq 1 $empty))

        printf "\r  \033[1;36m%s\033[0m \033[1;33m[%s%s]\033[0m %3d%%  \033[1;37m%s\033[0m | \033[0;36m%s\033[0m" \
          "$logo" "$bar" "$spaces" "$progress" "$phase" "$time_left"

        sleep $(awk "BEGIN {print $interval_ms/1000}")
    done

    printf "\r\033[K"

    # On ne réécrit pas le flag si mode réinstall forcée
    if [ "$MODE" != "force" ] && [ "$MODE" != "reinstall" ]; then
        touch "$FLAG_FILE"
    fi

    log_statusbar "\033[1;32m✔ Interface webui disponible : https://ssdv2.${domain}\033[0m"
}


function affiche_menu_db() {
  if [ -z "$OLDIFS" ]; then
    OLDIFS=${IFS}
  fi
  IFS=$'\n'
  echo -e "${CGREEN}${CEND}"
  start_menu="is null"
  texte_sortie="Sortie du script"
  precedent=""
  if [[ $# -eq 1 ]]; then
    if [ -z "$1" ]; then
      :
    else
      start_menu="=${1}"
      texte_sortie="Menu précédent"
      precedent="${1}"
    fi
  fi
  clear
  logo

  # chargement des menus
  webui
  request="select * from menu where parent_id ${start_menu}"
  sqlite3 "${SETTINGS_SOURCE}/menu" "${request}" | while read -a db_select; do
    IFS='|'
    read -ra db_select2 <<<"$db_select"
    echo -e "${CGREEN}""   ${db_select2[3]})" "$(gettext "${db_select2[1]}")" "${CEND}"
    IFS=$'\n'
  done
  echo -e "${CGREEN}---------------------------------------${CEND}"
  if [ "${precedent}" = "" ]; then
    :
  else
    echo -e "${CGREEN}"   $(gettext "  H) Retour au menu principal")"${CEND}"
    echo -e "${CGREEN}"   $(gettext "  B) Retour au menu précédent")"${CEND}"
  fi
  echo -e "${CGREEN}"   $(gettext "  Q) Quitter")"${CEND}"
  echo -e "${CGREEN}---------------------------------------${CEND}"
  read -p "Votre choix : " PORT_CHOICE

  if [ "${PORT_CHOICE,,}" == "b" ]; then

    request2="select parent_id from menu where id ${start_menu}"
    newchoice=$(sqlite3 ${SETTINGS_SOURCE}/menu $request2)
    affiche_menu_db ${newchoice}
  elif [ "${PORT_CHOICE,,}" == "q" ]; then
    exit 0
  elif [ "${PORT_CHOICE,,}" == "h" ]; then
    # retour au début
    affiche_menu_db
  else
    # on va voir s'il y a une action à faire
    request_action="select action from menu where parent_id ${start_menu} and ordre = ${PORT_CHOICE}"
    action=$(sqlite3 ${SETTINGS_SOURCE}/menu "$request_action")
    if [ -z "$action" ]; then
      : # pas d'action à effectuer
    else
      # on va lancer la fonction qui a été chargée
      IFS=${OLDIFS}
      ${action}
    fi

    req_new_choice="select id from menu where parent_id ${start_menu} and ordre = ${PORT_CHOICE}"
    newchoice=$(sqlite3 ${SETTINGS_SOURCE}/menu "${req_new_choice}")
    request_cpt="select count(*) from menu where parent_id = ${newchoice}"
    cpt=$(sqlite3 ${SETTINGS_SOURCE}/menu "$request_cpt")
    if [ "${cpt}" -eq 0 ]; then
      # pas de sous menu, on va rester sur le même
      newchoice=${precedent}
    fi
    affiche_menu_db ${newchoice}

  fi
  IFS=${OLDIFS}
}

function log_statusbar() {
  tput sc                           #save the current cursor position
  tput cup $(($(tput lines) - 2)) 3 # go to last line
  tput ed
  tput cup $(($(tput lines) - 1)) 3 # go to last line
  echo -e $1
  tput rc # bring the cursor back to the last saved position
}

function choix_appli_sauvegarde() {
  line=$1
  sauve_one_appli ${line}
}

function sauve_symlinks() {
  clear
  logo
  echo -e "${CRED}----------------------------------------${CEND}"
  echo -e "${CCYAN}"$(gettext "Sauvegarde des Symlinks")"${CEND}"
  echo -e "${CRED}----------------------------------------${CEND}"
  ls -1 /home/${USER}/Medias | xargs -I {} sh -c 'if [ -d "/home/${USER}/Medias/{}" ]; then echo {}; fi' | cat -n | sed 's/[ ]\+/ /g' | tr "\t" " " > temp

  # nombre total de lignes dans le fichier temp
  total_lines=$(wc -l < temp)

  # Ajoutez 1 au nombre total de lignes pour obtenir le numéro suivant
  next_line_number=$((total_lines + 1))

  # Incrémentez le numéro de ligne avant d'ajouter "Medias" au fichier temporaire
  echo " $next_line_number Medias" >> temp

  while read LIGNE
  do 
    echo -e "${BLUE}  "$LIGNE"${CEND}"
  done < temp

  echo -e "${CGREEN}---------------------------------------${CEND}"
  echo -e "${CGREEN}  "$(gettext "H) Retour au menu principal")"${CEND}"
  echo -e "${CGREEN}  "$(gettext "Q) Quitter")"${CEND}"
  echo -e "${CGREEN}---------------------------------------${CEND}"
  echo ""
  echo >&2 -n -e "${CGREEN}"$(gettext "Votre choix :") "${CEND}"
  read DOSSIER
  if [ $DOSSIER == h ] || [ $DOSSIER == H ]; then
    affiche_menu_db
  elif [ $DOSSIER == q ] || [ $DOSSIER == Q ]; then
    exit 1
  fi
  APPLI=$(grep $DOSSIER temp | cut -d ' ' -f3)
  
  rm temp
  sauve_one_appli $APPLI
}

function sauve_one_appli() {
  #############################
  # Parametres :
  # $1 = nom de l'appli
  # $2 ((optionnel) : nombre de backups à garder
  # si $2 = 0 => pas de suppression des vieux backups
  # si $2 non renseigné, on reste à 3 backups à garder
  ##############################

  # Variables
  APPLI=$1
  CDAY=$(date +%Y%m%d-%H%M)
  BACKUP_PARTITION=/home/${USER}/backup
  ARCHIVE=$APPLI-$CDAY.tar.gz
  BACKUP_FOLDER=$BACKUP_PARTITION/$APPLI/$ARCHIVE
  remote_backups=BACKUPS

  # Définition des variables de couleurs
  CSI="\033["
  CEND="${CSI}0m"
  CRED="${CSI}1;31m"
  CGREEN="${CSI}1;32m"
  CYELLOW="${CSI}1;33m"
  CCYAN="${CSI}0;36m"

  sudo mkdir -p "${BACKUP_PARTITION}/${APPLI}"

  if [[ "$(basename "${APPLI}")" == "Medias" ]]; then
    SOURCE_DIR="/home/${USER}"
    FOLDER="du Dossier"
  elif [[ -d "/home/${USER}/Medias/${APPLI}" ]]; then
    SOURCE_DIR="/home/${USER}/Medias"
    FOLDER="du Dossier"
  else
    SOURCE_DIR="${SETTINGS_STORAGE}/docker/${USER}"
    FOLDER="de l'Application"
  fi

  REMOTE=$(get_from_account_yml rclone.remote)
  if [ ${REMOTE} == notfound ]; then
    RCLONE=$(grep -B 1 "type" "/home/${USER}/.config/rclone/rclone.conf" | grep -oP '^\[\K[^]]+' | grep -v "zurg" | cat -n | tr "\t" " ")
    if [ -n "$RCLONE" ]; then
      echo ""
      echo -e "${CGREEN}"$(gettext "Remote Rclone disponible")"${CEND}"
      echo "$RCLONE" | while read -r line
      do
        echo -e "${BLUE}  $line ${CEND}"
      done
      echo >&2 -n -e "${CGREEN}"$(gettext "Votre choix : ")"${CEND}"
      read -r REPONSE

      # extraire la ligne correspondant à la réponse choisie
      REMOTE=$(grep -B 1 "type" "/home/${USER}/.config/rclone/rclone.conf" | grep -oP '^\[\K[^]]+' | grep -v "zurg" | sed -n "${REPONSE}p")
      manage_account_yml rclone.remote $REMOTE
      # Affichez la ligne choisie
      echo ""
      echo -e "${BLUE}>" $(gettext "Remote Drive :")"${CEND}" "${CGREEN} $REMOTE${CEND}"
    else
      echo ""
      echo -e "${BLUE}>" $(gettext "Remote Drive :")"${CEND}" "${CGREEN} Non Actif ${CEND}"
    fi
  else
    echo -e "${BLUE}>" $(gettext "Remote Drive :")"${CEND}" "${CGREEN} $REMOTE${CEND}"
  fi

  NB_MAX_BACKUP=3
  ALL_RETENTION=0
  if [ $# == 2 ]; then
    if [ "$2" == 0 ]; then
      ALL_RETENTION=1
    else
      NB_MAX_BACKUP=$2
    fi
  fi

  if [ $ALL_RETENTION -eq 0 ]; then
    echo -e "${CCYAN}>" $(gettext "Nombre de backups à garder") : "$NB_MAX_BACKUP" "${CEND}"
  else
    echo $(gettext "Pas de suppression des vieux backups")
  fi

  if [ "${SOURCE_DIR}" == "${SETTINGS_STORAGE}/docker/${USER}" ]; then
    # Stop APPLI
    echo -e "${CCYAN}>" $(gettext "Arrêt de") "${APPLI}${CEND}"
    docker stop ${APPLI} > /dev/null 2>&1
  fi
  sleep 5

  echo -e "${CCYAN}>" $(gettext "Création de l'archive")"${CEND}"
  mkdir -p $BACKUP_PARTITION/$APPLI
  sudo tar -I pigz -cf $BACKUP_PARTITION/$APPLI/$ARCHIVE -P $SOURCE_DIR/$APPLI
  sleep 2s
  echo -e "${CCYAN}>" $(gettext "Archive conservée dans le dossier /home/${USER}/backup")"${CEND}"

  if [ "${SOURCE_DIR}" == "${SETTINGS_STORAGE}/docker/${USER}" ]; then
  # Restart APPLI
  echo -e "${CCYAN}>" $(gettext "Lancement de") "${APPLI}${CEND}"
  docker start $APPLI > /dev/null 2>&1
  sleep 5
  fi

  if [ ${REMOTE} != notfound ]; then
    echo -e "${CCYAN}>" $(gettext "Envoie Archive vers Google Drive")"${CEND}"
    # Envoie Archive vers Google Drive
    rclone copy "$BACKUP_FOLDER" "$REMOTE:/$remote_backups/$APPLI" --progress
  fi

  # Nombre de sauvegardes effectuées
  nbBackup=$(find $BACKUP_PARTITION -type f -name $APPLI-* | wc -l)
  if [ $ALL_RETENTION -eq 0 ]; then
    if [[ "$nbBackup" -gt "$NB_MAX_BACKUP" ]]; then

      # Archive la plus ancienne
      oldestBackupPath=$(find $BACKUP_PARTITION/$APPLI -type f -name $APPLI-* -printf '%T+ %p\n' | sort | head -n 1 | awk '{print $2}')
      oldestBackupFile=$(find $BACKUP_PARTITION/$APPLI -type f -name $APPLI-* -printf '%T+ %p\n' | sort | head -n 1 | awk '{split($0,a,/\//); print a[6]}')

      # Suppression du backup local
      sudo rm "$oldestBackupPath"

      if [ ${REMOTE} != notfound ]; then
        # Suppression Archive Google Drive
        echo -e "${CCYAN}>" $(gettext "Suppression de l'archive la plus ancienne")"${CEND}"
        rclone delete "$REMOTE:/$remote_backups/$APPLI/$oldestBackupFile" --progress
      fi
    fi
  fi
  echo ""
  echo -e "${CRED}------------------------------------------${CEND}"
  echo -e "${CCYAN}"$(gettext "Sauvegarde $FOLDER $APPLI terminée")"${CEND}"
  echo -e "${CRED}------------------------------------------${CEND}"
  echo -e "\n"$(gettext "Appuyer sur")"${CCYAN} ["$(gettext "ENTREE")"]${CEND}" $(gettext "pour continuer")
  read -r
}

function change_password() {
  echo "#############################################"
  echo $(gettext "Cette procédure va redémarrer traefik")
  echo $(gettext "Pendant cette opération, les interfaces web seront inaccessibles")
  echo >&2 -n -e "${BWHITE}"$(gettext "Saisissez le nouveau password :") "${CEND}"
  read NEWPASS
  manage_account_yml user.pass "${NEWPASS}"
  manage_account_yml user.htpwd $(htpasswd -nb ${USER} ${NEWPASS})
  docker rm -f traefik
  launch_service traefik
}

function relance_container() {
  line=$1
  log_write "Relance du container ${line}" >/dev/null 2>&1
  echo -e "\e[32m"$(gettext "Les volumes ne seront pas supprimés")"\e[0m" 
  echo -e "\e[32m"$(gettext "L'image sera mise à jour si nécessaire")"\e[0m" 
  docker rm -f ${line} > /dev/null 2>&1
  docker rmi $(docker images | grep "$line" | tr -s ' ' | cut -d ' ' -f 3) > /dev/null 2>&1
  echo ""
  launch_service ${line}
  pause
}

function install_plextraktsync() {
  echo -e "\e[32m"$(gettext "Préparation pour le premier lancement de configuration")"\e[0m" 
  echo -e "\e[32m"$(gettext "Assurez vous d'avoir les api Trakt avant de continuer") "https://trakt.tv/oauth/applications/new)""\e[0m" 
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/roles/plextraktsync/tasks/main.yml
  pause
  /usr/local/bin/plextraktsync
  echo $(gettext "L'outil est installé et se lancera automatiquement toutes les heures")
  pause
}

function install_block_public_tracker() {
  echo -e "\e[32m"$(gettext "Block_public_tracker va bloquer les trackers publics (piratebay, etc...) sur votre machine au niveau réseau")"\e[0m"
  echo -e "\e[32m"$(gettext "Ces trackers ne seront plus accessibles")"\e[0m"
  pause
  ansible-playbook ${SETTINGS_SOURCE}/includes/config/playbooks/block_public_tracker.yml
  echo -e "\e[32m"$(gettext "Block_public_tracker a été installé avec succès")"\e[0m"
  pause
}

function relance_tous_services() {
  sqlite3 ${SETTINGS_SOURCE}/ssddb <<EOF >$SERVICESPERUSER
select name from applications;
EOF
  sed -i '/traefik/d' $SERVICESPERUSER
  install_services
}

function apply_patches() {
  touch "${HOME}/.config/ssd/patches"

  for patch in $(ls ${SETTINGS_SOURCE}/patches); do
    # Si on a demandé un patch spécifique
    if [ -n "$FORCE_PATCH" ] && [ "$FORCE_PATCH" != "1" ] && [ "$patch" != "$FORCE_PATCH" ]; then
      continue
    fi

    if grep -q "${patch}" "${HOME}/.config/ssd/patches"; then
      if [ "$FORCE_PATCH" = "1" ] || [ "$FORCE_PATCH" = "$patch" ]; then
        echo "⚠ Réinstallation forcée du patch : ${patch}"
        bash "${SETTINGS_SOURCE}/patches/${patch}" >> "${HOME}/.config/ssd/${patch}.log" 2>&1
      else
        # patch déjà appliqué → on ne fait rien
        :
      fi
    else
      # première installation du patch
      echo "✔ Application du patch : ${patch}"
      bash "${SETTINGS_SOURCE}/patches/${patch}"
      echo "${patch}" >>"${HOME}/.config/ssd/patches"
    fi
  done
}

function install_zurg() {
  update_release_zurg
  ARCHITECTURE=$(dpkg --print-architecture)
  RCLONE_VERSION=$(get_from_account_yml rclone.architecture)
  ZURG_VERSION=$(get_from_account_yml zurg.version)
  create_dir "${HOME}/.config/rclone"
  if [ ${RCLONE_VERSION} == notfound ]; then
    manage_account_yml rclone.architecture "${ARCHITECTURE}"
  fi
  rm -rf "${HOME}/scripts/zurg" > /dev/null 2>&1
  docker rm -f zurg > /dev/null 2>&1
  docker system prune -af > /dev/null 2>&1
  mkdir -p "${HOME}/scripts/zurg" && cd ${HOME}/scripts/zurg
  wget https://github.com/debridmediamanager/zurg-testing/releases/download/${ZURG_VERSION}/zurg-${ZURG_VERSION}-linux-${ARCHITECTURE}.zip > /dev/null 2>&1
  unzip zurg-${ZURG_VERSION}-linux-${ARCHITECTURE}.zip > /dev/null 2>&1
  rm zurg-${ZURG_VERSION}-linux-${ARCHITECTURE}.zip > /dev/null 2>&1
  ZURG_TOKEN=$(get_from_account_yml zurg.token)
  if [ ${ZURG_TOKEN} == notfound ]; then
    echo >&2 -n -e "${BLUE}"$(gettext "Token API pour Zurg (https://real-debrid.com/apitoken) | Appuyer sur [Enter]:") "${CEND}"
    read ZURG_TOKEN
    manage_account_yml zurg.token "${ZURG_TOKEN}"
  else
    echo -e "${BLUE}"$(gettext "Token Zurg déjà renseigné")"${CEND}"
  fi
  # launch zurg
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/playbooks/zurg.yml"
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/roles/rclone/tasks/main.yml"
  echo -e "\n"$(gettext "Appuyer sur")"${CCYAN} ["$(gettext "ENTREE")"]${CEND}" $(gettext "pour continuer")
  read -r
}

function install_zurg_docker() {
  rm -rf "${HOME}/scripts/zurg" > /dev/null 2>&1
  ZURG_TOKEN=$(get_from_account_yml zurg.token)
  if [ ${ZURG_TOKEN} == notfound ]; then
    echo >&2 -n -e "${BLUE}"$(gettext "Token API pour Zurg (https://real-debrid.com/apitoken) | Appuyer sur [Enter]:") "${CEND}"
    read ZURG_TOKEN
    manage_account_yml zurg.token "${ZURG_TOKEN}"
  else
    echo -e "${BLUE}"$(gettext "Token Zurg déjà renseigné")"${CEND}"
  fi
  # launch zurg
  ansible-playbook "${SETTINGS_SOURCE}/includes/dockerapps/generique.yml" --extra-vars "@${SETTINGS_SOURCE}/includes/dockerapps/vars/zurg.yml"
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/roles/rclone/tasks/main.yml"
  echo -e "\n"$(gettext "Appuyer sur")"${CCYAN} ["$(gettext "ENTREE")"]${CEND}" $(gettext "pour continuer")
  read -r
}

function create_folders() {
  echo ""
  create_dir "${HOME}/local"
  create_dir "${HOME}/local/radarr"
  create_dir "${HOME}/local/radarr4k"
  create_dir "${HOME}/local/sonarr"
  create_dir "${HOME}/local/sonarr4k"
  create_dir "${HOME}/Medias"
  echo -e "\e[36m"$(gettext "Noms de dossiers à créer dans Medias ex: Films, Series, Films d'animation etc .. [Enter] | Taper stop une fois terminé")"\e[0m"		
  while :
  do		
    read -p "" EXCLUDEPATH
    mkdir -p ${HOME}/Medias/$EXCLUDEPATH
    if [[ "$EXCLUDEPATH" = "STOP" ]] || [[ "$EXCLUDEPATH" = "stop" ]]; then
      rm -rf ${HOME}/Medias/$EXCLUDEPATH
      break
    fi
  done
}

function install_gluetun {
  source ${SETTINGS_SOURCE}/includes/config/scripts/gluetun.sh
  launch_service gluetun
}

function update_release_zurg() {
  wget https://api.github.com/repos/debridmediamanager/zurg-testing/releases > /dev/null 2>&1
  CURRENT_VERSION=$(get_from_account_yml zurg.version)
  LATEST_VERSION=$(jq '.[] | .tag_name' releases | tr -d '"' | sed -n "1p")
  if [[ ${CURRENT_VERSION} == notfound ]] || [[ ${CURRENT_VERSION} != ${LATEST_VERSION} ]]; then
    manage_account_yml zurg.version "${LATEST_VERSION}"
    echo -e  "${BLUE}"$(gettext "Version Zurg :") "$LATEST_VERSION${CEND}"
  else 
    echo -e  "${BLUE}"$(gettext "Version Zurg :") "$LATEST_VERSION${CEND}"
  fi
  rm releases
}

function choose_version_zurg() {
  echo ""
  wget https://api.github.com/repos/debridmediamanager/zurg-testing/releases > /dev/null 2>&1
  jq '.[] | .tag_name' releases | tr -d '"' | cat -n | sed 's/[ ]\+/ /g' | tr " " " " | tr "\t" " " > temp

  while read LIGNE
  do echo -e "${CCYAN}"$LIGNE"${CEND}"
  done < temp
  echo ""
  echo >&2 -n -e "${CCYAN}"$(gettext "Choisir le numéro de la Version :") "${CEND}"
  read NUMERO_LIGNE
  VERSION=$(sed -n "${NUMERO_LIGNE}p" temp | cut -d ' ' -f 3) 
  manage_account_yml zurg.version "${VERSION}"
  echo -e  "${BLUE}"$(gettext "Version Zurg :") "$VERSION${CEND}"
  ARCHITECTURE=$(dpkg --print-architecture)
  RCLONE_VERSION=$(get_from_account_yml rclone.architecture)
  ZURG_VERSION=$(get_from_account_yml zurg.version)
  create_dir "${HOME}/.config/rclone"
  if [ ${RCLONE_VERSION} == notfound ]; then
    manage_account_yml rclone.architecture "${ARCHITECTURE}"
  fi
  rm -rf "${HOME}/scripts/zurg" > /dev/null 2>&1
  docker rm -f zurg > /dev/null 2>&1
  docker system prune -af > /dev/null 2>&1
  mkdir -p "${HOME}/scripts/zurg" && cd ${HOME}/scripts/zurg
  wget https://github.com/debridmediamanager/zurg-testing/releases/download/${ZURG_VERSION}/zurg-${ZURG_VERSION}-linux-${ARCHITECTURE}.zip > /dev/null 2>&1
  unzip zurg-${ZURG_VERSION}-linux-${ARCHITECTURE}.zip > /dev/null 2>&1
  rm zurg-${ZURG_VERSION}-linux-${ARCHITECTURE}.zip > /dev/null 2>&1
  ZURG_TOKEN=$(get_from_account_yml zurg.token)
  if [ ${ZURG_TOKEN} == notfound ]; then
    echo >&2 -n -e "\e[32m"$(gettext "Token API pour Zurg (https://real-debrid.com/apitoken) | Appuyer sur [Enter]:") " \e[0m"
    read ZURG_TOKEN
    manage_account_yml zurg.token "${ZURG_TOKEN}"
  else
    echo -e "${BLUE}"$(gettext "Token Zurg déjà renseigné")"${CEND}"
  fi
  # launch zurg
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/playbooks/zurg.yml"
  ansible-playbook "${SETTINGS_SOURCE}/includes/config/roles/rclone/tasks/main.yml"
  echo -e "\n"$(gettext "Appuyer sur")"${CCYAN} ["$(gettext "ENTREE")"]${CEND}" $(gettext "pour continuer")
  read -r
}

function get_architecture() {
  architecture=$(dpkg --print-architecture)
  manage_account_yml system.arch "${architecture}"
}

function liste_perso() {
  echo -e "${CRED}-----------------------------------------------------------${CEND}"
  echo -e "${CCYAN}"$(gettext "Liste des applis déjà personnalisées")"${CEND}"                     
  echo -e "${CCYAN}"$(gettext "Vous pouvez à tout moment décider de modifier les fichiers")"${CEND}"
  echo -e "${CCYAN}"$(gettext "Réinitialiser ensuite le container")"${CEND}"                             
  echo -e "${CRED}-----------------------------------------------------------${CEND}"
  echo ""

  folder_path="${SETTINGS_STORAGE}/vars"
  files=$(ls -p "$folder_path" | grep -v /)
  echo -e "\e[32m"$(gettext "Applications Personnalisées : ")"\e[0m"
  if [ -n "$files" ]; then
    echo -e "\e[36m$files\e[0m"
    echo
  else
    echo -e "\e[36m"$(gettext "Aucune application personnalisée.")"\e[0m"
    echo
  fi
}

function applis_perso_create() {
  clear
  logo
  liste_perso
  # Liste des fichiers déjà personnalisés

  echo -e "${CRED}-----------------------------------------------------------${CEND}"
  echo -e "${CCYAN}"ATTENTION !!"${CEND}"                     
  echo -e "${CCYAN}"$(gettext "Cette fonction va copier/créer les fichiers yml choisis")"${CEND}"                     
  echo -e "${CCYAN}"$(gettext "Afin de pouvoir les personnaliser")"${CEND}"
  echo -e "${CCYAN}"$(gettext "Mais ne lancera pas les services associés")"${CEND}"                             
  echo -e "${CRED}-----------------------------------------------------------${CEND}"
  echo ""

  # Nouvelle appli
  echo >&2 -n -e "\e[36m"$(gettext "Configurer une nouvelle application ? (y/n) : ")"\e[0m"
  read choice
  if [[ "$choice" = "Y" ]] || [[ "$choice" = "y" ]]; then
    echo >&2 -n -e "\e[36m"$(gettext "Nouvelle Appli à personnaliser : ")"\e[0m"
    read NOUVELLE
    echo ""
      echo -e "\e[32m"$(gettext "Application non référencée dans la base existante,")"\e[0m \e[36m${NOUVELLE}.yml\e[0m \e[32m"$(gettext "a été créée ds le dossier") "${SETTINGS_STORAGE}vars.\e[0m" 
      echo -e "\e[32m"$(gettext "Une fois personnalisée, elle s'installera à partir du menu Application perso")"\e[0m" 
      create_file "${SETTINGS_STORAGE}/vars/${NOUVELLE}.yml"
      cp "${SETTINGS_SOURCE}/includes/dockerapps/vars/exemple.yml" "${SETTINGS_STORAGE}vars/${NOUVELLE}.yml"
  echo -e "\n"$(gettext "Appuyer sur")"${CCYAN} ["$(gettext "ENTREE")"]${CEND}" $(gettext "pour continuer")
  read -r
  fi  
}

function copie_applis() {
  rm -Rf "${SERVICESPERUSER}" >/dev/null 2>&1
  touch $SERVICESPERUSER
  jq -r '.selected_lines[] | split("-")[0] | gsub("\""; "")' output.json | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' > "$SERVICESPERUSER"
  echo -e "\e[36m##" $(gettext "Copie des fichiers dans le dossier vars") "##\e[0m"  
  while IFS= read -r line; do
    if [ -e "${SETTINGS_SOURCE}/includes/dockerapps/vars/${line}.yml" ]; then
      cp "${SETTINGS_SOURCE}/includes/dockerapps/vars/${line}.yml" "${SETTINGS_STORAGE}vars/${line}.yml"
      echo -e "\e[32m"$(gettext "Copie effectuée pour")"\e[0m \e[36m$line\e[0m" 
    else
      cp "${SETTINGS_SOURCE}/includes/dockerapps/${line}.yml" "${SETTINGS_STORAGE}vars/${line}.yml"
      echo -e "\e[32m"$(gettext "Copie effectuée pour")"\e[0m \e[36m$line\e[0m"
    fi
  done < "$SERVICESPERUSER"
  rm output.json
  rm $SERVICESPERUSER
  echo -e "\n"$(gettext "Appuyer sur")"${CCYAN} ["$(gettext "ENTREE")"]${CEND}" $(gettext "pour continuer")
  read -r
}

function reinit_container() {
  clear
  logo
  liste_perso
  python3 "${SETTINGS_SOURCE}/includes/config/scripts/generique_python.py" reinit_container
}

function install_applis() {
  clear
  logo
  python3 "${SETTINGS_SOURCE}/includes/config/scripts/generique_python.py" install_applis
  rm output.json
}

function suppression_applis() {
  clear  
  logo
  liste_perso
  python3 "${SETTINGS_SOURCE}/includes/config/scripts/generique_python.py" suppression_application
  pause
}

function relance_applis() {
  clear
  logo
  liste_perso
  python3 "${SETTINGS_SOURCE}/includes/config/scripts/generique_python.py" relance_applis
}

function sauvegarde_applis() {
  clear
  logo
  liste_perso
  python3 "${SETTINGS_SOURCE}/includes/config/scripts/generique_python.py" sauvegarde_applis
}

function install_applis_perso() {
  clear
  logo
  python3 "${SETTINGS_SOURCE}/includes/config/scripts/generique_python.py" install_applis_perso
  pause
}

function create_applis_perso() {
  clear
  logo
  python3 "${SETTINGS_SOURCE}/includes/config/scripts/generique_python.py" create_applis_perso
}

function translation() {
  for f in ${SETTINGS_SOURCE}/i18n/*.po; do
    [[ -e "$f" ]] || break # handle the case of no *.po files
    temp=$(basename $f)
    short="${temp:0:2}"
    mkdir -p "i18n/${short}/LC_MESSAGES"
    msgfmt -o "${SETTINGS_SOURCE}/i18n/${short}/LC_MESSAGES/ks.mo" "${SETTINGS_SOURCE}/i18n/${short}.po"
    echo "$(gettext "Generation") ${short} $(gettext "terminée")"
  done
  echo " == $(gettext "Génération des traductions terminées") =="
}

# Fonction pour mettre à jour un ou plusieurs containers Docker avec Watchtower
update_containers() {
  if [ $# -eq 0 ]; then
    echo "Veuillez fournir au moins un nom de container."
    return 1
  fi

  for container_name in "$@"; do
    echo "Mise à jour du container '$container_name' avec Watchtower..."

    # Exécution de Watchtower pour chaque container
    docker run --rm -d --name watchtower_"$container_name" \
      -e WATCHTOWER_CLEANUP=true \
      -v /var/run/docker.sock:/var/run/docker.sock \
      containrrr/watchtower \
      --run-once "$container_name"
    
    if [ $? -eq 0 ]; then
      echo "Mise à jour du container '$container_name' lancée avec succès."
    else
      echo "Échec de la mise à jour du container '$container_name'."
    fi
  done
}

function decypharr() {
launch_service decypharr
}


