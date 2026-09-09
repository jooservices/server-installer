#!/usr/bin/env bash
# Module catalog: discover MODULE_ID / MODULE_TITLE grouped by area.
#
# WIZ_CATALOG_ENTRIES is a plain (indexed) array of "area|id|title"
# strings — NOT an associative array. macOS ships bash 3.2 (no
# `declare -A`), and this wizard must run there without requiring a
# newer bash first.

WIZ_CATALOG_ENTRIES=()
WIZ_AREA_ORDER=(
  essentials runtime system services panel security observability
  proxy dns network backup certs apps data iac workstation
)

# True unless the module's metadata os_family excludes the detected host.
wiz_catalog_os_match() {
  local id="$1" meta families
  meta="$(si_preflight_meta_path "${id}")"
  families="$(si_preflight_field "${meta}" "os_family" "any")"
  [[ "${families}" == "any" || " ${families} " == *" ${SI_OS_FAMILY} "* ]]
}

wiz_catalog_load() {
  WIZ_CATALOG_ENTRIES=()
  local path area id title
  while IFS= read -r -d '' path; do
    area="$(basename "$(dirname "$(dirname "${path}")")")"
    id="$(grep -E '^MODULE_ID=' "${path}" | head -n1 | sed 's/.*"\(.*\)".*/\1/;s/.*'\''\(.*\)'\''.*/\1/')"
    title="$(grep -E '^MODULE_TITLE=' "${path}" | head -n1 | sed 's/.*"\(.*\)".*/\1/;s/.*'\''\(.*\)'\''.*/\1/')"
    [[ -n "${id}" ]] || continue
    [[ -n "${title}" ]] || title="${id}"
    wiz_catalog_os_match "${id}" || continue
    WIZ_CATALOG_ENTRIES+=("${area}|${id}|${title}")
  done < <(find "${SI_MODULES_DIR}" -type f -name 'module.sh' -print0 | sort -z)
}

# Unique areas actually present in WIZ_CATALOG_ENTRIES, in first-seen order.
wiz_catalog_known_areas() {
  local entry area
  local -a areas=()
  for entry in "${WIZ_CATALOG_ENTRIES[@]+"${WIZ_CATALOG_ENTRIES[@]}"}"; do
    area="${entry%%|*}"
    case " ${areas[*]+"${areas[*]}"} " in
      *" ${area} "*) ;;
      *) areas+=("${area}") ;;
    esac
  done
  printf '%s\n' "${areas[@]+"${areas[@]}"}"
}

wiz_catalog_areas() {
  local a known_area
  local -a known=()
  while IFS= read -r known_area; do
    [[ -n "${known_area}" ]] && known+=("${known_area}")
  done < <(wiz_catalog_known_areas)

  for a in "${WIZ_AREA_ORDER[@]}"; do
    for known_area in "${known[@]+"${known[@]}"}"; do
      [[ "${known_area}" == "${a}" ]] && { printf '%s\n' "${a}"; break; }
    done
  done
  # Any areas not in the preferred order
  for known_area in "${known[@]+"${known[@]}"}"; do
    local o found=0
    for o in "${WIZ_AREA_ORDER[@]}"; do
      [[ "${o}" == "${known_area}" ]] && found=1 && break
    done
    [[ "${found}" -eq 0 ]] && printf '%s\n' "${known_area}"
  done
}

wiz_catalog_items() {
  local area="$1" entry
  for entry in "${WIZ_CATALOG_ENTRIES[@]+"${WIZ_CATALOG_ENTRIES[@]}"}"; do
    [[ "${entry%%|*}" == "${area}" ]] && printf '%s\n' "${entry#*|}"
  done
}

wiz_list_profiles() {
  local f families
  for f in "${SI_PROFILES_DIR}"/*.json; do
    [[ -f "${f}" ]] || continue
    families="$(si_preflight_field "${f}" "os_family" "any")"
    if [[ "${families}" != "any" && " ${families} " != *" ${SI_OS_FAMILY} "* ]]; then
      continue
    fi
    basename "${f}" .json
  done
}
