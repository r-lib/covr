FROM rocker/r-devel
MAINTAINER james.f.hester@gmail.com

RUN apt-get update && apt-get install -y --no-install-recommends \
	git \
	libcurl4-openssl-dev \
	nano \
	sudo

RUN Rscript -e 'install.packages(c("crayon", "devtools", "digest", "testthat", "rex", "roxygen2"))'

# karl: was needed to test a package of mine
RUN Rscript -e 'install.packages(c("brew", "dplyr", "gdata", "plyr","reshape2","seqinr","stringr","logging", "pryr"))'

USER docker
WORKDIR /home/docker