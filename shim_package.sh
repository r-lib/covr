#!/usr/bin/sh

perl -i -pe 's/\bcovr\b/covrShim/g;s/\breassign_function\b/reassign_function_shim/g;s/\bduplicate_\b/duplicate_shim/g' DESCRIPTION NAMESPACE R/* src/* tests/*R tests/testthat/*R
