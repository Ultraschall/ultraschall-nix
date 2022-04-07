{ alsa-lib
, autoPatchelfHook
, bash
, config
, coreutils
, fetchurl
, ffmpeg
, gnutar
, gtk3
, lame
, lib
, makeWrapper
, openssl
, stdenv
, vlc
, which
, xdg-utils
, callPackage
, jackSupport ? true
, libjack2
, pulseaudioSupport ? config.pulseaudio or true
, libpulseaudio
}:
stdenv.mkDerivation rec {
  pname = "ultraschall";
  version = "R5.1.0_16_202202202016";
  reaperPackage = callPackage ./../reaper-for-ultraschall { }; #TODO: change that for nixpkgs

  src = fetchurl {
    url = "https://github.com/Ultraschall/ultraschall-installer/releases/download/${version}/ULTRASCHALL_R5.1.0-preview.tar.gz";
    sha256 = "sha256-avkZlbpgvXFhJdMW71X1nWfF6F/tZCScWFyB/kOSPFk=";
  };

  ultraschallExecutable = ''
    #! ${bash}/bin/bash -e
    
    CONFIGDIR=$HOME/.ultrsc/REAPER
    
    # check if this script ran before:
    if [ -f "$CONFIGDIR/ultraschallInitScriptRunBefore" ]; then
      echo "Ultraschall was setup before, starting reaper."
    else
      echo "Ultraschall first time setup."
      cd "$(${coreutils}/bin/dirname $0)/.."
      mkdir -p "$CONFIGDIR"
      mkdir -p "$CONFIGDIR/UserPlugins"
      mkdir -p "$CONFIGDIR/Scripts"
      mkdir -p "$HOME/.vst3"
      mkdir -p "$HOME/.lv2"

      ${gnutar}/bin/tar xf ./themes/ultraschall-theme.tar -C "$CONFIGDIR"
      
      cp -fr ./plugins/* "$CONFIGDIR/UserPlugins"
      cp -fr ./scripts/* "$CONFIGDIR/Scripts"
      rm -rf "$HOME/.vst3/{studio-link-plugin.vst,Soundboard.vst3}"
      rm -rf "$HOME/.lv2/studio-link-onair.lv2"
      cp -fr "./custom-plugins/{studio-link-plugin.vst,Soundboard.vst3}" "$HOME/.vst3"
      cp -fr "./custom-plugins/studio-link-onair.lv2" "$HOME/.lv2"

      ${coreutils}/bin/touch "$CONFIGDIR/ultraschallInitScriptRunBefore"

      chmod -R +w "$CONFIGDIR"
      chmod -R +w "$HOME/.lv2"
      chmod -R +w "$HOME/.vst3"
    fi

    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ lame ffmpeg vlc ]}"''${LD_LIBRARY_PATH:+':'}$LD_LIBRARY_PATH
    exec -a "$0" "${reaperPackage}/opt/REAPER/reaper" "$@"
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
  ];

  runtimeDependencies = [
    gtk3
  ]
  ++ lib.optional jackSupport libjack2
  ++ lib.optional pulseaudioSupport libpulseaudio;

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
