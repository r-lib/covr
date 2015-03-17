#!/usr/bin/sh

perl -i -pe 's/\bcovrShim\b/covr/g;s/\breassign_function_shim\b/reassign_function/g;s/\bduplicate_shim\b/duplicate_/g' DESCRIPTION NAMESPACE R/* src/* tests/*R tests/testthat/*R
