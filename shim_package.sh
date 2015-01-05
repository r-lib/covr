#!/usr/bin/sh

sed -i -e 's/Package: covr$/Package: covrShim/' DESCRIPTION
sed -i -e 's/rex::register_shortcuts("covr")/rex::register_shortcuts("covrShim")/' R/covr.R
