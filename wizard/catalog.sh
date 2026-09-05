#!/usr/bin/env bash
# Module catalog: discover MODULE_ID / MODULE_TITLE grouped by area.

# area -> space-separated "id|Title" entries
declare -A WIZ_CATALOG=()
WIZ_AREA_ORDER=(
  essentials runtime system services security observability
  proxy dns network backup certs apps data iac
)

wiz_catalog_load() {
  WIZ_CATALOG=()
  local path area id title
  while IFS= read -r -d '' path; do
    area="$(basename "$(dirname "$(dirname "${path}")")")"
    id="$(grep -E '^MODULE_ID=' "${path}" | head -n1 | sed 's/.*"\(.*\)".*/\1/;s/.*'\''\(.*\)'\''.*/\1/')"
    title="$(grep -E '^MODULE_TITLE=' "${path}" | head -n1 | sed 's/.*"\(.*\)".*/\1/;s/.*'\''\(.*\)'\''.*/\1/')"
    [[ -n "${id}" ]] || continue
    [[ -n "${title}" ]] || title="${id}"
    WIZ_CATALOG["${area}"]+="${id}|${title}"$'\n'
  done < <(find "${SI_MODULES_DIR}" -type f -name 'module.sh' -print0 | sort -z)
}

wiz_catalog_areas() {
  local a
  for a in "${WIZ_AREA_ORDER[@]}"; do
    [[ -n "${WIZ_CATALOG[$a]:-}" ]] && printf '%s\n' "${a}"
  done
  # Any areas not in the preferred order
  for a in "${!WIZ_CATALOG[@]}"; do
    local known=0 o
    for o in "${WIZ_AREA_ORDER[@]}"; do
      [[ "${o}" == "${a}" ]] && known=1 && break
    done
    [[ "${known}" -eq 0 ]] && printf '%s\n' "${a}"
  done
}

wiz_catalog_items() {
  local area="$1"
  printf '%s' "${WIZ_CATALOG[$area]:-}"
}

wiz_list_profiles() {
  local f
  for f in "${SI_PROFILES_DIR}"/*.json; do
    [[ -f "${f}" ]] || continue
    basename "${f}" .json
  done
}
