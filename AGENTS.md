# AGENTS.md — QEMU Camp 2026 Experiment Repository

This file guides agentic coding agents working in this repository. Read it before making changes.

## Repository Overview

This is a QEMU-based experiment repo for QEMU Camp 2026, covering four RISC-V experiment directions: CPU (TCG), SoC (QTest), GPGPU (QTest/QOS), and Rust (QTest + unit tests). The codebase is primarily C with a Rust subsystem (`rust/`).

**Key directories:**
- `hw/riscv/g233.c` — G233 machine definition
- `hw/gpgpu/` — GPGPU PCIe device
- `rust/hw/i2c/` — Rust I2C bus model
- `tests/gevico/tcg/` — CPU TCG test sources
- `tests/gevico/qtest/` — SoC and Rust QTest sources
- `tests/qtest/gpgpu-test.c` — GPGPU test source
- `scripts/checkpatch.pl` — C style checker
- `docs/devel/style.rst` — Official QEMU coding style reference

## Build Commands

All commands use `make -f Makefile.camp`. The build system is Meson/Ninja under the hood.

```bash
# Configure (creates build/ directory, runs Meson setup)
make -f Makefile.camp configure

# Build
make -f Makefile.camp build

# Clean
make -f Makefile.camp clean       # Clean artifacts
make -f Makefile.camp distclean   # Remove build/ entirely
```

Configure flags (set in Makefile.camp): `--target-list=riscv64-softmmu,riscv64-linux-user --extra-cflags='-O0 -g3' --enable-rust`

**Prerequisites:** RISC-V bare-metal cross compiler (`riscv64-unknown-elf-gcc`), Rust toolchain (MSRV 1.83.0), `bindgen-cli`.

## Test Commands

### Run All Tests
```bash
make -f Makefile.camp test
```

### Run by Experiment
```bash
make -f Makefile.camp test-cpu     # CPU: TCG testcases (10 tests)
make -f Makefile.camp test-soc     # SoC: QTest (10 tests)
make -f Makefile.camp test-gpgpu   # GPGPU: QOS subtests (17 tests)
make -f Makefile.camp test-rust    # Rust: unit + QTest (10 tests)
```

### Run a Single Test

**Single SoC QTest:**
```bash
cd build && ./pyvenv/bin/meson test --no-rebuild --print-errorlogs "qtest-riscv64/test-gpio-basic"
```
Available: `test-board-g233`, `test-gpio-basic`, `test-gpio-int`, `test-pwm-basic`, `test-wdt-timeout`, `test-spi-jedec`, `test-flash-read`, `test-flash-read-interrupt`, `test-spi-cs`, `test-spi-overrun`

**Single Rust QTest:**
```bash
cd build && ./pyvenv/bin/meson test --no-rebuild --print-errorlogs "qtest-riscv64/test-i2c-gpio-init"
```
Available: `test-i2c-gpio-init`, `test-i2c-gpio-bitbang`, `test-i2c-eeprom-rw`, `test-i2c-eeprom-page`, `test-spi-rust-init`, `test-spi-rust-transfer`, `test-spi-rust-flash`

**Single Rust Unit Test:**
```bash
cd build && ./pyvenv/bin/meson test --no-rebuild --test-args "test_i2c_bus_read_write" rust-i2c-unit
```
Available: `test_i2c_bus_create`, `test_i2c_bus_read_write`, `test_i2c_bus_nack`

**Single GPGPU Subtest:**
```bash
build/tests/qtest/qos-test \
  -p /riscv64/virt/generic-pcihost/pci-bus-generic/pci-bus/gpgpu/gpgpu-tests/device-id \
  --tap -k
```
Subtests: `device-id`, `vram-size`, `global-ctrl`, `dispatch-regs`, `vram-access`, `dma-regs`, `irq-regs`, `simt-thread-id`, `simt-block-id`, `simt-warp-lane`, `simt-thread-mask`, `simt-reset`, `kernel-exec`, `fp-kernel-exec`, `lp-convert`, `lp-convert-e5m2-e2m1`, `lp-convert-saturate`

**CPU TCG Tests** (run as a group):
```bash
make -C build check-gevico-tcg
```

## C Code Style

Reference: `docs/devel/style.rst` (authoritative), `.editorconfig`, `.dir-locals.el`

### Formatting
- **Indent:** 4 spaces, no tabs (except Makefiles: tabs, size 8)
- **Line length:** target 80 chars; checkpatch warns at 100
- **Braces:** Function opening brace on its own line; control-block braces on same line
- **Trailing whitespace:** forbidden
- **File ending:** newline at end of file

### Naming Conventions
- **Types/structs:** PascalCase — `DeviceState`, `ARMCPU`, `CPUState`
- **Functions:** snake_case with subsystem prefix — `qemu_log()`, `qdev_realize()`, `error_setg_errno()`
- **Variables:** snake_case — `local_err`, `dev_path`
- **Constants/macros:** UPPER_SNAKE_CASE — `CPU_LOG_TB_OUT_ASM`, `GPGPU_REG_CTRL`
- **Files:** lowercase; match subsystem convention (hyphen or underscore) — `qemu-coroutine.c`, `g233.c`
- **Suffixes:** `_locked` (lock-required variant), `_impl` (implementation)

### Include Order (mandatory)
1. `"qemu/osdep.h"` — ALWAYS first in `.c` files, NEVER in headers
2. System headers `<...>`
3. QEMU/internal headers `"..."`

### Comments
- Use `/* ... */` block comments with leading asterisk column for multi-line
- Avoid `//` comments
- No Doxygen-style; use `docs/` `.rst` for developer docs

### Error Handling
- Use `Error **errp` for rich diagnostics: `error_setg_errno()`, `error_propagate()`, `error_report()`
- Simple returns: non-negative on success, `-errno` or `NULL` on failure
- Never use `printf`/`fprintf` for user-visible errors; use `error_report()`
- `error_abort` / `error_fatal` are special — only for unrecoverable startup errors

### Types and Attributes
- Fixed-width: `uint32_t`, `uint64_t` for width-critical fields
- QEMU address types: `vaddr`, `target_ulong`, `ram_addr_t`, `hwaddr`
- Annotate printf-style functions with `G_GNUC_PRINTF(n, m)`
- Use `g_autofree`/`g_autoptr` for automatic cleanup
- Use `const`-correct pointers

### Style Checking
```bash
perl scripts/checkpatch.pl --file <path/to/file.c>
```

## Rust Code Style

Workspace: `rust/Cargo.toml` (MSRV 1.83.0, edition 2021)

### Linting
- Extensive Clippy lints enforced (see `[workspace.lints.clippy]` in `rust/Cargo.toml`)
- `missing_safety_doc = "deny"` — document all `unsafe` blocks
- `dbg_macro = "deny"` — no `dbg!()` in committed code
- `uninlined_format_args = "deny"` — use inline format args: `format!("{x}")` not `format!("{}", x)`
- `unsafe_op_in_unsafe_fn = "deny"` — explicit unsafe in unsafe fns

### Formatting
```bash
cargo fmt  # follow rustfmt defaults
cargo clippy --workspace  # lint check
```

### Unit Tests
Rust unit tests live in the same source files (`#[cfg(test)] mod tests`). Run via Meson:
```bash
cd build && ./pyvenv/bin/meson test --no-rebuild rust-i2c-unit
```

## CI Behavior

- Trigger: push to `main` (ignores `README.md`, `docs/`)
- Four parallel jobs (CPU, SoC, GPGPU, Rust) on Ubuntu 24.04
- Each job: install deps → configure → build → run tests → calculate score → upload
- **Failing tests do not break CI** — they reduce the score
- Scores of 0 are not uploaded to the ranking platform
- Score formula: `(passed_cases * points_per_case)` or `(passed * 100 / total)` for GPGPU

## Canonical Example Files

When unsure about style, refer to these files:
- `util/error.c` — Error object patterns, `Error **errp` usage
- `util/log.c` — Include ordering, `qemu_` prefix, logging patterns
- `hw/core/qdev.c` — QOM naming, guard macros, device lifecycle
- `rust/hw/i2c/src/lib.rs` — Rust module structure, doc comments, trait design
