#!/bin/bash
#
tar_encrypt() {
  local OUTPUT=
  local opt=
  local OPTARG=
  
  while getopts :o: opt; do
    case $opt in
      o) OUTPUT="$OPTARG";;
      \?) echo "Invalid option: -"$OPTARG"" >&2
          return 1;; 
      : ) echo "Option -"$OPTARG" requires an argument." >&2
          return 1;; 
    esac
  done

  [[ -z "$OUTPUT" ]] && echo "You must specify ${FUNCNAME[0]} -o <outputfile> <files>">&2 && unset OPTIND && return 1   

  shift 2
  [[ -z "$@" ]] && echo "Please specify files to tar_encrypt" >&2 && unset OPTIND && return 1

  tar -czv $@ | gpg --symmetric --cipher-algo aes256 > $OUTPUT
  unset OPTIND
}

beep() {
  read a || exit;
  printf "$a\007\n"
  beep
}

#mvn dependency:get -DremoteRepositories=http://repo.maven2.org -DgroupId=org.apache -DartifactId=collections4 -Dversion=${VERS} -Dpackaging=jar -Dtransitive=false -Ddest=/tmp/
