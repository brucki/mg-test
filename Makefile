up:
	docker compose build
	docker compose up -d
	docker compose exec symfony composer install

down:
	docker compose down

stop:
	docker compose stop