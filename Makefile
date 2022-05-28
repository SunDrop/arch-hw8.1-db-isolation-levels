up:
	docker-compose up -d

down:
	docker-compose down -v

stop:
	docker-compose stop

mysql:
	docker-compose exec mysql bash

postgres:
	docker-compose exec postgres bash
