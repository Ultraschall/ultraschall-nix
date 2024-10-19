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
}:
stdenv.mkDerivation rec {
  pname = "ultraschall";
  version = "V5.1_6_202410180942";

  src = fetchurl {
    url = "https://github.com/Ultraschall/ultraschall-installer/releases/download/${version}/Ultraschall-5.1.tar.gz";
    hash = "sha256-LHSksmpsKd+X0kJdDCWX8TD7vt9QApwdTi+aIyVaNJs=";
  };

  # TODO: make some kind of backup of changed files (rename or move to backup folder)
  ultraschallExecutable = let
    # Ultraschall demands the latest 6.x version
    reaperPackage = pkgs.reaper.overrideAttrs (_: {
      version = "6.83";
      src = fetchurl {
        url = "https://www.reaper.fm/files/6.x/reaper683_linux_x86_64.tar.xz";
        hash ="sha256-iioHvcb1x+1P5ggEDnwyvFS6bBZIxSHJURxedeCXOQg=";
      };
    });
  in ''
    # check if this script ran before for this ultraschall package:
    if [ -f "$HOME/.config/ULTRASCHALL/installedversion" ] && [[ "$(< "$HOME/.config/ULTRASCHALL/installedversion")" == "${version}" ]] ; then
      echo "starting ultraschall"
    else
      # TODO: create backup of the last version
      echo "setting up ultraschall for the first time"
      mkdir -p "$HOME"/.config/ULTRASCHALL/{UserPlugins,Scripts}
      mkdir -p "$HOME"/{.vst3,.lv2}

      cp -fr "$out/themes/"/* "$HOME/.config/ULTRASCHALL"
      cp -fr "$out/scripts"/* "$HOME/.config/ULTRASCHALL/Scripts"
      cp -frs "$out/plugins"/* "$HOME/.config/ULTRASCHALL/UserPlugins"
      cp -frs "$out"/custom-plugins/{studio-link-plugin.vst,Soundboard.vst3} "$HOME/.vst3"
      cp -frs "$out"/custom-plugins/studio-link-onair.lv2 "$HOME/.lv2"
      cp -f "$out"/themes/libSwell.colortheme "$HOME/.config/ULTRASCHALL/libSwell-user.colortheme"

      echo "${version}" > "$HOME/.config/ULTRASCHALL/installedversion"

      chmod -R +w "$HOME/.config/ULTRASCHALL"
      chmod -R +w "$HOME/.lv2"
      chmod -R +w "$HOME/.vst3"
    fi

    export LD_LIBRARY_PATH="${lib.makeLibraryPath [curl lame libxml2 ffmpeg vlc xdotool stdenv.cc.cc.lib]}"''${LD_LIBRARY_PATH:+':'}$LD_LIBRARY_PATH
    exec -a "$0" "${reaperPackage}/opt/REAPER/reaper" -cfgfile "$HOME/.config/ULTRASCHALL/reaper.ini" "$@"
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    xdg-utils
    which
  ];

  buildInputs = [
    alsa-lib
    stdenv.cc.cc.lib
    gtk3
    openssl
    curl
  ];

  runtimeDependencies = [
    gtk3
    libjack2
    pulseaudio
    reaper
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # copy ultraschall installer
    mkdir -p $out/bin
    cp -r * $out

    # untar the big tar archive
    ${gnutar}/bin/tar xf themes/ultraschall-theme.tar -C "$out"/themes/
    rm "$out"/themes/ultraschall-theme.tar

    # create ultraschall wrapper script:
    echo "#! ${pkgs.bash}/bin/bash -e" > $out/bin/ultraschall
    echo "out=\""$out"\"" >> $out/bin/ultraschall
    echo '${ultraschallExecutable}' >> $out/bin/ultraschall
    chmod +x $out/bin/ultraschall

    runHook postInstall
  '';

  meta = with lib; {
    description = "Ultraschall is a extension of the reaper DAW for podcasting";
    homepage = "https://www.ultraschall.fm/";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    maintainers = with maintainers; [fernsehmuell];
  };
}
