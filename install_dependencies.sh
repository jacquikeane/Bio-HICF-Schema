#!/bin/bash
set -e
set -x

start_dir=$(pwd)

BIO_METADATA_VALIDATOR_URL="https://github.com/sanger-pathogens/Bio-Metadata-Validator.git"

# Make an install location
if [ ! -d 'build' ]; then
  mkdir build
fi
cd build
build_dir=$(pwd)

cd $build_dir
git clone $BIO_METADATA_VALIDATOR_URL
cd Bio-Metadata-Validator
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest

BMV_BIN=$(pwd)/bin
BMV_LIB=$(pwd)/lib

cd $start_dir

export PATH=${BMV_bin}:${PATH}
export PERL5LIB=${BMV_lib}:${PERL5LIB}

cpanm DBIx::Class::PassphraseColumn --notest
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest


echo "Add the following lines to your ~/.bashrc profile"
echo "export PATH=${BMV_bin}:${PATH}"
echo "export PERL5LIB=${BMV_lib}:${PERL5LIB}"