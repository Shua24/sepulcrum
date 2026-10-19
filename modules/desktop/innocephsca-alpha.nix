# Package derivation (not a NixOS module): Innocephsca Alpha, the font family
# built from the Iosevka fork at https://github.com/Shua24/innocephsca-alpha.
# `modules/desktop/fonts.nix` installs it through `fonts.packages`.
#
# The fork changes exactly one thing against upstream Iosevka 34.9.0: the
# build plans in `build-plans.toml`, reduced to a single plan named
# `InnocephscaAlpha` that selects the family's character variants. Everything
# else - glyph sources, metrics, OpenType features, build tooling - is upstream.
#
# Both hashes are pinned, so any rebuild reproduces the same fonts. To bump
# after changing the fork:
#   1. push the fork change, take the new commit hash;
#   2. set `rev`, set `hash = lib.fakeHash;` and build - nix prints the source
#      hash nix wants;
#   3. set `npmDepsHash = lib.fakeHash;` and build again - nix prints the hash
#      of the fetched npm dependencies (same value as
#      `nix run nixpkgs#prefetch-npm-deps -- package-lock.json`).
{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs_22
, ttfautohint
}:

buildNpmPackage rec {
  pname = "innocephsca-alpha";
  version = "34.9.0";

  src = fetchFromGitHub {
    owner = "Shua24";
    repo = "innocephsca-alpha";
    # Branch `innocephsca`: one commit on top of the upstream 34.9.0 release.
    rev = "b555a1f71d5c948b785c9a436e281cc298044614";
    hash = "sha256-72cnXGA/kRkjL95uUY6aiYKakn15Jd4k5xW3TZdOKb8=";
  };

  # Hash of the npm dependency tree from the pinned `package-lock.json`.
  npmDepsHash = "sha256-hPUcUxa2KgGz/KVsYmRFdizTZF7Pim49vBSk9kkCxCg=";

  nodejs = nodejs_22;
  # ttfautohint is what makes the `ttf::` target produce hinted TTFs; without
  # it the build stops and asks for the binary.
  nativeBuildInputs = [ ttfautohint ];

  # `ttf::<plan>` builds the hinted TTF set only - what a desktop installs.
  # `contents::<plan>` would add unhinted TTFs, WOFF2 and webfont CSS, none of
  # which fontconfig needs. --jCmd caps the concurrent build jobs: the default
  # is one per CPU thread and each job can peak above 1 GB of RAM, which is
  # upstream's own warning in doc/custom-build.md.
  buildPhase = ''
    runHook preBuild
    npm run build -- ttf::InnocephscaAlpha --jCmd=4
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -d $out/share/fonts/truetype/innocephsca-alpha
    install -m644 dist/InnocephscaAlpha/TTF/*.ttf $out/share/fonts/truetype/innocephsca-alpha/
    runHook postInstall
  '';

  meta = {
    description = "Innocephsca Alpha - a custom Iosevka build from a personal fork";
    homepage = "https://github.com/Shua24/innocephsca-alpha";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
