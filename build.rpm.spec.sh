#!/usr/bin/bash

(( EUID == 0 )) &&
  { echo >&2 "This script should not be run as root!"; exit 1; }

# -------------------------------------------------------------------------------------------------------------------- #
# Get options.
# -------------------------------------------------------------------------------------------------------------------- #

OPTIND=1

while getopts "f:h" opt; do
  case ${opt} in
    f)
      file="${OPTARG}"
      ;;
    h|*)
      echo "-f '[file]'"
      exit 2
      ;;
  esac
done

shift $(( OPTIND - 1 ))

[[ -z "${file}" ]] && exit 1

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

sed="$( command -v sed ) -i -E"

declare -A tags
tags=(
  ['AutoReqProv:']='AutoReqProv:                    '
  ['BuildArch:']='BuildArch:                      '
  ['BuildRoot:']='BuildRoot:                      '
  ['Conflicts:']='Conflicts:                      '
  ['Epoch:']='Epoch:                          '
  ['ExcludeArch:']='ExcludeArch:                    '
  ['Group:']='Group:                          '
  ['License:']='License:                        '
  ['Name:']='Name:                           '
  ['Obsoletes:']='Obsoletes:                      '
  ['Provides:']='Provides:                       '
  ['Release:']='Release:                        '
  ['Requires(post):']='Requires(post):                 '
  ['Requires(postun):']='Requires(postun):               '
  ['Requires(pre):']='Requires(pre):                  '
  ['Requires(preun):']='Requires(preun):                '
  ['Requires:']='Requires:                       '
  ['Summary:']='Summary:                        '
  ['URL:']='URL:                            '
  ['Version:']='Version:                        '
  ['BuildRequires:']='BuildRequires:                  '
  ['Suggests:']='Suggests:                       '
  ['Patch([[:digit:]]+):']='Patch\1: '
  ['Source([[:digit:]]+):']='Source\1: '
)

[[ ! -f "${file}" ]] &&
  { echo "File not found: ${file}"; exit 1; }

for i in "${!tags[@]}"; do
  ${sed} "s|${i}[[:space:]]+|${tags[$i]}|g" "${file}"
done

# -------------------------------------------------------------------------------------------------------------------- #
# Exit.
# -------------------------------------------------------------------------------------------------------------------- #

exit 0
