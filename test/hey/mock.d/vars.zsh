#!/usr/bin/env zsh
# TODO

# Setup
export HEYSTORE="$XDG_DATA_HOME/hey/env.test.d"
rm -rf $HEYSTORE
trap "rm -rf $HEYSTORE" EXIT
mkdir -p ${HEYSTORE}
local -A vars=( [__test_varA]=123 [__test_varB]=321 )

# Tests
for key val in ${(kv)vars}; do
  @test -z '$(hey vars get '$key')'
  @test -z '$(hey vars get '$key')'
  @test '$(hey vars set '$key' '$val') == '$val''
  @test '$(hey vars get '$key') == '$val''
  @test '$(echo "XYZ" | hey vars set -i '$key') == XYZ'
  @test '$(hey vars get '$key') == XYZ'
done
@test '$(hey vars) == "'${(kj. .)vars[@]}'"'

# Cleanup
for key val in ${(kv)vars}; do
  @test '$(hey vars set '$key' nil) == '$key''
  @test -z '$(hey vars get '$key')'
done
@test -z '$(hey vars)'
