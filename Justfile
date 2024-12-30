default:
    @just --list --unsorted

config := absolute_path('config')
build := absolute_path('.build')
out := absolute_path('firmware')
draw := absolute_path('draw')

# parse combos.dtsi and adjust settings to not run out of slots
_parse_combos:
    #!/usr/bin/env bash
    set -euo pipefail
    cconf="{{ config / 'combos.dtsi' }}"
    if [[ -f $cconf ]]; then
        # set MAX_COMBOS_PER_KEY to the most frequent combos count
        count=$(
            tail -n +10 $cconf |
                grep -Eo '[LR][TMBH][0-9]' |
                sort | uniq -c | sort -nr |
                awk 'NR==1{print $1}'
        )
        sed -Ei "/CONFIG_ZMK_COMBO_MAX_COMBOS_PER_KEY/s/=.+/=$count/" "{{ config }}"/*.conf
        echo "Setting MAX_COMBOS_PER_KEY to $count"

        # set MAX_KEYS_PER_COMBO to the most frequent key count
        count=$(
            tail -n +10 $cconf |
                grep -o -n '[LR][TMBH][0-9]' |
                cut -d : -f 1 | uniq -c | sort -nr |
                awk 'NR==1{print $1}'
        )
        sed -Ei "/CONFIG_ZMK_COMBO_MAX_KEYS_PER_COMBO/s/=.+/=$count/" "{{ config }}"/*.conf
        echo "Setting MAX_KEYS_PER_COMBO to $count"
    fi

# parse build.yaml and filter targets by expression
_parse_targets $expr:
    #!/usr/bin/env bash
    attrs="[.board, .shield]"
    filter="(($attrs | map(. // [.]) | combinations), ((.include // {})[] | $attrs)) | join(\",\")"
    echo "$(yq -r "$filter" build.yaml | grep -v "^," | grep -i "${expr/#all/.*}")"

# build firmware using nix
build: _parse_combos
    #!/usr/bin/env bash
    set -euo pipefail
    targets=$(just _parse_targets all)

    nix build

# clear build cache and artifacts
clean:
    rm -rf {{ build }} {{ out }}

# clear all automatically generated files
clean-all: clean
    rm -rf .west zmk modules zephyr result

# clear nix cache
clean-nix:
    nix-collect-garbage --delete-old

# parse & plot keymap
draw:
    #!/usr/bin/env bash
    set -euo pipefail
    keymap -c "{{ draw }}/config.yaml" parse -z "{{ config }}/yeagboard.keymap" >"{{ draw }}/yeagboard.yaml"
    keymap -c "{{ draw }}/config.yaml" draw "{{ draw }}/yeagboard.yaml" -k "corne_rotated" -l "LAYOUT_split_3x5_3" >"{{ draw }}/yeagboard.svg"
    # we like our absurd resolutions
    inkscape -w 4096 "{{ draw }}/yeagboard.svg" -o "{{ draw }}/keymap.png"

# initialize west
init:
    west init -l config
    west update
    west zephyr-export

# list build targets
list:
    @just _parse_targets all | sed 's/,$//' | sort | column

# update west
update:
    west update

# upgrade zephyr-sdk and python dependencies
upgrade-sdk:
    nix flake update --flake .
