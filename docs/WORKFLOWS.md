# Workflows n8n - Exemples d'intégration avec Ollama 🔄

Ce document présente des exemples de workflows n8n intégrant Ollama pour créer des automatisations intelligentes.

## Workflow 1 : Assistant Email avec IA

**Description** : Répondre automatiquement aux emails avec l'aide d'Ollama

### Nodes nécessaires :
1. **Email Trigger** (IMAP) - Surveille les nouveaux emails
2. **HTTP Request** - Appelle Ollama pour générer une réponse
3. **Email Send** - Envoie la réponse

### Configuration HTTP Request pour Ollama :

```json
{
  "method": "POST",
  "url": "http://ollama:11434/api/generate",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "model": "llama3.2",
    "prompt": "Réponds à cet email de manière professionnelle et concise:\n\n{{ $json.body }}",
    "stream": false
  }
}
```

## Workflow 2 : Résumé quotidien de documents

**Description** : Résumer automatiquement les nouveaux documents uploadés

### Nodes nécessaires :
1. **Schedule Trigger** - Exécution quotidienne
2. **Watch Folder** - Surveille un dossier de documents
3. **Read Binary File** - Lit le contenu
4. **HTTP Request** - Envoie à Ollama pour résumé
5. **Slack/Discord** - Envoie le résumé

### Prompt pour le résumé :

```json
{
  "model": "mistral",
  "prompt": "Fais un résumé en 5 points clés de ce document:\n\n{{ $json.content }}",
  "stream": false
}
```

## Workflow 3 : Chatbot Webhook

**Description** : Créer une API de chatbot utilisant Ollama

### Nodes nécessaires :
1. **Webhook** - Point d'entrée HTTP
2. **HTTP Request** - Appelle Ollama
3. **Respond to Webhook** - Retourne la réponse

### Configuration :

**Webhook (POST)** :
- Path : `/chat`
- Body :
```json
{
  "message": "Votre question",
  "model": "llama3.2"
}
```

**HTTP Request** :
```json
{
  "method": "POST",
  "url": "http://ollama:11434/api/chat",
  "body": {
    "model": "{{ $json.model }}",
    "messages": [
      {
        "role": "user",
        "content": "{{ $json.message }}"
      }
    ],
    "stream": false
  }
}
```

**Response** :
```javascript
// Dans le node Function
return {
  json: {
    response: $input.all()[0].json.message.content,
    model: $json.model
  }
};
```

## Workflow 4 : Traduction automatique

**Description** : Service de traduction utilisant Ollama

### Configuration HTTP Request :

```json
{
  "method": "POST",
  "url": "http://ollama:11434/api/generate",
  "body": {
    "model": "llama3.2",
    "prompt": "Traduis ce texte en {{ $json.targetLang }}. Retourne uniquement la traduction, sans explications:\n\n{{ $json.text }}",
    "stream": false
  }
}
```

## Workflow 5 : Extraction de données structurées

**Description** : Extraire des informations structurées de texte libre

### Prompt pour extraction :

```json
{
  "model": "llama3.2",
  "prompt": "Extrais les informations suivantes du texte ci-dessous et retourne-les au format JSON:\n- nom\n- email\n- téléphone\n- entreprise\n\nTexte:\n{{ $json.text }}\n\nRéponds uniquement avec le JSON, rien d'autre.",
  "stream": false,
  "format": "json"
}
```

## Workflow 6 : Modération de contenu

**Description** : Analyser et modérer du contenu automatiquement

### Configuration :

```json
{
  "model": "mistral",
  "prompt": "Analyse ce contenu et indique s'il contient:\n- Langage inapproprié (oui/non)\n- Spam (oui/non)\n- Score de toxicité (0-10)\n\nContenu:\n{{ $json.content }}\n\nRéponds au format JSON uniquement.",
  "stream": false,
  "format": "json"
}
```

## Workflow 7 : Génération de code

**Description** : Générer du code à partir de descriptions

### Configuration :

```json
{
  "model": "codellama",
  "prompt": "Génère une fonction {{ $json.language }} qui fait:\n{{ $json.description }}\n\nRetourne uniquement le code, bien formaté et commenté.",
  "stream": false
}
```

## Workflow 8 : Classification de tickets

**Description** : Classifier automatiquement des tickets support

### Prompt :

```json
{
  "model": "llama3.2",
  "prompt": "Classifie ce ticket de support dans l'une de ces catégories:\n- Technique\n- Facturation\n- Demande de fonctionnalité\n- Bug\n- Autre\n\nTicket:\n{{ $json.ticket }}\n\nRéponds uniquement avec le nom de la catégorie.",
  "stream": false
}
```

## Intégration avec Qdrant pour RAG

Pour utiliser Qdrant dans vos workflows n8n :

### 1. Créer des embeddings avec Ollama

```json
{
  "method": "POST",
  "url": "http://ollama:11434/api/embeddings",
  "body": {
    "model": "nomic-embed-text",
    "prompt": "{{ $json.text }}"
  }
}
```

### 2. Stocker dans Qdrant

```json
{
  "method": "PUT",
  "url": "http://qdrant:6333/collections/documents/points",
  "body": {
    "points": [
      {
        "id": "{{ $json.id }}",
        "vector": "{{ $json.embedding }}",
        "payload": {
          "text": "{{ $json.text }}",
          "metadata": {}
        }
      }
    ]
  }
}
```

### 3. Recherche sémantique

```json
{
  "method": "POST",
  "url": "http://qdrant:6333/collections/documents/points/search",
  "body": {
    "vector": "{{ $json.query_embedding }}",
    "limit": 5,
    "with_payload": true
  }
}
```

## 🔧 Conseils et bonnes pratiques

### 1. Gestion des erreurs
Toujours ajouter un node "Error Trigger" pour gérer les erreurs d'API

### 2. Rate limiting
Utiliser le node "Wait" pour éviter de surcharger Ollama

### 3. Cache
Utiliser Redis pour mettre en cache les réponses fréquentes :

```javascript
// Node Function pour check cache
const redis = require('redis');
const client = redis.createClient({ url: 'redis://redis:6379' });
await client.connect();

const cacheKey = `ollama:${$json.prompt}`;
const cached = await client.get(cacheKey);

if (cached) {
  return { json: JSON.parse(cached) };
}
// Sinon, appeler Ollama et mettre en cache
```

### 4. Streaming pour longues réponses
Pour les réponses longues, utiliser le streaming :

```json
{
  "url": "http://ollama:11434/api/generate",
  "body": {
    "model": "llama3.2",
    "prompt": "{{ $json.prompt }}",
    "stream": true
  }
}
```

## Ressources

- [Documentation API Ollama](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Documentation n8n](https://docs.n8n.io/)
- [Exemples de workflows n8n](https://n8n.io/workflows)
- [Documentation Qdrant API](https://qdrant.tech/documentation/quick-start/)

## Support

Pour toute question, ouvrez une issue sur GitHub !

