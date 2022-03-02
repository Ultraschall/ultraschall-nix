{ config
, pkgs
, lib
, stdenv
, fetchurl
, fetchFromGitHub
, autoPatchelfHook
, makeWrapper
, alsa-lib
, gtk3
, lame
, ffmpeg
, vlc
, xdg-utils
, which
, jackSupport ? true
, libjack2
, openssl
, pulseaudioSupport ? config.pulseaudio or true
, libpulseaudio
}:
let
  pname = "ultraschall";
  version = "R5.1.0_14_202201011512";
  reaperVersion = "6.27";

  reaper = fetchurl {
    url = "https://www.reaper.fm/files/${lib.versions.major reaperVersion}.x/reaper${builtins.replaceStrings ["."] [""] reaperVersion}_linux_x86_64.tar.xz";
    sha256 = "sha256:1f0x94jnl02kz2q9dzmf4vnn86as949qhmliq612nmaqaqmxjcgb";
  };

  ultraschall = fetchurl {
    url = "https://github.com/Ultraschall/ultraschall-installer/releases/download/R5.1.0_14_202201011512/ULTRASCHALL_R5.1.0-preview.tar.gz";
    sha256 = "sha256:0n9wj91zx0awb2f28r7dbzlcarwxymayy5nk4mhp3gb0paaikyba";
  };

  ultraschallExecutable = ''
    #! ${pkgs.bash}/bin/bash -e
    
    mkdir -p $HOME/.config/ULTRASCHALL
    export HOME=$HOME/.config/ULTRASCHALL
    
    # check if this script ran before:
    if [ -f "$HOME/.config/REAPER/ultraschallInitScriptRunBefore" ]; then
      echo ultraschall was setup before, just starting reaper
    else
      echo first time ultraschall starts, seting up ultraschall for you now
      cd $(${pkgs.coreutils}/bin/dirname $0)/../ultraschall-installer
      mkdir -p "$HOME/.config/REAPER"
      mkdir -p "$HOME/.config/REAPER/UserPlugins"
      mkdir -p "$HOME/.config/REAPER/Scripts"
      mkdir -p "$HOME/.vst3"
      mkdir -p "$HOME/.lv2"

      # todo: check if maybe we need to copy from reaper first, then overwrite
      tar xf ./themes/ultraschall-theme.tar -C "$HOME/.config/REAPER"
      
      cp -fr ./plugins/* "$HOME/.config/REAPER/UserPlugins"
      cp -fr ./scripts/* "$HOME/.config/REAPER/Scripts"
      rm -rf "$HOME/.vst3/{studio-link-plugin.vst,Soundboard.vst3}"
      rm -rf "$HOME/.lv2/studio-link-onair.lv2"
      cp -fr ./custom-plugins/{studio-link-plugin.vst,Soundboard.vst3} "$HOME/.vst3"
      cp -fr ./custom-plugins/studio-link-onair.lv2 "$HOME/.lv2"

      touch $HOME/.config/REAPER/ultraschallInitScriptRunBefore

      chmod -R +w "$HOME/.config/REAPER"
      chmod -R +w "$HOME/.lv2"
      chmod -R +w "$HOME/.vst3"
    fi

    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ lame ffmpeg vlc ]}"''${LD_LIBRARY_PATH:+':'}$LD_LIBRARY_PATH
    exec -a "$0" "$(${pkgs.coreutils}/bin/dirname $0)/../opt/REAPER/reaper" "$@"
  '';
in
stdenv.mkDerivation rec {
  inherit pname version reaperVersion;

  srcs = [ reaper ultraschall ];
  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    xdg-utils # Required for desktop integration
    which
  ];

  buildInputs = [
    alsa-lib
    stdenv.cc.cc.lib # reaper and libSwell need libstdc++.so.6
    gtk3
    openssl
  ];

  runtimeDependencies = [
    gtk3 # libSwell needs libgdk-3.so.0
  ]
  ++ lib.optional jackSupport libjack2
  ++ lib.optional pulseaudioSupport libpulseaudio;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # copy ultraschall installer
    mkdir -p $out/ultraschall-installer
    cp -r R5.1.0-preview/* $out/ultraschall-installer

    # Install reaper
    cd ./reaper_linux_x86_64
    HOME="$out/share" XDG_DATA_HOME="$out/share" ./install-reaper.sh \
      --install $out/opt \
      --integrate-user-desktop
    rm $out/opt/REAPER/uninstall-reaper.sh

    # create ultraschall wrapper script:
    echo '${ultraschallExecutable}' > $out/opt/REAPER/ultraschall   
    chmod +x $out/opt/REAPER/ultraschall

    mkdir $out/bin
    ln -s $out/opt/REAPER/ultraschall $out/bin/
    ln -s $out/opt/REAPER/reamote-server $out/bin/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Reaper DAW (https://www.reaper.fm) with Ultraschall extension for Podcastng";
    homepage = "https://www.ultraschall.fm/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ fernsehmuell ];
  };
}
