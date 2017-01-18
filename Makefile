.PHONY: up down test

test: up
	rspec spec
	$(MAKE) down

up:
	docker-compose up -d

down:
	docker-compose down -v
