#!/usr/bin/env sh

perl -i -pe 's/\bcovr\b/covrShim/g;s/\bcovr_/covrShim_/g;s/_covr/_covrShim/g;' DESCRIPTION NAMESPACE R/* src/* tests/*R tests/testthat/*R
