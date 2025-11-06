# Configuration Traefik pour Stack-IA

## Qu'est-ce que Traefik ?

Traefik est un **reverse proxy** moderne qui permet d'accéder à tous vos services via des **noms de domaine** au lieu de ports.

### Sans Traefik (avant) :
- Open WebUI : `http://localhost:3000`
- n8n : `http://localhost:5678`
- AnythingLLM : `http://localhost:3001`

### Avec Traefik (maintenant) :
- Open WebUI : `http://webui.stack-ia.local`
- n8n : `http://n8n.stack-ia.local`
- AnythingLLM : `http://anythingllm.stack-ia.local`

---

## Configuration requise

### 1. Configurer le fichier hosts (DNS local)

#### Sur Windows :

1. **Ouvrir Notepad en tant qu'administrateur**
   - Chercher "Notepad" dans le menu Démarrer
   - Clic droit → "Exécuter en tant qu'administrateur"

2. **Ouvrir le fichier hosts**
   - Fichier → Ouvrir
   - Naviguer vers : `C:\Windows\System32\drivers\etc\hosts`
   - Changer le filtre de "Fichiers texte" à "Tous les fichiers"

3. **Ajouter ces lignes à la fin du fichier** :

```
# Stack-IA - Traefik
127.0.0.1    traefik.stack-ia.local
127.0.0.1    webui.stack-ia.local
127.0.0.1    n8n.stack-ia.local
127.0.0.1    anythingllm.stack-ia.local
127.0.0.1    qdrant.stack-ia.local
127.0.0.1    adminer.stack-ia.local
127.0.0.1    ollama.stack-ia.local
```

4. **Sauvegarder le fichier**

#### Sur Linux/Mac :

```bash
sudo nano /etc/hosts
```

Ajouter les mêmes lignes que ci-dessus, puis sauvegarder (Ctrl+X, Y, Enter).

---

## Démarrage avec Traefik

### Option 1 : Avec GPU (recommandé pour vous avec RTX 3050)

```bash
# Créer le fichier .env
cp env.example .env

# Démarrer tous les services
docker compose up -d
```

### Option 2 : Sans GPU

```bash
# Créer le fichier .env
cp env.example .env

# Démarrer avec la config no-gpu
docker compose -f docker-compose-no-gpu.yaml up -d
```

---

## Accès aux services

Une fois démarrés, vous pouvez accéder à vos services via :

| Service | URL avec Traefik | Port direct (encore accessible) |
|---------|------------------|----------------------------------|
| **Traefik Dashboard** | http://traefik.stack-ia.local | http://localhost:8081 |
| **Open WebUI** | http://webui.stack-ia.local | http://localhost:3000 |
| **n8n** | http://n8n.stack-ia.local | http://localhost:5678 |
| **AnythingLLM** | http://anythingllm.stack-ia.local | http://localhost:3001 |
| **Qdrant Dashboard** | http://qdrant.stack-ia.local | http://localhost:6333/dashboard |
| **Adminer** | http://adminer.stack-ia.local | http://localhost:8080 |
| **Ollama API** | http://ollama.stack-ia.local | http://localhost:11434 |

---

## Vérification

### Tester que Traefik fonctionne :

1. **Ouvrir le dashboard Traefik** : http://traefik.stack-ia.local
   - Vous devriez voir tous vos services listés

2. **Tester un service** : http://webui.stack-ia.local
   - Open WebUI devrait s'afficher

### En cas de problème :

```bash
# Vérifier les logs de Traefik
docker logs traefik

# Vérifier que tous les services sont démarrés
docker compose ps
```

---

## SSL/HTTPS (Optionnel - pour production)

Par défaut, Traefik est configuré pour **HTTP uniquement** (développement local).

Pour activer **HTTPS avec Let's Encrypt** :

1. **Modifier `.env`** :
```env
ENABLE_SSL=true
LETS_ENCRYPT_STAGING=false  # true pour tester, false pour production
ACME_EMAIL=votre-email@example.com
```

2. **Redémarrer les services** :
```bash
docker compose restart traefik
```

**Note** : Let's Encrypt ne fonctionne que si vous avez un **vrai nom de domaine** accessible depuis Internet. Pour le développement local, restez en HTTP.

---

## Personnalisation

### Changer les noms de domaine

Modifiez le fichier `.env` :

```env
DOMAIN_SUFFIX=mon-stack.local
WEBUI_DOMAIN=chat.mon-stack.local
N8N_DOMAIN=automation.mon-stack.local
# etc.
```

N'oubliez pas de mettre à jour votre fichier `hosts` en conséquence !

---

## Avantages de Traefik

**URLs propres** : Plus besoin de se souvenir des ports  
**Découverte automatique** : Traefik détecte automatiquement les nouveaux services  
**Load balancing** : Peut équilibrer la charge entre plusieurs instances  
**SSL automatique** : Génération et renouvellement automatique des certificats  
**Dashboard** : Visualisation de tous vos services en temps réel

---

## Dépannage

### "Ce site est inaccessible"

1. Vérifier que le fichier `hosts` est bien configuré
2. Vérifier que Traefik est démarré : `docker ps | grep traefik`
3. Vider le cache DNS : `ipconfig /flushdns` (Windows)

### "502 Bad Gateway"

Le service backend n'est pas démarré. Vérifier avec :
```bash
docker compose ps
docker compose logs <nom-du-service>
```

### Ports déjà utilisés

Si le port 80 ou 443 est déjà utilisé sur votre machine :

1. **Identifier le processus** :
```bash
# Windows
netstat -ano | findstr :80

# Linux/Mac
sudo lsof -i :80
```

2. **Modifier les ports dans docker-compose.yaml** :
```yaml
traefik:
  ports:
    - "8888:80"    # Utiliser 8888 au lieu de 80
    - "8443:443"
```

Puis accéder via : `http://webui.stack-ia.local:8888`

---

## Ressources

- [Documentation Traefik](https://doc.traefik.io/traefik/)
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Labels Traefik](https://doc.traefik.io/traefik/routing/providers/docker/)

