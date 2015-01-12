RCHECKER=rocker/r-base
FILTER=

build-docker-checker:
	docker build -t $(RCHECKER) docker_checker

run-rocker: build-docker-checker
	-docker rm $(RCHECKER)
	docker run --rm -ti -v $(PWD)/..:/home/docker $(RCHECKER) bash 
	
test: build-docker-checker
	docker run --rm -ti -v $(PWD)/..:/home/docker $(RCHECKER) Rscript -e 'devtools::test("covr", "$(FILTER)")'


check: build-docker-checker
	docker run --rm -ti -v $(PWD)/..:/home/docker $(RCHECKER) Rscript -e 'devtools::check("covr")'

