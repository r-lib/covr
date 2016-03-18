#!/usr/bin/env sh

perl -i -pe 's/\bcovrShim\b/covr/g;s/\bcovrShim_/covr_/g' DESCRIPTION NAMESPACE R/* src/* tests/*R tests/testthat/*R
