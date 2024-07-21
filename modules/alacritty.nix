{ pkgs, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      import = [ "${pkgs.alacritty-theme}/solarized_dark.toml" ];
      # import = [ "${pkgs.alacritty-theme}/kanagawa_wave.toml" ];
      # import = [ "${pkgs.alacritty-theme}/tokyo-night.toml"];
      # import = [ "${pkgs.alacritty-theme}/nord.toml" ];

      cursor.style = "Block";
      font =
        let fontname = "SauceCodePro Nerd Font Mono";
        in {
          normal = {
            family = fontname;
            style = "Regular";
          };
          bold = {
            family = fontname;
            style = "Medium";
          };
          italic = {
            family = fontname;
            style = "Ligth";
          };
          size = 18;
        };

      mouse = { hide_when_typing = true; };
      scrolling = {
        history = 100000;
        multiplier = 3;
      };
      selection.save_to_clipboard = true;

      window = {
        blur = true;
        opacity = 0.7;
        dynamic_title = true;
        dynamic_padding = true;
        decorations = "buttonless";
        padding.x = 10;
        padding.y = 10;
      };
    };
  };
}
