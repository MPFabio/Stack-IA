# Architecture Stack-IA

## Vue d'ensemble

Stack-IA est une architecture microservices complète pour l'intelligence artificielle locale, orchestrée via Docker Compose et Traefik.

```mermaid
graph TB
    subgraph "Couche Accès - Port 80/443"
        TRAEFIK[Traefik Reverse Proxy]
    end
    
    subgraph "Couche Interface Utilisateur"
        WEBUI[Open WebUI<br/>Interface Chat IA]
        ANYTHING[AnythingLLM<br/>RAG & Documents]
        N8N[n8n<br/>Workflows & Automation]
        ADMINER[Adminer<br/>DB Management]
    end
    
    subgraph "Couche IA & Traitement"
        OLLAMA[Ollama<br/>LLM Engine]
        QDRANT[Qdrant<br/>Vector Database]
    end
    
    subgraph "Couche Données"
        POSTGRES[(PostgreSQL<br/>Relational DB)]
        REDIS[(Redis<br/>Cache)]
    end
    
    subgraph "Infrastructure"
        GPU[NVIDIA GPU<br/>CUDA Support]
        VOLUMES[Docker Volumes<br/>Persistent Storage]
    end
    
    TRAEFIK --> WEBUI
    TRAEFIK --> ANYTHING
    TRAEFIK --> N8N
    TRAEFIK --> ADMINER
    TRAEFIK --> OLLAMA
    TRAEFIK --> QDRANT
    
    WEBUI --> OLLAMA
    ANYTHING --> OLLAMA
    ANYTHING --> QDRANT
    N8N --> OLLAMA
    N8N --> POSTGRES
    
    OLLAMA --> GPU
    
    WEBUI -.-> REDIS
    N8N -.-> REDIS
    
    POSTGRES --> VOLUMES
    QDRANT --> VOLUMES
    OLLAMA --> VOLUMES
    REDIS --> VOLUMES
    
    style TRAEFIK fill:#326ce5,stroke:#fff,stroke-width:2px,color:#fff
    style OLLAMA fill:#ff6b6b,stroke:#fff,stroke-width:2px,color:#fff
    style POSTGRES fill:#336791,stroke:#fff,stroke-width:2px,color:#fff
    style REDIS fill:#dc382d,stroke:#fff,stroke-width:2px,color:#fff
    style GPU fill:#76b900,stroke:#fff,stroke-width:2px,color:#fff
```

---

## Composants Principaux

### Couche Reverse Proxy

#### Traefik v2.10
**Rôle** : Point d'entrée unique pour tous les services

| Caractéristique | Valeur |
|----------------|--------|
| Port HTTP | 80 |
| Port HTTPS | 443 |
| Port Dashboard | 8081 |
| Discovery | Automatique via Docker labels |
| SSL | Let's Encrypt (optionnel) |
| Network | stack-ia-network (bridge) |

**Fonctionnalités** :
- Routage basé sur les noms de domaine
- Load balancing automatique
- Génération de certificats SSL
- Dashboard de monitoring temps réel
- Health checks automatiques

---

### Couche Intelligence Artificielle

#### Ollama
**Rôle** : Moteur d'inférence pour les modèles LLM

```mermaid
graph LR
    A[Client Request] --> B[Ollama API :11434]
    B --> C{GPU Available?}
    C -->|Yes| D[CUDA Acceleration]
    C -->|No| E[CPU Processing]
    D --> F[Model Inference]
    E --> F
    F --> G[Response]
    
    style B fill:#ff6b6b,stroke:#333,stroke-width:2px
    style D fill:#76b900,stroke:#333,stroke-width:2px
```

| Caractéristique | Valeur |
|----------------|--------|
| Port | 11434 |
| GPU Support | NVIDIA CUDA (optionnel) |
| Stockage modèles | `/root/.ollama` |
| Format API | REST JSON |
| Modèles supportés | Llama, Mistral, CodeLlama, etc. |

**Modèles recommandés** :
```
llama3.2        (8GB)  - Usage général
mistral         (4GB)  - Optimisé français
codellama       (4GB)  - Génération de code
nomic-embed-text(274MB)- Embeddings (RAG)
phi3            (2.3GB)- Léger et rapide
```

#### Qdrant
**Rôle** : Base de données vectorielle pour RAG (Retrieval Augmented Generation)

| Caractéristique | Valeur |
|----------------|--------|
| Port HTTP | 6333 |
| Port gRPC | 6334 |
| Stockage | `/qdrant/storage` |
| API | REST + gRPC |
| Dashboard | Intégré |

**Utilisation** :
- Stockage des embeddings de documents
- Recherche sémantique
- Similarité vectorielle
- Context enrichment pour LLM

---

### Couche Interface Utilisateur

#### Open WebUI
**Rôle** : Interface de chat moderne similaire à ChatGPT

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant W as Open WebUI
    participant O as Ollama
    participant R as Redis
    
    U->>W: Message
    W->>R: Check cache
    alt Cache hit
        R-->>W: Cached response
    else Cache miss
        W->>O: POST /api/generate
        O-->>W: Streaming response
        W->>R: Store in cache
    end
    W-->>U: Display response
```

| Caractéristique | Valeur |
|----------------|--------|
| Port | 3000 (interne: 8080) |
| Authentification | Oui (WEBUI_AUTH) |
| Sessions | Stockées localement |
| Multi-utilisateurs | Oui |

#### AnythingLLM
**Rôle** : Plateforme RAG complète

**Architecture RAG** :
```
Document → Chunking → Embedding (Ollama) → Vector DB (Qdrant)
                                                     ↓
User Query → Embedding → Similarity Search → Context → LLM → Response
```

| Caractéristique | Valeur |
|----------------|--------|
| Port | 3001 |
| LLM Provider | Ollama |
| Embedding Engine | Ollama (nomic-embed-text) |
| Vector DB | Qdrant |
| Documents supportés | PDF, TXT, DOCX, MD, etc. |

**Flux de traitement** :
1. Upload de documents
2. Chunking intelligent
3. Génération d'embeddings
4. Stockage dans Qdrant
5. Requête utilisateur
6. Recherche vectorielle
7. Augmentation du contexte
8. Génération de réponse

#### n8n
**Rôle** : Plateforme d'automatisation no-code/low-code

| Caractéristique | Valeur |
|----------------|--------|
| Port | 5678 |
| Base de données | PostgreSQL |
| Encryption | AES-256 (N8N_ENCRYPTION_KEY) |
| Webhooks | Supportés |
| Timezone | Europe/Paris |

**Intégrations disponibles** :
- HTTP Request vers Ollama
- PostgreSQL
- Redis
- Webhooks
- 300+ nodes pré-configurés

---

### Couche Données

#### PostgreSQL 16 Alpine
**Rôle** : Base de données relationnelle principale

```mermaid
erDiagram
    N8N-WORKFLOWS ||--o{ N8N-EXECUTIONS : contains
    N8N-WORKFLOWS ||--o{ N8N-CREDENTIALS : uses
    N8N-WORKFLOWS {
        int id PK
        string name
        json nodes
        json connections
        boolean active
    }
    N8N-EXECUTIONS {
        int id PK
        int workflow_id FK
        timestamp started_at
        json data
        string status
    }
    N8N-CREDENTIALS {
        int id PK
        string name
        string type
        blob encrypted_data
    }
```

| Caractéristique | Valeur |
|----------------|--------|
| Port | 5432 |
| Version | 16-alpine |
| Users | stackia (admin), n8n (app) |
| Database | n8n |
| Health check | pg_isready |

#### Redis 7 Alpine
**Rôle** : Cache et stockage clé-valeur

| Caractéristique | Valeur |
|----------------|--------|
| Port | 6379 |
| Persistence | AOF (Append-Only File) |
| Max Memory | 512 MB |
| Eviction Policy | allkeys-lru |
| Health check | redis-cli ping |

**Cas d'usage** :
- Cache de sessions utilisateurs
- Cache de réponses LLM
- Files d'attente de tâches
- Rate limiting

---

## Architecture Réseau

```mermaid
graph TB
    subgraph "Réseau Externe"
        CLIENT[Client Browser]
        DNS[DNS Local<br/>hosts file]
    end
    
    subgraph "Docker Network: stack-ia-network (bridge)"
        subgraph "Ports Exposés"
            P80[":80 → Traefik HTTP"]
            P443[":443 → Traefik HTTPS"]
            P8081[":8081 → Traefik Dashboard"]
            P3000[":3000 → Open WebUI"]
            P3001[":3001 → AnythingLLM"]
            P5678[":5678 → n8n"]
            P8080[":8080 → Adminer"]
            P6333[":6333 → Qdrant HTTP"]
            P11434[":11434 → Ollama API"]
        end
        
        subgraph "Communication Interne"
            INT[Réseau bridge interne<br/>Résolution DNS automatique]
        end
    end
    
    CLIENT --> DNS
    DNS --> P80
    DNS --> P443
    CLIENT --> P3000
    CLIENT --> P3001
    
    P80 --> INT
    P443 --> INT
    INT -.->|ollama:11434| OLLAMA_INT[Ollama]
    INT -.->|postgres:5432| PG_INT[PostgreSQL]
    INT -.->|redis:6379| REDIS_INT[Redis]
    
    style P80 fill:#326ce5,stroke:#fff,stroke-width:2px,color:#fff
    style P443 fill:#326ce5,stroke:#fff,stroke-width:2px,color:#fff
    style INT fill:#f0f0f0,stroke:#333,stroke-width:2px
```

### Résolution DNS

**Externe (via /etc/hosts ou C:\Windows\System32\drivers\etc\hosts)** :
```
127.0.0.1    traefik.stack-ia.local
127.0.0.1    webui.stack-ia.local
127.0.0.1    n8n.stack-ia.local
127.0.0.1    anythingllm.stack-ia.local
127.0.0.1    qdrant.stack-ia.local
127.0.0.1    adminer.stack-ia.local
127.0.0.1    ollama.stack-ia.local
```

**Interne (Docker DNS)** :
- Chaque conteneur est accessible par son nom de service
- Exemple : `http://ollama:11434` depuis n8n
- Exemple : `http://postgres:5432` depuis n8n
- Résolution automatique via le réseau bridge

---

## Persistance des Données

```mermaid
graph LR
    subgraph "Docker Volumes"
        V1[traefik_letsencrypt<br/>Certificats SSL]
        V2[traefik_logs<br/>Logs Traefik]
        V3[ollama_data<br/>Modèles LLM]
        V4[open-webui_data<br/>Configs & Sessions]
        V5[postgres_data<br/>Base de données]
        V6[n8n_data<br/>Workflows & Credentials]
        V7[anythingllm_data<br/>Configs]
        V8[anythingllm_documents<br/>Documents uploadés]
        V9[anythingllm_outputs<br/>Fichiers générés]
        V10[qdrant_data<br/>Vecteurs & Index]
        V11[redis_data<br/>Snapshots RDB]
    end
    
    subgraph "Système Hôte"
        HOST[/var/lib/docker/volumes/]
    end
    
    V1 --> HOST
    V2 --> HOST
    V3 --> HOST
    V4 --> HOST
    V5 --> HOST
    V6 --> HOST
    V7 --> HOST
    V8 --> HOST
    V9 --> HOST
    V10 --> HOST
    V11 --> HOST
    
    style V3 fill:#ff6b6b,stroke:#333,stroke-width:2px
    style V5 fill:#336791,stroke:#333,stroke-width:2px
    style V10 fill:#ff9f43,stroke:#333,stroke-width:2px
```

### Espace disque typique

| Volume | Taille estimée | Croissance |
|--------|---------------|------------|
| ollama_data | 5-50 GB | Par modèle téléchargé |
| postgres_data | 100-500 MB | Workflows & executions |
| qdrant_data | 1-10 GB | Documents indexés |
| anythingllm_documents | 1-100 GB | Documents uploadés |
| redis_data | 50-512 MB | Cache (limité) |
| Autres | < 1 GB | Configuration |

---

## Flux de Données

### Scénario 1 : Chat Simple (Open WebUI)

```mermaid
sequenceDiagram
    autonumber
    participant U as Utilisateur
    participant T as Traefik
    participant W as Open WebUI
    participant O as Ollama
    participant G as GPU
    
    U->>T: GET webui.stack-ia.local
    T->>W: Forward request
    W-->>U: Page HTML
    
    U->>W: POST /api/chat<br/>{"model": "llama3.2", "message": "..."}
    W->>O: POST /api/generate
    O->>G: CUDA inference
    G-->>O: Tokens
    O-->>W: Stream tokens
    W-->>U: Display response
```

### Scénario 2 : RAG avec AnythingLLM

```mermaid
sequenceDiagram
    autonumber
    participant U as Utilisateur
    participant A as AnythingLLM
    participant O as Ollama
    participant Q as Qdrant
    
    rect rgb(240, 240, 240)
        Note over U,Q: Phase 1: Indexation
        U->>A: Upload PDF
        A->>A: Extract & Chunk text
        loop Pour chaque chunk
            A->>O: POST /api/embeddings<br/>model: nomic-embed-text
            O-->>A: Vector [768 dimensions]
            A->>Q: Store vector + metadata
        end
    end
    
    rect rgb(220, 240, 255)
        Note over U,Q: Phase 2: Requête
        U->>A: Question: "..."
        A->>O: Generate query embedding
        O-->>A: Query vector
        A->>Q: Similarity search (top 5)
        Q-->>A: Relevant chunks
        A->>A: Build context
        A->>O: Generate with context
        O-->>A: Final answer
        A-->>U: Response with sources
    end
```

### Scénario 3 : Workflow n8n

```mermaid
sequenceDiagram
    autonumber
    participant W as Webhook
    participant N as n8n
    participant O as Ollama
    participant P as PostgreSQL
    participant E as Email/API
    
    W->>N: POST /webhook/xyz<br/>Trigger event
    N->>P: Log execution start
    N->>O: Generate summary
    O-->>N: LLM response
    N->>N: Process data
    N->>E: Send notification
    N->>P: Log success
    N-->>W: 200 OK
```

---

## Stack Technique

### Technologies Principales

| Composant | Technologie | Version | Langage |
|-----------|-------------|---------|---------|
| Reverse Proxy | Traefik | 2.10 | Go |
| LLM Engine | Ollama | latest | Go |
| Chat UI | Open WebUI | main | Python/Svelte |
| RAG Platform | AnythingLLM | latest | Node.js/React |
| Automation | n8n | latest | Node.js/Vue |
| Vector DB | Qdrant | latest | Rust |
| Relational DB | PostgreSQL | 16-alpine | C |
| Cache | Redis | 7-alpine | C |
| DB Admin | Adminer | latest | PHP |

### Orchestration

```yaml
Docker Compose v3.8
├── Services: 9
├── Volumes: 11
├── Networks: 1 (bridge)
└── Deployment: docker compose up -d
```

---

## Patterns & Bonnes Pratiques

### 1. Microservices Architecture
Chaque service est isolé, scalable indépendamment, et communique via APIs REST.

### 2. Reverse Proxy Pattern
Traefik comme single entry point avec routing dynamique.

### 3. Service Discovery
Découverte automatique via labels Docker - pas de configuration manuelle.

### 4. Health Checks
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U stackia"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### 5. Separation of Concerns
- **Presentation** : Open WebUI, AnythingLLM, n8n UI
- **Business Logic** : n8n workflows, AnythingLLM RAG
- **Data** : PostgreSQL, Qdrant, Redis
- **Infrastructure** : Traefik, Docker

### 6. Configuration Externe
Toutes les configurations sensibles dans `.env`, jamais hardcodées.

### 7. Volumes Named
Persistance explicite avec volumes nommés pour faciliter backup/restore.

---

## Sécurité

### Authentification

| Service | Auth Méthode | Default |
|---------|--------------|---------|
| Open WebUI | Local users | Premier = admin |
| AnythingLLM | Local users | Workspace-based |
| n8n | Local users | Premier = owner |
| Adminer | PostgreSQL creds | Aucun user par défaut |
| Traefik Dashboard | None | Accessible localement |

### Encryption

```
├── n8n credentials : AES-256 (N8N_ENCRYPTION_KEY)
├── Open WebUI sessions : WEBUI_SECRET_KEY
├── PostgreSQL password : Plain text (docker network isolé)
└── Traefik SSL : Let's Encrypt (optionnel)
```

### Réseau

- Réseau Docker bridge isolé
- Pas d'exposition directe des DBs (postgres, redis)
- Firewall au niveau de l'hôte recommandé
- Traefik comme seul point d'entrée

---

## Scalabilité

### Horizontale (Future)

```mermaid
graph TB
    LB[Load Balancer]
    
    subgraph "Instance 1"
        O1[Ollama]
        W1[WebUI]
    end
    
    subgraph "Instance 2"
        O2[Ollama]
        W2[WebUI]
    end
    
    subgraph "Shared"
        P[(PostgreSQL)]
        Q[(Qdrant)]
        R[(Redis)]
    end
    
    LB --> O1
    LB --> O2
    W1 --> O1
    W2 --> O2
    W1 --> R
    W2 --> R
    O1 -.-> Q
    O2 -.-> Q
```

### Verticale (Actuelle)

- Augmenter RAM Docker : Settings → Resources → Memory
- Ajouter GPU plus puissant
- Utiliser SSD pour volumes
- Augmenter `max_memory` Redis si besoin

---

## Monitoring & Observabilité

### Logs

```bash
# Tous les services
docker compose logs -f

# Service spécifique
docker compose logs -f ollama

# Avec timestamps
docker compose logs -f --timestamps
```

### Métriques

```bash
# Ressources temps réel
docker stats

# Espace disque
docker system df -v

# Santé des services
docker compose ps
```

### Traefik Dashboard

Accès : `http://traefik.stack-ia.local` ou `http://localhost:8081`

Informations disponibles :
- Services actifs
- Routes configurées
- Middlewares appliqués
- Santé des backends
- Métriques HTTP

---

## Évolutions Futures

### Court terme
- [ ] Ajout de Prometheus + Grafana pour métriques
- [ ] Backup automatisé des volumes
- [ ] SSL Let's Encrypt en production
- [ ] Authentication centralisée (OAuth2)

### Moyen terme
- [ ] Kubernetes migration
- [ ] Multi-GPU support
- [ ] Model serving distribué
- [ ] CI/CD pipeline

### Long terme
- [ ] Multi-région deployment
- [ ] Auto-scaling basé sur charge
- [ ] ML Ops pipeline complet
- [ ] Fine-tuning infrastructure

---

## Diagramme Complet du Système

```mermaid
flowchart TB
    subgraph External["Accès Externe"]
        USER[Utilisateur]
        BROWSER[Navigateur Web]
    end
    
    subgraph DNS["DNS Local"]
        HOSTS[/etc/hosts<br/>127.0.0.1 *.stack-ia.local]
    end
    
    subgraph Docker["Docker Engine"]
        subgraph Network["stack-ia-network"]
            TRAEFIK[Traefik<br/>:80,:443,:8081]
            
            subgraph UI["Interface Layer"]
                WEBUI[Open WebUI<br/>:3000]
                ANYTHING[AnythingLLM<br/>:3001]
                N8N[n8n<br/>:5678]
                ADMINER[Adminer<br/>:8080]
            end
            
            subgraph AI["AI Layer"]
                OLLAMA[Ollama<br/>:11434]
                QDRANT[Qdrant<br/>:6333,:6334]
            end
            
            subgraph Data["Data Layer"]
                POSTGRES[(PostgreSQL<br/>:5432)]
                REDIS[(Redis<br/>:6379)]
            end
        end
        
        subgraph Storage["Volumes"]
            VOL1[ollama_data<br/>5-50 GB]
            VOL2[postgres_data<br/>100-500 MB]
            VOL3[qdrant_data<br/>1-10 GB]
            VOL4[redis_data<br/>50-512 MB]
        end
    end
    
    subgraph Hardware["Infrastructure"]
        GPU[NVIDIA GPU<br/>CUDA]
        CPU[CPU]
        DISK[Disk Storage]
    end
    
    USER --> BROWSER
    BROWSER --> HOSTS
    HOSTS --> TRAEFIK
    
    TRAEFIK --> WEBUI
    TRAEFIK --> ANYTHING
    TRAEFIK --> N8N
    TRAEFIK --> ADMINER
    TRAEFIK --> QDRANT
    TRAEFIK --> OLLAMA
    
    WEBUI --> OLLAMA
    ANYTHING --> OLLAMA
    ANYTHING --> QDRANT
    N8N --> OLLAMA
    N8N --> POSTGRES
    
    OLLAMA --> GPU
    OLLAMA --> CPU
    
    WEBUI -.Cache.-> REDIS
    N8N -.Cache.-> REDIS
    
    OLLAMA --> VOL1
    POSTGRES --> VOL2
    QDRANT --> VOL3
    REDIS --> VOL4
    
    VOL1 --> DISK
    VOL2 --> DISK
    VOL3 --> DISK
    VOL4 --> DISK
    
    style TRAEFIK fill:#326ce5,stroke:#fff,stroke-width:3px,color:#fff
    style OLLAMA fill:#ff6b6b,stroke:#fff,stroke-width:2px,color:#fff
    style POSTGRES fill:#336791,stroke:#fff,stroke-width:2px,color:#fff
    style REDIS fill:#dc382d,stroke:#fff,stroke-width:2px,color:#fff
    style QDRANT fill:#ff9f43,stroke:#fff,stroke-width:2px,color:#fff
    style GPU fill:#76b900,stroke:#fff,stroke-width:2px,color:#fff
```

---

## Références

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Ollama Documentation](https://github.com/ollama/ollama)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [n8n Documentation](https://docs.n8n.io/)

---

**Dernière mise à jour** : 2025-01-06  
**Version** : 1.0  
**Auteur** : Stack-IA Project

