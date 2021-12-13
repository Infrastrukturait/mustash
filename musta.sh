#!/bin/bash

__MUSTASH_VERSION="0.1.0"

SELF="$0"
NULL=/dev/null
STDIN=0
STDOUT=1
STDERR=2
LEFT_DELIM="{{"
RIGHT_DELIM="}}"
INDENT_LEVEL="  "
ESCAPE=0
out=">&$STDOUT"

ENV_FILE=".mustashenv"

__help () {
    echo "usage: $SELF [-ehV] [-f <file>] [-o <file>]"
    echo
    echo "options:"
    echo "  -f, --file <file>       file to parse"
    echo "  -o, --out <file>        output file"
    echo "  -e, --escape            escapes html html entities"
    echo "  -h, --help              display this message"
    echo "  -V, --version           output version"
    echo "  -v, --env-file          load environment variables from file"
    echo ""
    echo "Variables can be from the environment  or by using the \`.mustashenv\` file."
    echo "You can always overwrite the path to another variable file with the \`-v\` \`--variables\` parameter or with the \`MUSTASH_ENV\` environment variable"
    echo ""
}

__version () {
  echo $__MUSTASH_VERSION
}

__load_env () {
  set -a
  [ -f $1 ] && . $1
  set +a
}

while true; do
  arg="$1"

  if [ "" = "$1" ]; then
    break;
  fi

  if [ "${arg:0:1}" != "-" ]; then
    shift
    continue
  fi

  case $arg in
    -f|--file)
      file="$2";
      shift 2;
      ;;
    -o|--out)
      out="> $2";
      shift 2;
      ;;
    -e|--escape)
      ESCAPE=1
      shift
      ;;
    -h|--help)
      __help
      exit 1
      ;;
    -V|--version)
      __version
      exit 0
      ;;
    -v|--env-file)
      ENV_FILE="$2";
      shift 2;
      ;;
    *)
      {
        echo "unknown option \`$arg'"
      } >&$STDERR
      __help
      exit 1
      ;;
  esac
done

__main__ () {

  ## read each line
  while IFS= read -r line; do
    printf '%q\n' "${line}" | {
        ## read each ENV variable
        echo "$ENV" | {
          while read var; do
            ## split each ENV variable by '='
            ## and parse the line replacing
            ## occurrence of the key with
            ## guarded by the values of
            ## `LEFT_DELIM' and `RIGHT_DELIM'
            ## with the value of the variable
            case "$var" in
              (*"="*)
                key=${var%%"="*}
                val=${var#*"="*}
                ;;

              (*)
                key=$var
                val=
                ;;
            esac

            line="${line//${LEFT_DELIM}$key${RIGHT_DELIM}/$val}"
          done

          if [ "1" = "$ESCAPE" ]; then
            line="${line//&/&amp;}"
            line="${line//\"/&quot;}"
            line="${line//\</&lt;}"
            line="${line//\>/&gt;}"
          fi

          ## output to stdout
          echo "$line" | {
            ## parse undefined variables
            sed -e "s#${LEFT_DELIM}[A-Za-z]*${RIGHT_DELIM}##g" | \
            ## parse comments
            sed -e "s#${LEFT_DELIM}\!.*${RIGHT_DELIM}##g" | \
            ## escaping
            sed -e 's/\\\"/""/g'
          };
        }
    };
  done
}


if test -z "$MUSTASH_ENV"; then
    ENV_FILE=$ENV_FILE
else
    ENV_FILE=$MUSTASH_ENV
fi

__load_env $ENV_FILE

ENV=$(env)

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  export -f __main__
else
  if test ! -t 0; then
    eval "__main__ $out"
  elif test ! -z "$file"; then
    eval "cat $file | __main__ $out"
  else
    __help
    exit 1
  fi
  exit $?
fi
