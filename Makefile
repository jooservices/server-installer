.PHONY: help doctor e2e e2e-coverage e2e-essentials e2e-docker e2e-web e2e-devops e2e-full-gap shellcheck

help:
	@echo "Targets: e2e e2e-coverage e2e-essentials e2e-docker e2e-web e2e-devops e2e-full-gap"

doctor:
	./bin/server-installer doctor --profile vm-essentials

e2e:
	bash ./tests/run_e2e.sh all

e2e-coverage:
	bash ./tests/run_e2e.sh coverage

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

shellcheck:
	shellcheck -x bin/server-installer lib/*.sh modules/*/*/module.sh tests/e2e/*.sh tests/run_e2e.sh
