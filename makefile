PYTHON_VERSION = 3

help:
	@echo "Targets:"
	@echo "    make start"
	@echo "    make build"
	@echo "    make down"
	@echo "    make destroy"
	@echo "    make stream"


start:
	docker-compose up -d

down:
	docker-compose down

build:
	cd terraform/staging && terraform init && terraform apply

destroy:
	cd terraform/staging && terraform init && terraform destroy

stream:
	python$(PYTHON_VERSION) apps/dummy_producer/produce.py
