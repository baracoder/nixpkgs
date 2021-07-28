{ version
, url ? null
, sha256_32bit ? null
, sha256_64bit
, settingsSha256
, settingsVersion ? version
, persistencedSha256
, persistencedVersion ? version
, useGLVND ? true
, useProfiles ? true
, preferGtk2 ? false

, prePatch ? ""
, patches ? []
, broken ? false
}@args:

{ lib, stdenv, callPackage, pkgs, pkgsi686Linux, fetchurl, util-linux, glibc, gnutar, xz, which, wayland, autoPatchelfHook
, kernel ? null, perl, nukeReferences
, # Whether to build the libraries only (i.e. not the kernel module or
  # nvidia-settings).  Used to support 32-bit binaries on 64-bit
  # Linux.
  libsOnly ? false
  # 32 bit libs only version of this package
, lib32 ? null
}:

with lib;

assert !libsOnly -> kernel != null;
assert stdenv.hostPlatform.system == "x86_64-linux";

let
  nameSuffix = optionalString (!libsOnly) "-${kernel.version}";
  pkgSuffix = "";
  i686bundled = true;

  libPathFor = pkgs: pkgs.lib.makeLibraryPath [ pkgs.libdrm pkgs.xorg.libXext pkgs.xorg.libX11
    pkgs.xorg.libXv pkgs.xorg.libXrandr pkgs.xorg.libxcb pkgs.zlib pkgs.stdenv.cc.cc ];

  self = stdenv.mkDerivation {
    name = "nvidia-x11-${version}${nameSuffix}";

    src = fetchurl {
        url = args.url or "https://us.download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}${pkgSuffix}.run";
        sha256 = sha256_64bit;
    };

    patches = if libsOnly then null else patches;
    inherit prePatch;
    inherit version useGLVND useProfiles;
    inherit (stdenv.hostPlatform) system;
    inherit i686bundled;

    outputs = [ "out" "doc" ]
        ++ optional i686bundled "lib32"
        ++ optional (!libsOnly) "bin";
    outputDev = if libsOnly then null else "bin";

    kernel = if libsOnly then null else kernel.dev;
    kernelVersion = if libsOnly then null else kernel.modDirVersion;

    hardeningDisable = [ "pic" "format" ];

    dontStrip = true;
    dontPatchELF = true;

    libPath = libPathFor pkgs;
    libPath32 = optionalString i686bundled (libPathFor pkgsi686Linux);

    buildInputs = [ glibc xz wayland ];
    nativeBuildInputs = [ perl nukeReferences util-linux glibc gnutar xz which autoPatchelfHook ]
      ++ optionals (!libsOnly) kernel.moduleBuildDependencies;

    disallowedReferences = optional (!libsOnly) [ kernel.dev ];

    passthru = {
      settings = callPackage (import ./settings.nix self settingsSha256) {
        withGtk2 = preferGtk2;
        withGtk3 = !preferGtk2;
      };
      persistenced = mapNullable (hash: callPackage (import ./persistenced.nix self hash) { }) persistencedSha256;
      inherit persistencedVersion settingsVersion;
    } // optionalAttrs (!i686bundled) {
      inherit lib32;
    };

    builder = ./builder-v2.sh;

    meta = with lib; {
      homepage = "https://www.nvidia.com/object/unix.html";
      description = "X.org driver and kernel module for NVIDIA graphics cards";
      license = licenses.unfreeRedistributable;
      platforms = [ "x86_64-linux" ] ++ optionals (!i686bundled) [ "i686-linux" ];
      maintainers = with maintainers; [ baracoder ];
      priority = 4; # resolves collision with xorg-server's "lib/xorg/modules/extensions/libglx.so"
      inherit broken;
    };
  };
in self