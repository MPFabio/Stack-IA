# Guide de dépannage 🔧

Ce guide vous aide à résoudre les problèmes courants avec Stack-IA.

## Problèmes de démarrage

### Docker ne démarre pas

**Symptômes** :
```
Cannot connect to the Docker daemon
```

**Solutions** :
1. Vérifiez que Docker Desktop est lancé
2. Sur Linux, lancez le service : `sudo systemctl start docker`
3. Vérifiez les permissions : `sudo usermod -aG docker $USER` puis déconnectez/reconnectez

### Ollama ne démarre pas avec GPU

**Symptômes** :
```
could not select device driver "nvidia"
```

**Solutions** :
1. Vérifiez que NVIDIA Container Toolkit est installé :
```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

2. Si l'erreur persiste, utilisez la version sans GPU :
```bash
docker compose -f docker-compose-no-gpu.yaml up -d
```

3. Ou commentez la section GPU dans `docker-compose.yaml` :
```yaml
# deploy:
#   resources:
#     reservations:
#       devices:
#         - driver: nvidia
#           count: all
#           capabilities: [gpu]
```

### Port déjà utilisé

**Symptômes** :
```
Bind for 0.0.0.0:3000 failed: port is already allocated
```

**Solutions** :
1. Identifiez le processus utilisant le port :
```bash
# Linux/Mac
lsof -i :3000

# Windows
netstat -ano | findstr :3000
```

2. Modifiez le port dans `docker-compose.yaml` :
```yaml
ports:
  - "3005:8080"  # Utilise 3005 au lieu de 3000
```

## 🔌 Problèmes de connexion

### n8n ne se connecte pas à PostgreSQL

**Symptômes** :
```
FATAL: password authentication failed for user "n8n"
```

**Solutions** :
1. Vérifiez que PostgreSQL est démarré :
```bash
docker compose ps postgres
```

2. Recréez les conteneurs :
```bash
docker compose down
docker compose up -d
```

3. Vérifiez les variables d'environnement dans `.env` ou `docker-compose.yaml`

### Open WebUI ne peut pas contacter Ollama

**Symptômes** :
- "Cannot connect to Ollama"
- Erreur de connexion dans l'interface

**Solutions** :
1. Vérifiez qu'Ollama est en cours d'exécution :
```bash
docker compose logs ollama
```

2. Testez l'API Ollama :
```bash
curl http://localhost:11434/api/tags
```

3. Vérifiez que `OLLAMA_BASE_URL` est correctement configuré dans Open WebUI :
```yaml
environment:
  - OLLAMA_BASE_URL=http://ollama:11434
```

### AnythingLLM ne trouve pas les modèles

**Symptômes** :
- Aucun modèle disponible dans la liste
- Erreur "No models found"

**Solutions** :
1. Téléchargez les modèles requis :
```bash
docker exec -it ollama ollama pull llama3.2
docker exec -it ollama ollama pull nomic-embed-text
```

2. Vérifiez que les modèles sont bien installés :
```bash
docker exec -it ollama ollama list
```

3. Redémarrez AnythingLLM :
```bash
docker compose restart anythingllm
```

## 💾 Problèmes de performance

### Les modèles sont très lents

**Solutions** :

1. **Sans GPU** : Utilisez des modèles plus petits
```bash
# Au lieu de llama3.2 (8GB)
docker exec -it ollama ollama pull phi3  # 2.3GB
```

2. **Avec GPU** : Vérifiez que le GPU est utilisé
```bash
docker exec -it ollama nvidia-smi
```

3. **Augmentez la RAM** de Docker Desktop :
- Docker Desktop → Settings → Resources → Memory
- Recommandé : Au moins 8 GB, idéalement 16 GB

4. **Limitez le nombre de services** :
```bash
# Démarrez uniquement les services essentiels
docker compose up -d ollama open-webui
```

### Mémoire saturée

**Symptômes** :
```
Error: Out of memory
Container killed
```

**Solutions** :

1. Vérifiez l'utilisation mémoire :
```bash
docker stats
```

2. Limitez la mémoire de Redis (déjà configuré à 512MB)

3. Utilisez des modèles quantizés :
```bash
# Modèles Q4 = 4-bit quantization (plus petits)
docker exec -it ollama ollama pull llama3.2:latest
```

4. Nettoyez les conteneurs et images inutilisés :
```bash
docker system prune -a
```

## Problèmes de données

### Perte de données après redémarrage

**Cause** : Les volumes Docker ont été supprimés

**Prévention** :
1. Ne jamais utiliser `docker compose down -v` sauf si vous voulez tout supprimer
2. Utiliser `docker compose down` (sans -v) pour arrêter sans supprimer les volumes

**Restauration** :
Si vous avez des sauvegardes (voir section Backup), restaurez-les :
```bash
# Exemple pour restaurer n8n
docker run --rm -v stack-ia_n8n_data:/data -v $(pwd)/backups:/backup alpine sh -c "cd /data && tar xzf /backup/n8n-YYYYMMDD-HHMMSS.tar.gz"
```

### Les modèles Ollama disparaissent

**Solutions** :
1. Vérifiez que le volume existe :
```bash
docker volume ls | grep ollama
```

2. Vérifiez le montage du volume dans le conteneur :
```bash
docker inspect ollama | grep -A 10 Mounts
```

3. Re-téléchargez les modèles si nécessaire :
```bash
docker exec -it ollama ollama pull llama3.2
```

## Problèmes de sécurité

### Accès refusé à Open WebUI

**Solutions** :
1. Réinitialisez les credentials en recréant le conteneur :
```bash
docker compose down open-webui
docker volume rm stack-ia_open-webui_data
docker compose up -d open-webui
```

2. Vérifiez que `WEBUI_AUTH=true` dans la configuration

### Changement du mot de passe PostgreSQL

```bash
# 1. Accédez au conteneur
docker exec -it postgres psql -U stackia

# 2. Changez le mot de passe
ALTER USER stackia WITH PASSWORD 'nouveau_mot_de_passe';
\q

# 3. Mettez à jour docker-compose.yaml et redémarrez
docker compose restart
```

## Débogage avancé

### Voir les logs en temps réel

```bash
# Tous les services
docker compose logs -f

# Un service spécifique
docker compose logs -f ollama

# Dernières 100 lignes
docker compose logs --tail=100 n8n
```

### Accéder au shell d'un conteneur

```bash
# Ollama
docker exec -it ollama /bin/bash

# PostgreSQL
docker exec -it postgres psql -U stackia

# Redis
docker exec -it redis redis-cli
```

### Tester les connexions réseau

```bash
# Depuis un conteneur, tester la connexion à un autre
docker exec -it open-webui ping ollama
docker exec -it n8n curl http://ollama:11434/api/tags
```

### Inspecter les volumes

```bash
# Lister tous les volumes
docker volume ls

# Inspecter un volume
docker volume inspect stack-ia_ollama_data

# Voir le contenu d'un volume
docker run --rm -v stack-ia_ollama_data:/data alpine ls -la /data
```

## Monitoring

### Dashboard de monitoring simple

Créez un fichier `monitoring.sh` :

```bash
#!/bin/bash

clear
echo "=== Stack-IA Monitoring ==="
echo ""
echo "Services Status:"
docker compose ps
echo ""
echo "Resource Usage:"
docker stats --no-stream
echo ""
echo "Disk Usage:"
docker system df
echo ""
echo "Volume Sizes:"
docker system df -v | grep stack-ia
```

### Alertes automatiques

Pour être alerté en cas de problème, utilisez un workflow n8n qui vérifie l'état des services toutes les 5 minutes.

## Réinitialisation complète

Si rien ne fonctionne, réinitialisation totale :

```bash
# ATTENTION : Ceci supprime TOUTES les données

# 1. Arrêter tous les conteneurs
docker compose down

# 2. Supprimer tous les volumes
docker volume rm stack-ia_ollama_data
docker volume rm stack-ia_open-webui_data
docker volume rm stack-ia_n8n_data
docker volume rm stack-ia_anythingllm_data
docker volume rm stack-ia_postgres_data
docker volume rm stack-ia_qdrant_data
docker volume rm stack-ia_redis_data

# 3. Nettoyer le système Docker
docker system prune -a

# 4. Redémarrer
docker compose up -d

# 5. Re-télécharger les modèles
docker exec -it ollama ollama pull llama3.2
```

## Obtenir de l'aide

Si votre problème persiste :

1. **Collectez les informations** :
```bash
# Versions
docker --version
docker compose version

# Logs
docker compose logs > logs.txt

# Configuration
docker compose config > config.txt
```

2. **Ouvrez une issue** sur GitHub avec :
   - Description du problème
   - Étapes pour reproduire
   - Logs pertinents
   - Version de Docker
   - Système d'exploitation

3. **Vérifiez les issues existantes** : Quelqu'un a peut-être déjà eu le même problème !

## Ressources utiles

- [Documentation Docker](https://docs.docker.com/)
- [Documentation Ollama](https://github.com/ollama/ollama/tree/main/docs)
- [Open WebUI Troubleshooting](https://docs.openwebui.com/)
- [n8n Forum](https://community.n8n.io/)
- [Stack Overflow - Docker tag](https://stackoverflow.com/questions/tagged/docker)

