{ pkgs
, lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, alsa-lib
, gtk3
, lame
, ffmpeg
, vlc
, xdg-utils
, which
, openssl
, curl
}:
stdenv.mkDerivation rec {
  pname = "ultraschall";
  version = "R5.1.0_23_202311072335";
  reaperPackage = pkgs.callPackage ./../reaper-for-ultraschall { };

  src = fetchurl {
    url = "https://github.com/Ultraschall/ultraschall-installer/releases/download/${version}/ULTRASCHALL_R5.1.0-preview.tar.gz";
    sha256 = "sha256-1QQdjlnFM1P8g1eyrDT5iiwf9iNVbRcuXQh14P4Im/Q=";
  };

  ultraschallExecutable = ''
    #! ${pkgs.bash}/bin/bash -e
    
    mkdir -p $HOME/.config/ULTRASCHALL
    #export HOME=$HOME/.config/ULTRASCHALL
    
    # check if this script ran before:
    if [ -f "$HOME/.config/ULTRASCHALL/ultraschallInitScriptRunBefore" ]; then
      echo ultraschall was setup before, just starting reaper
    else
      echo first time ultraschall starts, seting up ultraschall for you now
      cd "$(${pkgs.coreutils}/bin/dirname $0)/.."
     
      mkdir -p "$HOME/.config/ULTRASCHALL"
      mkdir -p "$HOME/.config/ULTRASCHALL/UserPlugins"
      mkdir -p "$HOME/.config/ULTRASCHALL/Scripts"
      mkdir -p "$HOME/.vst3"
      mkdir -p "$HOME/.lv2"

      # todo: check if maybe we need to copy from reaper first, then overwrite
      tar xf ./themes/ultraschall-theme.tar -C "$HOME/.config/ULTRASCHALL"
      
      cp -fr ./plugins/* "$HOME/.config/ULTRASCHALL/UserPlugins"
      cp -fr ./scripts/* "$HOME/.config/ULTRASCHALL/Scripts"
      rm -rf "$HOME/.vst3/{studio-link-plugin.vst,Soundboard.vst3}"
      rm -rf "$HOME/.lv2/studio-link-onair.lv2"
      cp -fr ./custom-plugins/{studio-link-plugin.vst,Soundboard.vst3} "$HOME/.vst3"
      cp -fr ./custom-plugins/studio-link-onair.lv2 "$HOME/.lv2"

      touch $HOME/.config/ULTRASCHALL/ultraschallInitScriptRunBefore

      chmod -R +w "$HOME/.config/ULTRASCHALL"
      chmod -R +w "$HOME/.lv2"
      chmod -R +w "$HOME/.vst3"
    fi

    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ lame ffmpeg vlc ]}"''${LD_LIBRARY_PATH:+':'}$LD_LIBRARY_PATH
    echo "doller at= $@"
    exec -a "$0" "${reaperPackage}/opt/REAPER/reaper" -cfgfile "$HOME/.config/ULTRASCHALL/reaper.ini" "$@"
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    xdg-utils # Required for desktop integration
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
  ];
  #++ lib.optional jackSupport libjack2
  #++ lib.optional pulseaudioSupport libpulseaudio;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # copy ultraschall installer
    mkdir -p $out
    cp -r * $out

    # create ultraschall wrapper script:
    mkdir -p $out/opt/REAPER
    echo '${ultraschallExecutable}' > $out/opt/REAPER/ultraschall   
    chmod +x $out/opt/REAPER/ultraschall

    mkdir -p $out/bin
    ln -s $out/opt/REAPER/ultraschall $out/bin/
    ln -s $out/opt/REAPER/reamote-server $out/bin/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Ultraschall is a extension of the reaper DAW for podcasting";
    homepage = "https://www.ultraschall.fm/";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ fernsehmuell ];
  };
}
