# Fonts and fontconfig defaults.
{ config, lib, pkgs, ... }:

let
  # Curation of the ~70 individual nerd-font packages you had on Arch. nixpkgs
  # exposes the collection as one attrset and `nerd-fonts` alone pulls all of
  # it, which is multi-gigabyte. These are the ones your configs actually name,
  # plus the symbol fallback set. MapleMono comes from `maple-mono`, a separate
  # attrset - it is NOT a member of nerd-fonts.
  curatedNerdFonts = with pkgs.nerd-fonts; [
    jetbrains-mono
    hack
    fira-code
    iosevka
    symbols-only
  ];

  # Your own font: the Iosevka fork built from source by the derivation next to
  # this module. It pins the fork's commit plus the source and npm-dependency
  # hashes, so every rebuild reproduces the same TTFs.
  innocephscaAlpha = pkgs.callPackage ./innocephsca-alpha.nix { };
in
{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      innocephscaAlpha
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      dejavu_fonts
      liberation_ttf
      poppins
      inconsolata
      maple-mono.NF
      corefonts
    ] ++ curatedNerdFonts;
    fontconfig = {
      enable = true;
      defaultFonts = {
        # Innocephsca Alpha leads: it is the font this system renders
        # monospaced text with (kitty names it directly). The others stay as
        # fallbacks for glyphs it does not carry.
        monospace = [ "Innocephsca Alpha" "JetBrainsMono Nerd Font" "MapleMono NF" "Noto Sans Mono" ];
        sansSerif = [ "Poppins" "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
