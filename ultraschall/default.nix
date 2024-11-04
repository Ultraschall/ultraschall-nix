{
  alsa-lib,
  autoPatchelfHook,
  curl,
  fetchurl,
  ffmpeg,
  gtk3,
  lame,
  lib,
  libjack2,
  libxml2,
  makeWrapper,
  openssl,
  pkgs,
  reaper,
  pulseaudio,
  stdenv,
  vlc,
  which,
  xdg-utils,
  xdotool,
  gnutar,
  gnused,
  copyDesktopItems,
  makeDesktopItem,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ultraschall";
  #version = "V5.1_6_202410180942"; # official 5.1 release
  version = "5.1.1_144_202411031527"; # pre-release

  src = fetchurl {
    # official 5.1 release:
    #url = "https://github.com/Ultraschall/ultraschall-installer/releases/download/${finalAttrs.version}/Ultraschall-5.1.tar.gz";
    #hash = "sha256-LHSksmpsKd+X0kJdDCWX8TD7vt9QApwdTi+aIyVaNJs=";

    # pre-release
    url = "https://github.com/Ultraschall/ultraschall-installer/releases/download/R${finalAttrs.version}/ULTRASCHALL_R5.1.1-preview.tar.gz";
    hash = "sha256-KWKDTd7ziXrE26VW6WjJ/BD5yZkok8wojwJJOXCljsU=";
  };

  nativeBuildInputs = [autoPatchelfHook copyDesktopItems makeWrapper xdg-utils which];
  buildInputs = [alsa-lib stdenv.cc.cc.lib gtk3 openssl curl];
  runtimeDependencies = [gtk3 libjack2 pulseaudio reaper];

  buildPhase = let
    reaperPackage = pkgs.reaper.overrideAttrs (_: {
      version = "6.83"; # Ultraschall demands the latest 6.x version
      src = fetchurl {
        url = "https://www.reaper.fm/files/6.x/reaper683_linux_x86_64.tar.xz";
        hash = "sha256-iioHvcb1x+1P5ggEDnwyvFS6bBZIxSHJURxedeCXOQg=";
      };
    });
    icon = fetchurl {
      url = "https://raw.githubusercontent.com/Ultraschall/ultraschall-assets/refs/heads/master/images/Ultraschall-5-Logo.png";
      hash = "sha256-yIuWkWB2aoJWT7sa9XGe276saUXgacJ6SQhCdQ6x4Dg=";
    };
  in ''
    runHook preBuild

    cp "${icon}" ultraschall.png

    cat <<'EOF' > ultraschall
      #! ${pkgs.bash}/bin/bash -e
      DIR=${builtins.placeholder "out"}

      # check if this script ran before for this ultraschall package:
      if [ -f "$HOME/.config/ULTRASCHALL/installedversion" ] && [[ "$(< "$HOME/.config/ULTRASCHALL/installedversion")" == "${finalAttrs.version}" ]] ; then
        echo "starting ultraschall"
      else
        echo "setting up ultraschall for the first time"
        mkdir -p "$HOME"/.config/ULTRASCHALL/{UserPlugins,Scripts}
        mkdir -p "$HOME"/{.vst3,.lv2}
        cp -fr "$DIR/themes/"/* "$HOME/.config/ULTRASCHALL"
        cp -fr "$DIR/scripts"/* "$HOME/.config/ULTRASCHALL/Scripts"
        cp -frs "$DIR/plugins"/* "$HOME/.config/ULTRASCHALL/UserPlugins"
        cp -frs "$DIR"/custom-plugins/{studio-link-plugin.vst,Soundboard.vst3} "$HOME/.vst3"
        cp -frs "$DIR"/custom-plugins/studio-link-onair.lv2 "$HOME/.lv2"
        cp -f "$DIR"/themes/libSwell.colortheme "$HOME/.config/ULTRASCHALL/libSwell-user.colortheme"
        echo "${finalAttrs.version}" > "$HOME/.config/ULTRASCHALL/installedversion"
        chmod -R +w "$HOME/.config/ULTRASCHALL"
        chmod -R +w "$HOME/.lv2"
        chmod -R +w "$HOME/.vst3"
      fi
      export LD_LIBRARY_PATH="${lib.makeLibraryPath [curl lame libxml2 ffmpeg vlc xdotool stdenv.cc.cc.lib]}"''${LD_LIBRARY_PATH:+':'}$LD_LIBRARY_PATH
      exec -a "$0" "${reaperPackage}/opt/REAPER/reaper" -cfgfile "$HOME/.config/ULTRASCHALL/reaper.ini" "$@"
    EOF

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    mkdir -p "$out/share/icons/hicolor/512x512/apps"
    
    mv ultraschall.png "$out/share/icons/hicolor/512x512/apps/ultraschall.png"
    mv ultraschall "$out/bin/ultraschall" && chmod +x "$out/bin/ultraschall"
    cp -r * "$out"
    ${gnutar}/bin/tar xf themes/ultraschall-theme.tar -C "$out/themes/" && rm "$out/themes/ultraschall-theme.tar"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Ultraschall";
      exec = "Ultraschall";
      icon = "ultraschall";
      desktopName = "Ultraschall";
      comment = "Ultraschall – High-end podcasting for the rest of us";
      categories = ["Audio" "AudioVideo" "AudioVideoEditing" "Recorder" "Video"];
    })
  ];

  meta = with lib; {
    description = "Ultraschall is a extension of the reaper DAW for podcasting";
    homepage = "https://www.ultraschall.fm/";
    changelog = "https://github.com/Ultraschall/ultraschall-portable/wiki/Ultraschall-5.1---Release-Notes";
    license = licenses.mit;
    mainProgram = "ultraschall";
    maintainers = with maintainers; [fernsehmuell];
    platforms = ["x86_64-linux"];
  };
})
