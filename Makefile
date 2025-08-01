up:
	docker compose build
	docker compose up -d
	docker compose exec symfony composer install 
	docker compose exec symfony npm run build
	docker compose exec symfony npm install
	docker compose exec symfony npm run dev

down:
	docker compose down

stop:
	docker compose stop