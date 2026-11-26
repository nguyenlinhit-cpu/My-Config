{ pkgs, ... }:
{
  # ===========================================================================
  # Ghostty: nền trong suốt + bôi đen là tự copy
  # ===========================================================================
  programs.ghostty = {
    enable = true; # tự thêm pkgs.ghostty vào home.packages

    settings = {
      # --- 1. TRONG SUỐT ----------------------------------------------------
      # 0.0 = trong hoàn toàn, 1.0 = đục hoàn toàn
      background-opacity = "0.85";

      # Làm mờ nội dung phía sau (niri 26.04 có ext-background-effect)
      background-blur = false;

      # true  = ô có màu nền riêng (panel của opencode, helix, selection...)
      #         cũng trong suốt theo
      # false = các ô đó giữ nguyên đục (chữ dễ đọc hơn)
      background-opacity-cells = true;

      # --- 2. BÔI ĐEN LÀ COPY -----------------------------------------------
      # none | primary | clipboard | both
      copy-on-select = "both";

      # --- 3. GIAO DIỆN -----------------------------------------------------
      # Không vẽ thanh tiêu đề / nút close (niri tự vẽ viền)
      window-decoration = "none";
      window-padding-x = 10;
      window-padding-y = 8;
      mouse-hide-while-typing = true;

      # --- 4. SPLIT ---------------------------------------------------------
      # Pane không focus mờ đi cho biết đang gõ ở đâu
      unfocused-split-opacity = "0.6";

      # Resize pane: ctrl+alt+shift+←/→/↑/↓
      # (mặc định là super+ctrl+shift, bấm mỏi tay)
      keybind = [
        "ctrl+alt+shift+arrow_left=resize_split:left,20"
        "ctrl+alt+shift+arrow_right=resize_split:right,20"
        "ctrl+alt+shift+arrow_up=resize_split:up,10"
        "ctrl+alt+shift+arrow_down=resize_split:down,10"
        "ctrl+alt+shift+equal=equalize_splits"
      ];

      # --- 5. TUỲ CHỌN (bỏ comment nếu muốn) -------------------------------
      # font-family = "JetBrainsMono Nerd Font";
      # font-size = 12;
      # theme = "catppuccin-mocha";
      # clipboard-read = "allow";
    };
  };

  # ===========================================================================
  # Zellij: layout 3 pane cố định (giống neovim)
  #
  #   ┌──────────┬────────────┐
  #   │  yazi    │            │
  #   ├──────────┤     hx     │
  #   │ terminal │            │
  #   └──────────┴────────────┘
  #
  # Mở:    gõ "zellij"  (nhờ default_layout bên dưới)
  # Thoát: ctrl+q
  # ===========================================================================
  home.packages = [
    pkgs.zellij
    pkgs.wl-clipboard # copy trong zellij vào clipboard Wayland
  ];

  # Bố cục 3 pane
  xdg.configFile."zellij/layouts/dev.kdl".text = ''
    layout {
        pane split_direction="vertical" {
            pane split_direction="horizontal" {
                pane command="yazi" size="50%"
                pane
            }
            pane command="hx"
        }
    }
  '';

  # Config zellij: bỏ viền pane cho giống split của Ghostty
  xdg.configFile."zellij/config.kdl".text = ''
    default_layout "dev"
    pane_frames false
    show_startup_tips false
    copy_command "wl-copy"
  '';
}
