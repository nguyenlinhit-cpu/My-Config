{ pkgs, config, lib, ... }:
{
  programs.nixvim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;

    globals.mapleader = " ";

    opts = {
      number = true;
      relativenumber = true;
      signcolumn = "yes";
      tabstop = 2;
      shiftwidth = 2;
      softtabstop = 2;
      expandtab = true;
      termguicolors = true;
      timeoutlen = 300;
      ttimeoutlen = 50;
    };

    # ---------- Phím tắt ----------
    keymaps = [
      # Space e -> mở/focus cây thư mục
      {
        mode = "n";
        key = "<leader>e";
        action.__raw = "function() _G.FocusTree() end";
        options.desc = "Focus cây thư mục";
      }
      # Space t -> mở/focus terminal
      {
        mode = "n";
        key = "<leader>t";
        action.__raw = "function() _G.FocusTerm() end";
        options.desc = "Focus terminal";
      }
      # Space w -> quay lại vùng code
      {
        mode = "n";
        key = "<leader>w";
        action.__raw = "function() _G.FocusCode() end";
        options.desc = "Focus vùng code";
      }
      # Terminal mode: Space w / Space e cũng dùng được ngay khi đang gõ
      {
        mode = "t";
        key = "<leader>w";
        action.__raw = "function() _G.FocusCode() end";
        options.desc = "Focus vùng code";
      }
      {
        mode = "t";
        key = "<leader>e";
        action.__raw = "function() vim.cmd('stopinsert'); _G.FocusTree() end";
        options.desc = "Focus cây thư mục";
      }
      # Esc Esc để thoát insert trong terminal (1 lần Esc vẫn gửi cho shell)
      {
        mode = "t";
        key = "<Esc><Esc>";
        action.__raw = "function() vim.cmd('stopinsert') end";
        options.desc = "Về normal mode";
      }
    ];

    plugins = {
      # ---------- lazy.nvim ----------
      # Chỉ đóng vai trò loader/UI; plugin vẫn do Nix cài.
      lazy = {
        enable = true;
        autoLoad = true;
       };
      lsp.enable = true;
      web-devicons.enable = true;

      neo-tree = {
        enable = true;
        settings = {
          close_if_last_window = true;
          popup_border_style = "rounded";
          enable_git_status = true;
          enable_diagnostics = true;

          window = {
            width = 30;
            mapping_options.noremap = true;
          };

          filesystem = {
            follow_current_file.enabled = true;
            use_libuv_file_watcher = true;
            filtered_items = {
              hide_dotfiles = false;
              hide_gitignored = true;
            };
          };
        };
      };

      toggleterm = {
        enable = true;
        settings = {
          size = 12;
          direction = "horizontal";
          open_mapping = null;
          start_in_insert = false;
          insert_mappings = true;
          terminal_mappings = true;
          persist_size = true;
          close_on_exit = true;
          shade_terminals = true;
          shell = "bash";
          float_opts = {
            border = "curved";
            winblend = 3;
          };
        };
      };
    };

    # ---------- Hàm focus dùng chung ----------
    extraConfigLua = ''
      _G.code_win = nil
      _G._term = nil

      function _G.FocusTree()
        if vim.bo.filetype == "neo-tree" then
          vim.cmd("Neotree close")
          return
        end
        vim.cmd("Neotree focus")
      end

      function _G.FocusTerm()
        if not _G._term then
          _G._term = require("toggleterm.terminal").Terminal:new({
            id = 1,
            direction = "horizontal",
            size = 12,
            hidden = true,
          })
        end
        local win = _G._term.window
        if win and vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
        else
          _G._term:toggle()
        end
        vim.cmd("startinsert")
      end

      function _G.FocusCode()
        local win = _G.code_win
        if win and vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
          vim.cmd("stopinsert")
          return
        end
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local b = vim.api.nvim_win_get_buf(w)
          if vim.bo[b].buftype == "" and vim.bo[b].filetype ~= "neo-tree" then
            vim.api.nvim_set_current_win(w)
            _G.code_win = w
            vim.cmd("stopinsert")
            return
          end
        end
      end

      -- Ghi nhớ cửa sổ code gần nhất
      vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
        callback = function()
          local b = vim.api.nvim_get_current_buf()
          if vim.bo[b].buftype == "" and vim.bo[b].filetype ~= "neo-tree" then
            _G.code_win = vim.api.nvim_get_current_win()
          end
        end,
      })
    '';

    # ---------- Mở sẵn cây thư mục + terminal ----------
    autoCmd = [
      {
        event = [ "VimEnter" ];
        pattern = [ "*" ];
        callback.__raw = ''
          function()
            if vim.bo.buftype ~= "" or vim.fn.argv(0) == "-" then
              return
            end
            vim.schedule(function()
              vim.cmd("Neotree show")
              _G.FocusTerm()
              _G.FocusCode()
            end)
          end
        '';
      }
    ];
  };
}
