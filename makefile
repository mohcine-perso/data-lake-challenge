PYTHON_VERSION = 3

help:
	@echo "Targets:"
	@echo "    make aws"
	@echo "    make build"
	@echo "    make destroy"

start:
	docker-compose up -d

down:
	docker-compose down

build:
	cd terraform/staging && terraform init && terraform apply

stream:
	python$(PYTHON_VERSION) apps/dummy_producer/produce.py
