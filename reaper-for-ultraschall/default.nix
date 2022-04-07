{ alsa-lib
, autoPatchelfHook
, bbe
, config
, fetchurl
, ffmpeg
, gtk3
, jackSupport ? true
, lame
, lib
, libjack2
, libpulseaudio
, makeWrapper
, pkgs
, pulseaudioSupport ? config.pulseaudio or true
, stdenv
, vlc
, which
, xdg-utils
}:

stdenv.mkDerivation rec {
  pname = "reaper-for-ultraschall";
  version = "6.27"; # ultraschall needs this older version of reaper!
  src = fetchurl {
    url = "https://www.reaper.fm/files/${lib.versions.major version}.x/reaper${builtins.replaceStrings ["."] [""] version}_linux_${stdenv.hostPlatform.qemuArch}.tar.xz";
    hash = "sha256-6zHZK1ZYVSuCwZFWiBNJWhlk7Sau/paw+FMAaiVJHbg=";
  };

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
  ];

  runtimeDependencies = [
    gtk3
  ]
  ++ lib.optional jackSupport libjack2
  ++ lib.optional pulseaudioSupport libpulseaudio;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    HOME="$out/share" XDG_DATA_HOME="$out/share" ./install-reaper.sh --install $out/opt --integrate-user-desktop
    rm $out/opt/REAPER/uninstall-reaper.sh

    # Reaper has no commandline option or ENV variable to set the config folder.
    # We have to patch the config folder location string ".config" to ".ultrsc",
    # so we can install ultraschall and the vanilla reaper side by side.
    ${bbe}/bin/bbe -e "s/.config\0/.ultrsc\0/" $out/opt/REAPER/reaper --output=$out/opt/REAPER/reapertmp
    cp $out/opt/REAPER/reapertmp $out/opt/REAPER/reaper && rm $out/opt/REAPER/reapertmp

    runHook postInstall
  '';

  meta = with lib; {
    description = "Reaper Digital audio workstation package for ultraschall";
    homepage = "https://www.reaper.fm/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ fernsemuell ];
  };
}
