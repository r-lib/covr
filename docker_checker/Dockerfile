FROM rocker/hadleyverse
MAINTAINER james.f.hester@gmail.com

# install deps from current github master
RUN Rscript -e 'devtools::install_github("jimhester/covr", dependencies = TRUE)'

# remove installed covr to be sure not to conflict with current source version
RUN Rscript -e 'remove.packages("covr")'

# docker user setup
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo && \
	chmod -R a+rwx /usr/local/lib/R/site-library

USER docker
WORKDIR /home/docker
