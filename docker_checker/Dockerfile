FROM rocker/r-devel
MAINTAINER karl.forner@quartzbio.com

RUN Rscript -e 'install.packages("digest")'
RUN Rscript -e 'install.packages("crayon")'
RUN apt-get install -y libcurl4-openssl-dev sudo nano

RUN Rscript -e 'install.packages("devtools")'
RUN Rscript -e 'install.packages("roxygen2")'
RUN Rscript -e 'install.packages("testthat")'
RUN Rscript -e 'devtools::install_github("jimhester/rex")'

RUN Rscript -e 'install.packages(c("brew", "gdata", "plyr","reshape2","seqinr","stringr","logging"))'

RUN apt-get install -y --no-install-recommends git

RUN Rscript -e 'install.packages("dplyr")'
RUN Rscript -e 'install.packages("pryr")'
USER docker
WORKDIR /home/docker