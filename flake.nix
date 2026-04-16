{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      riscvToolchain = pkgs.pkgsCross.riscv64-embedded.stdenv.cc;

      # Nixpkgs uses "riscv64-none-elf-" prefix, but the project expects
      # "riscv64-unknown-elf-". Create symlinks with the expected prefix.
      riscvWrapper = pkgs.runCommandLocal "riscv64-unknown-elf-toolchain" {}
        ''
          mkdir -p $out/bin
          for bin in ${riscvToolchain}/bin/riscv64-none-elf-*; do
            name=$(basename "$bin")
            ln -s "$bin" "$out/bin/''${name/riscv64-none-elf-/riscv64-unknown-elf-}"
          done
          for bin in ${riscvToolchain}/bin/*; do
            name=$(basename "$bin")
            [ ! -e "$out/bin/$name" ] && ln -s "$bin" "$out/bin/$name"
          done
        '';

      # FHS environment for /usr/bin, /usr/lib, /usr/include structure
      fhsEnv = pkgs.buildFHSEnv {
        pname = "qemu-camp-dev";
        version = "1.0";

        nativeBuildInputs = with pkgs; [
          gcc gnumake pkg-config meson ninja
          python3 python3Packages.pip python3Packages.setuptools python3Packages.wheel
          glib pixman dtc zlib bzip2 lzo zstd snappy capstone
          liburing libseccomp libslirp libssh curl
          gnutls nettle libgcrypt
          SDL2 SDL2_image gtk3 vte libepoxy libdrm virglrenderer
          usbredir spice-protocol spice-gtk libusb1 ncurses libaio
          perl flex bison texinfo file which git rsync
          diffutils patch autoconf automake libtool
          findutils coreutils gnugrep gnused gawk bash
          rustc cargo rustfmt clippy
          clang llvmPackages.libclang
        ];

        runScript = "bash";

        extraBwrapArgs = [
          "--dir" "/usr/lib"
          "--dir" "/usr/include"
        ];
      };

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ fhsEnv ] ++ (with pkgs; [
          gcc gnumake pkg-config meson ninja
          python3 python3Packages.pip python3Packages.setuptools python3Packages.wheel
          glib pixman dtc zlib bzip2 lzo zstd snappy capstone
          liburing libseccomp libslirp libssh curl
          gnutls nettle libgcrypt
          SDL2 SDL2_image gtk3 vte libepoxy libdrm virglrenderer
          usbredir spice-protocol spice-gtk libusb1 ncurses libaio
          perl flex bison texinfo file which git rsync
          diffutils patch autoconf automake libtool
          findutils coreutils gnugrep gnused gawk bash
          rustc cargo rustfmt clippy
          clang llvmPackages.libclang
        ]);

        CROSS_PREFIX = "riscv64-unknown-elf-";
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

        shellHook = ''
          export PATH="${riscvWrapper}/bin:${pkgs.meson}/bin:${pkgs.ninja}/bin:${pkgs.pkg-config}/bin:$PATH"
          export CROSS_PREFIX="riscv64-unknown-elf-"
          export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"

          echo "=========================================="
          echo "  QEMU Camp 2026 — devShell"
          echo "=========================================="
          echo "RISC-V GCC:  $(riscv64-unknown-elf-gcc --version 2>/dev/null | head -1 || echo 'not found')"
          echo "Rust:        $(rustc --version 2>/dev/null || echo 'not found')"
          echo "Meson:       $(meson --version 2>/dev/null || echo 'not found')"
          echo ""
          echo "Commands:"
          echo "  make -f Makefile.camp configure"
          echo "  make -f Makefile.camp build"
          echo "  make -f Makefile.camp test-cpu"
          echo "  make -f Makefile.camp test-soc"
          echo "  make -f Makefile.camp test-gpgpu"
          echo "  make -f Makefile.camp test-rust"
          echo ""
          echo "For FHS structure (/usr/bin, /usr/lib, /usr/include), run: qemu-camp-dev"
        '';
      };
    };
}
