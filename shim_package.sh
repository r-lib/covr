#!/usr/bin/env sh

perl -i -pe 's/\bcovr\b/covrShim/g;s/\bcovr_/covrShim_/g' DESCRIPTION NAMESPACE R/* src/* tests/*R tests/testthat/*R
