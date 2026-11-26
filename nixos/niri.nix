{ config, pkgs, ... }:
let
  # Alt+R: dàn các cửa sổ tiled trên workspace hiện tại thành lưới 2 cột
  niri-quarter = pkgs.writeShellScriptBin "niri-quarter" ''
    set -euo pipefail

    NIRI=${config.programs.niri.package}/bin/niri
    JQ=${pkgs.jq}/bin/jq

    cur=$("$NIRI" msg --json windows | "$JQ" -r '[.[] | select(.is_focused)][0].id // empty')
    ws=$("$NIRI" msg --json windows | "$JQ" -r '[.[] | select(.is_focused)][0].workspace_id // empty')
    [ -n "$ws" ] || exit 0

    tiled() {
      "$NIRI" msg --json windows | "$JQ" -r --argjson ws "$ws" '
        [ .[] | select(.workspace_id == $ws and (.is_floating | not) and .layout.pos_in_scrolling_layout != null) ]
        | sort_by(.layout.pos_in_scrolling_layout)
        | .[].id'
    }

    mapfile -t ids < <(tiled)
    [ "''${#ids[@]}" -ge 2 ] || exit 0

    # 1) tách mỗi cửa sổ về một cột riêng
    while :; do
      read -r _ top <<<"$("$NIRI" msg --json windows | "$JQ" -r --argjson ws "$ws" '
        [ .[] | select(.workspace_id == $ws and (.is_floating | not) and .layout.pos_in_scrolling_layout != null) ]
        | sort_by(.layout.pos_in_scrolling_layout)
        | group_by(.layout.pos_in_scrolling_layout[0])
        | map(select(length > 1))
        | .[0] // empty
        | "\(.[0].layout.pos_in_scrolling_layout[0]) \(.[0].id)"')" || true
      [ -n "''${top:-}" ] || break
      "$NIRI" msg action focus-window --id "$top" >/dev/null
      "$NIRI" msg action expel-window-from-column >/dev/null
    done

    # 2) gom thành 2 cột
    mapfile -t ids < <(tiled)
    n=''${#ids[@]}
    k=$(( (n + 1) / 2 ))
    r=$(( n - k ))

    "$NIRI" msg action focus-window --id "''${ids[0]}" >/dev/null
    for ((i = 1; i < k; i++)); do
      "$NIRI" msg action consume-window-into-column >/dev/null
    done

    if ((r > 0)); then
      "$NIRI" msg action focus-column 2 >/dev/null
      for ((i = 1; i < r; i++)); do
        "$NIRI" msg action consume-window-into-column >/dev/null
      done
    fi

    # 3) mỗi cột 50% rộng, các cửa sổ trong cột cao bằng nhau
    for c in 1 2; do
      "$NIRI" msg action focus-column "$c" >/dev/null 2>&1 || continue
      t=$("$NIRI" msg --json windows | "$JQ" -r --argjson ws "$ws" --argjson c "$c" '
        [ .[] | select(.workspace_id == $ws and (.is_floating | not)
            and .layout.pos_in_scrolling_layout != null
            and .layout.pos_in_scrolling_layout[0] == $c) ]
        | length')
      "$NIRI" msg action set-column-width 50% >/dev/null
      if ((t > 1)); then
        "$NIRI" msg action focus-window-in-column 1 >/dev/null
        "$NIRI" msg action set-window-height "$((100 / t))%" >/dev/null
      else
        "$NIRI" msg action reset-window-height >/dev/null
      fi
    done

    # 4) trả focus về cửa sổ ban đầu
    if [ -n "$cur" ]; then
      "$NIRI" msg action focus-window --id "$cur" >/dev/null
    fi
  '';
    # Super+Shift+S: kéo chọn vùng rồi chụp (giống Snipping Tool của Windows)
  niri-shot = pkgs.writeShellApplication {
    name = "niri-shot-region";
    runtimeInputs = with pkgs; [ slurp grim wl-clipboard libnotify coreutils ];
    text = ''
      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"

      # slurp: -d hiện kích thước, -b nền mờ, -c viền trắng, -w độ dày viền
      geom=$(slurp -d -b 00000080 -c ffffffff -w 2) || exit 0

      file="$dir/Screenshot $(date +'%Y-%m-%d %H-%M-%S').png"
      grim -g "$geom" "$file"
      wl-copy --type image/png < "$file"

      notify-send -i "$file" "Chụp màn hình" "Đã lưu và copy vào clipboard"
    '';
  };
in
{
  programs.niri.settings = {
    input.keyboard.xkb.layout = "us";
    window-rules = [
      {
        matches = [ { app-id = "^com\\.mitchellh\\.ghostty$"; } ];
        draw-border-with-background = false;
      }
    ];

    spawn-at-startup = [
      { command = ["noctalia"]; }
      { command = [ "fcitx5" "-d" ]; }
    ];

    binds = with config.lib.niri.actions; {
      #tool
      "Mod+T".action = spawn  "ghostty";
      "Mod+Q".action = close-window;
      "Mod+D" = {
        hotkey-overlay.title = "Launcher";
        action = spawn "noctalia" "msg" "panel-toggle" "launcher";
      };
      "Mod+W" = {
        hotkey-overlay.title = "Session menu";
        action = spawn "noctalia" "msg" "panel-toggle" "session";
      };
      "Mod+E" = {
        hotkey-overlay.title = "File manager (yazi)";
        action = spawn "ghostty" "-e" "yazi";
      };
      "Mod+Return" = {
        hotkey-overlay.title = "Neovim";
        action = spawn "ghostty" "-e" "nvim";
      };
      "Alt+F" = {
        hotkey-overlay.title = "Maximize window (giữ bar)";
        action = maximize-column;
      };
      "Alt+R" = {
        hotkey-overlay.title = "Chia 4 (2×2)";
        action = spawn "${niri-quarter}/bin/niri-quarter";
      };
      # tuỳ chọn: trả cửa sổ về như cũ
      "Alt+Shift+R" = {
        hotkey-overlay.title = "Bỏ chia 4";
        action = spawn-sh "niri msg action expand-column-to-available-width; niri msg action reset-window-height";
      };
      # chụp vùng màn hình
      "Super+Shift+S" = {
        hotkey-overlay.title = "Chụp vùng màn hình";
        action = spawn "${niri-shot}/bin/niri-shot-region";
      };
      #foucs & move
      "Alt+Left".action = focus-column-left;
      "ALt+Right".action = focus-column-right;
      "Ctrl+Left".action = move-column-left;
      "Ctrl+Right".action = move-column-right;
      # focus workspace
      "Alt+1".action = focus-workspace 1;
      "Alt+2".action = focus-workspace 2;
      "Alt+3".action = focus-workspace 3;
      "Alt+4".action = focus-workspace 4;
      "Alt+5".action = focus-workspace 5;
      "Alt+6".action = focus-workspace 6;
      "Alt+7".action = focus-workspace 7;
      "Alt+8".action = focus-workspace 8;
      "Alt+9".action = focus-workspace 9;
      # move workspace
      "Ctrl+1".action.move-window-to-workspace = 1;
      "Ctrl+2".action.move-window-to-workspace = 2;
      "Ctrl+3".action.move-window-to-workspace = 3;
      "Ctrl+4".action.move-window-to-workspace = 4;
      "Ctrl+5".action.move-window-to-workspace = 5;
      "Ctrl+6".action.move-window-to-workspace = 6;
      "Ctrl+7".action.move-window-to-workspace = 7;
      "Ctrl+8".action.move-window-to-workspace = 8;
      "Ctrl+9".action.move-window-to-workspace = 9;
    };
  };
}
