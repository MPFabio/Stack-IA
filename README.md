# Stack-IA

Stack d'Intelligence Artificielle local complet avec Ollama, n8n, AnythingLLM, Open WebUI et Traefik.

## Services inclus

| Service | Port | URL Traefik | Description |
|---------|------|-------------|-------------|
| **Traefik** | 80, 443, 8081 | http://traefik.stack-ia.local | Reverse proxy et load balancer |
| **Ollama** | 11434 | http://ollama.stack-ia.local | Serveur de modèles LLM locaux (llama3, mistral, etc.) |
| **Open WebUI** | 3000 | http://webui.stack-ia.local | Interface web moderne pour interagir avec Ollama |
| **n8n** | 5678 | http://n8n.stack-ia.local | Plateforme d'automatisation et de workflows |
| **AnythingLLM** | 3001 | http://anythingllm.stack-ia.local | Gestion de documents avec RAG et chat intelligent |
| **Qdrant** | 6333, 6334 | http://qdrant.stack-ia.local | Base de données vectorielle pour le RAG |
| **PostgreSQL** | 5432 | - | Base de données pour n8n et autres services |
| **Redis** | 6379 | - | Cache pour optimiser les performances |
| **Adminer** | 8080 | http://adminer.stack-ia.local | Interface web pour gérer PostgreSQL |

## Installation rapide

### Prérequis

- Docker et Docker Compose installés
- Au minimum 8 GB de RAM (16 GB recommandé)
- GPU NVIDIA avec CUDA (optionnel mais recommandé pour de meilleures performances)

### Démarrage

1. **Cloner le dépôt**
```bash
git clone https://github.com/MPFabio/Stack-IA.git
cd Stack-IA
```

2. **Configurer les variables d'environnement (optionnel)**
```bash
cp env.example .env
# Modifier .env avec vos valeurs
```

3. **Démarrer tous les services**
```bash
docker compose up -d
```

4. **Vérifier que tous les services sont lancés**
```bash
docker compose ps
```

## Configuration Traefik (Optionnel mais recommandé)

Traefik permet d'accéder à vos services via des **noms de domaine** au lieu de ports.

### Configuration du fichier hosts

**Sur Windows** (en tant qu'administrateur) :
1. Ouvrir `C:\Windows\System32\drivers\etc\hosts`
2. Ajouter ces lignes :

```
127.0.0.1    traefik.stack-ia.local
127.0.0.1    webui.stack-ia.local
127.0.0.1    n8n.stack-ia.local
127.0.0.1    anythingllm.stack-ia.local
127.0.0.1    qdrant.stack-ia.local
127.0.0.1    adminer.stack-ia.local
127.0.0.1    ollama.stack-ia.local
```

**Sur Linux/Mac** :
```bash
sudo nano /etc/hosts
# Ajouter les mêmes lignes que ci-dessus
```

### Accès aux services

Une fois configuré, accédez à vos services via :
- **Open WebUI** : http://webui.stack-ia.local
- **n8n** : http://n8n.stack-ia.local
- **AnythingLLM** : http://anythingllm.stack-ia.local
- **Qdrant** : http://qdrant.stack-ia.local
- **Adminer** : http://adminer.stack-ia.local
- **Traefik Dashboard** : http://traefik.stack-ia.local

**Guide complet** : Voir [TRAEFIK-SETUP.md](./docs/TRAEFIK-SETUP.md)

## Premier usage

### 1. Télécharger des modèles Ollama

```bash
# Se connecter au conteneur Ollama
docker exec -it ollama ollama pull llama3.2

# Autres modèles recommandés
docker exec -it ollama ollama pull mistral
docker exec -it ollama ollama pull nomic-embed-text  # Pour les embeddings
docker exec -it ollama ollama pull codellama  # Pour le code
```

### 2. Accéder aux interfaces

**Deux méthodes d'accès** : via ports directs OU via Traefik (si configuré)

- **Open WebUI** : http://localhost:3000 ou http://webui.stack-ia.local
  - Créer un compte lors de la première visite
  - Sélectionner votre modèle Ollama et commencer à chatter

- **AnythingLLM** : http://localhost:3001 ou http://anythingllm.stack-ia.local
  - Créer un workspace
  - Uploader des documents (PDF, TXT, DOCX, etc.)
  - Poser des questions sur vos documents

- **n8n** : http://localhost:5678 ou http://n8n.stack-ia.local
  - Créer un compte
  - Construire vos workflows d'automatisation
  - Intégrer Ollama dans vos workflows

- **Adminer** : http://localhost:8080 ou http://adminer.stack-ia.local
  - Serveur : `postgres`
  - Utilisateur : `stackia`
  - Mot de passe : voir `docker-compose.yaml` ou `.env`

## Cas d'usage

### 1. Chat local avec vos modèles
Utilisez Open WebUI pour interagir avec vos modèles LLM comme ChatGPT mais en local.

### 2. RAG sur vos documents
AnythingLLM permet de créer une base de connaissances avec vos documents et d'interroger le contenu avec l'IA.

### 3. Automatisation avec IA
n8n peut déclencher des actions basées sur des réponses LLM, créer des workflows complexes intégrant l'IA.

### 4. Développement d'applications IA
Utilisez les APIs exposées pour créer vos propres applications :
- API Ollama : http://localhost:11434
- API Qdrant : http://localhost:6333

## Commandes utiles

```bash
# Démarrer tous les services
docker compose up -d

# Arrêter tous les services
docker compose down

# Voir les logs
docker compose logs -f

# Voir les logs d'un service spécifique
docker compose logs -f ollama

# Redémarrer un service
docker compose restart ollama

# Arrêter et supprimer les volumes ( supprime toutes les données)
docker compose down -v
```

## Configuration avancée

### GPU NVIDIA

Si vous n'avez pas de GPU NVIDIA, commentez cette section dans `docker-compose.yaml` :

```yaml
# deploy:
#   resources:
#     reservations:
#       devices:
#         - driver: nvidia
#           count: all
#           capabilities: [gpu]
```

### Modèles recommandés par usage

| Usage | Modèle | Commande |
|-------|--------|----------|
| Chat général | llama3.2 | `docker exec -it ollama ollama pull llama3.2` |
| Code | codellama | `docker exec -it ollama ollama pull codellama` |
| Français | mistral | `docker exec -it ollama ollama pull mistral` |
| Embeddings | nomic-embed-text | `docker exec -it ollama ollama pull nomic-embed-text` |
| Multimodal | llava | `docker exec -it ollama ollama pull llava` |

### Intégration n8n + Ollama

1. Dans n8n, créer un nouveau workflow
2. Ajouter le node "HTTP Request"
3. Configurer :
   - Method : POST
   - URL : http://ollama:11434/api/generate
   - Body : 
```json
{
  "model": "llama3.2",
  "prompt": "Votre question ici",
  "stream": false
}
```

## Monitoring

Pour surveiller l'utilisation des ressources :

```bash
# Voir l'utilisation CPU/RAM de chaque conteneur
docker stats

# Voir l'espace disque utilisé par les volumes
docker system df -v
```

## Dépannage

### Ollama ne démarre pas
- Vérifiez que le port 11434 n'est pas déjà utilisé
- Si vous n'avez pas de GPU, commentez la section GPU dans docker-compose.yaml

### n8n ne se connecte pas à PostgreSQL
- Attendez quelques secondes que PostgreSQL soit complètement démarré
- Vérifiez les logs : `docker compose logs postgres`

### Manque de mémoire
- Réduisez le nombre de services actifs
- Augmentez la RAM allouée à Docker Desktop
- Utilisez des modèles plus petits (ex: phi3 au lieu de llama3.2)

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## Licence

MIT

## Liens utiles

- [Documentation Ollama](https://github.com/ollama/ollama)
- [Documentation Open WebUI](https://docs.openwebui.com/)
- [Documentation n8n](https://docs.n8n.io/)
- [Documentation AnythingLLM](https://docs.anythingllm.com/)
- [Documentation Qdrant](https://qdrant.tech/documentation/)
- [Documentation Traefik](https://doc.traefik.io/traefik/)

## Documentation du projet

- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - Architecture complète du système
- [TRAEFIK-SETUP.md](./docs/TRAEFIK-SETUP.md) - Guide de configuration Traefik
- [WORKFLOWS.md](./docs/WORKFLOWS.md) - Exemples de workflows n8n
- [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) - Guide de dépannage

