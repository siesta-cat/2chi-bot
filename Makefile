.PHONY: test

run:
	docker compose down -v
	docker compose run --build twochi-bot

test:
	docker compose down -v
	docker compose run --build twochi-bot sh -c "sleep 2 && gleam test"
