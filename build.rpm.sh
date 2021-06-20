#!/usr/bin/bash

(( EUID == 0 )) &&
  { echo >&2 "This script should not be run as root!"; exit 1; }

# -------------------------------------------------------------------------------------------------------------------- #
# Get options.
# -------------------------------------------------------------------------------------------------------------------- #

OPTIND=1

while getopts "c:p:h" opt; do
  case ${opt} in
    c)
      config="${OPTARG}"
      ;;
    p)
      package="${OPTARG}"
      ;;
    h|*)
      echo "-c '[config]' -p '[package_name]'"
      exit 2
      ;;
  esac
done

shift $(( OPTIND - 1 ))

[[ -z "${config}" ]] || [[ -z "${package}" ]] && exit 1

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

# Apps.
git="$( command -v git )"
copr="$( command -v copr-cli )"

# Build.
d_build="${HOME}/build"

# Package Store.
d_storage="${d_build}/pkgstore/storage"
d_packages="${d_build}/pkgstore/packages"

# Factory.
d_factory="${d_build}/factory"
d_sources="${d_factory}/sources/${package}"
d_result="${d_factory}/srpms"
d_spec="${d_factory}/specs"
f_spec="${d_spec}/${package}.spec"

# -------------------------------------------------------------------------------------------------------------------- #
# Create directory structure.
# -------------------------------------------------------------------------------------------------------------------- #

for i in ${d_factory} ${d_storage} ${d_packages} ${d_sources} ${d_result} ${d_spec}; do
  [[ ! -d "${i}" ]] && mkdir -p "${i}"
done

# -------------------------------------------------------------------------------------------------------------------- #
# Get package.
# -------------------------------------------------------------------------------------------------------------------- #

# Get package storage.
if [[ ! -d "${d_storage}/${package}" ]]; then
  ${git} clone "https://gitlab.com/marketplace-rpm/${package}.src.rpm.git" "${d_storage}/${package}"
fi

# Remove current package version.
[[ -d "${d_packages}/${package}" ]] && rm -rf "${d_packages:?}/${package}"

# Get new package version.
${git} clone "https://gitlab.com/marketplace-rpm/${package}.git" "${d_packages}/${package}"

# Copy package sources to build factory.
mkdir -p "${d_factory}/sources/${package}"

if [[ -d "${d_packages}/${package}/sources" ]]; then
  cp -rf "${d_packages}/${package}/sources"/* \
    "${d_factory}/sources/${package}/"
fi

# Copy package specs to build factory.
if [[ -d "${d_packages}/${package}/specs" ]]; then
  cp -rf "${d_packages}/${package}/specs"/* \
    "${d_factory}/specs/"
fi

# -------------------------------------------------------------------------------------------------------------------- #
# Build local SRPM.
# -------------------------------------------------------------------------------------------------------------------- #

mock -r "${config}"         \
  --spec="${f_spec}"        \
  --sources="${d_sources}"  \
  --resultdir="${d_result}" \
  --buildsrpm

# -------------------------------------------------------------------------------------------------------------------- #
# Build COPR SRPM.
# -------------------------------------------------------------------------------------------------------------------- #

f_srpm=$( basename -a "${d_result}/${package}"-* )
d_storage_srpm="${d_storage}/${package}"
f_storage_srpm="${d_storage_srpm}/${f_srpm}"

# Check storage directory.
[[ ! -d "${d_storage_srpm}" ]] && echo "Directory not found: ${d_storage_srpm}" || exit 1

# Copy package srpms to storage directory and upload srpm.
cp -rf "${d_result}/${f_srpm}" "${d_storage_srpm}"

# Check storage file.
[[ ! -f "${f_storage_srpm}" ]] && echo "File not found: ${f_storage_srpm}" || exit 1

cd "${d_storage_srpm}"                              \
  && git add .                                      \
  && git commit -a -m "$( date -u '+%Y-%m-%d %T' )" \
  && git push                                       \
  && cd "${HOME}" || exit

# Start build process.
case ${package} in
  *meta-*)
    project_name="meta"
    ;;
  *server-*)
    project_name="meta"
    ;;
  *lib*)
    project_name="libs"
    ;;
  *)
    project_name="${package}"
    ;;
esac

${copr} build --nowait "${project_name}" \
  "https://gitlab.com/marketplace-rpm/${package}.src.rpm/raw/master/${f_srpm}"

# -------------------------------------------------------------------------------------------------------------------- #
# Remove SRPM.
# -------------------------------------------------------------------------------------------------------------------- #

[[ -f "${d_result}/${f_srpm}" ]] && rm -f "${d_result}/${f_srpm}"

# -------------------------------------------------------------------------------------------------------------------- #
# Exit.
# -------------------------------------------------------------------------------------------------------------------- #

exit 0
