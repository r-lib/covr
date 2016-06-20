RCHECKER=docker_checker
FILTER=

# to install test packages, code must be compiled inside src/ dir, 
# that may cause problems for docker user docker
# so we grant all permissions
fix-permission-tests:
	chmod -R a+rwx tests


build-docker-checker:
	docker build -t $(RCHECKER) docker_checker

run-rocker: build-docker-checker
	-docker rm $(RCHECKER)
	docker run --rm -ti -v $(PWD)/..:/home/docker $(RCHECKER) bash 
	
test: build-docker-checker fix-permission-tests
	docker run --rm -ti -v $(PWD)/..:/home/docker $(RCHECKER) Rscript -e 'library(devtools);install("covr");test("covr", "$(FILTER)")'


check: build-docker-checker fix-permission-tests
	docker run --rm -ti -v $(PWD)/..:/home/docker $(RCHECKER) Rscript -e 'library(devtools);install("covr");devtools::check("covr")'


rox: build-docker-checker
	docker run --rm -ti -v $(PWD)/..:/home/docker $(RCHECKER) Rscript -e 'devtools::document("covr")'