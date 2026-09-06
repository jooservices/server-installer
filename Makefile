.PHONY: help doctor hooks-install e2e e2e-coverage metadata-test preflight-test e2e-essentials e2e-docker e2e-web e2e-devops e2e-full-gap e2e-gap-sys e2e-gap-apps shellcheck lint

help:
	@echo "Targets: lint hooks-install metadata-test preflight-test e2e-coverage e2e"

doctor:
	./bin/server-installer doctor --profile vm-essentials

hooks-install:
	git config core.hooksPath .githooks
	chmod +x .githooks/commit-msg .githooks/pre-commit .githooks/pre-push

lint shellcheck:
	shellcheck -x -e SC1091,SC2034,SC2016 \
		.githooks/* \
		bin/server-installer bin/server-installer-wizard lib/*.sh wizard/*.sh \
		modules/*/*/module.sh tests/*.sh tests/e2e/*.sh

e2e:
	bash ./tests/run_e2e.sh all

e2e-coverage:
	bash ./tests/run_e2e.sh coverage

metadata-test:
	bash ./tests/validate_metadata.sh

preflight-test:
	bash ./tests/preflight.sh

e2e-essentials:
	bash ./tests/run_e2e.sh essentials

e2e-docker:
	bash ./tests/run_e2e.sh docker

e2e-web:
	bash ./tests/run_e2e.sh web

e2e-devops:
	bash ./tests/run_e2e.sh devops

e2e-full-gap:
	bash ./tests/run_e2e.sh full-gap

e2e-gap-sys:
	bash ./tests/run_e2e.sh gap-sys

e2e-gap-apps:
	bash ./tests/run_e2e.sh gap-apps
