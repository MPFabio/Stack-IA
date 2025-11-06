.PHONY: help up down start stop restart logs ps pull models clean

help: ## Afficher l'aide
	@echo "Stack-IA - Commandes disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Démarrer tous les services
	docker compose up -d
	@echo "Stack-IA démarré ! Accédez aux services :"
	@echo "  - Open WebUI:   http://localhost:3000"
	@echo "  - AnythingLLM:  http://localhost:3001"
	@echo "  - n8n:          http://localhost:5678"
	@echo "  - Adminer:      http://localhost:8080"

down: ## Arrêter tous les services
	docker compose down

start: ## Démarrer les services existants
	docker compose start

stop: ## Arrêter les services sans les supprimer
	docker compose stop

restart: ## Redémarrer tous les services
	docker compose restart

logs: ## Afficher les logs de tous les services
	docker compose logs -f

ps: ## Afficher le statut des services
	docker compose ps

pull: ## Mettre à jour les images Docker
	docker compose pull

models: ## Télécharger les modèles Ollama recommandés
	@echo "Téléchargement des modèles Ollama..."
	docker exec -it ollama ollama pull llama3.2
	docker exec -it ollama ollama pull nomic-embed-text
	docker exec -it ollama ollama pull mistral
	@echo "Modèles téléchargés !"

clean: ## Arrêter et supprimer tous les conteneurs et volumes ([!] supprime les données)
	@echo "ATTENTION: Cette commande va supprimer toutes les données !"
	@read -p "Êtes-vous sûr ? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "Nettoyage terminé"; \
	else \
		echo "Annulé"; \
	fi

stats: ## Afficher les statistiques d'utilisation des ressources
	docker stats

backup: ## Créer une sauvegarde des volumes
	@echo "Création de la sauvegarde..."
	@mkdir -p backups
	@docker run --rm -v stack-ia_ollama_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/ollama-$$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@docker run --rm -v stack-ia_n8n_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/n8n-$$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@docker run --rm -v stack-ia_anythingllm_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/anythingllm-$$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@docker run --rm -v stack-ia_postgres_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/postgres-$$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@echo "Sauvegarde terminée dans ./backups/"

