# AGENTS.md — QEMU Camp 2026 Experiment Repository

This file guides agentic coding agents working in this repository. Read it before making changes.

## Repository Overview

QEMU-based experiment repo for QEMU Camp 2026. Four RISC-V experiment directions: CPU (TCG), SoC (QTest), GPGPU (QTest/QOS), Rust (QTest + unit tests). Primarily C with a Rust subsystem (`rust/`).

**Key directories:**
- `hw/riscv/g233.c` — G233 machine definition
- `hw/gpgpu/` — GPGPU PCIe device
- `rust/hw/i2c/src/` — Rust I2C bus model (`lib.rs`, `bus.rs`)
- `tests/gevico/tcg/` — CPU TCG test sources
- `tests/gevico/qtest/` — SoC and Rust QTest sources
- `tests/qtest/gpgpu-test.c` — GPGPU test source
- `scripts/checkpatch.pl` — C style checker
- `docs/devel/style.rst` — Authoritative QEMU coding style reference

## Build Commands

All commands use `make -f Makefile.camp` (Meson/Ninja under the hood).

```bash
make -f Makefile.camp configure   # Creates build/, runs Meson setup
make -f Makefile.camp build       # Build QEMU
make -f Makefile.camp rebuild     # Clean + rebuild
make -f Makefile.camp clean       # Clean artifacts
make -f Makefile.camp distclean   # Remove build/ entirely
```

Configure flags (set in Makefile.camp): `--target-list=riscv64-softmmu,riscv64-linux-user --extra-cflags='-O0 -g3' --enable-rust`

**Prerequisites:** RISC-V bare-metal cross compiler (`riscv64-unknown-elf-gcc`), Rust toolchain (MSRV 1.83.0), `bindgen-cli`.

## Test Commands

### Run All or by Experiment
```bash
make -f Makefile.camp test          # All tests
make -f Makefile.camp test-cpu      # CPU: TCG testcases (10 tests × 10 pts)
make -f Makefile.camp test-soc      # SoC: QTest (10 tests × 10 pts)
make -f Makefile.camp test-gpgpu    # GPGPU: QOS subtests (17 tests → 100 pts)
make -f Makefile.camp test-rust     # Rust: unit + QTest (10 tests × 10 pts)
make -f Makefile.camp test-rust-unit   # Rust unit tests only (3 tests)
make -f Makefile.camp test-rust-qtest  # Rust QTest only (7 tests)
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

**CPU TCG Tests** (run as a group only):
```bash
make -C build check-gevico-tcg
```

## C Code Style

Reference: `docs/devel/style.rst` (authoritative), `.editorconfig`, `.dir-locals.el` (`c-file-style: stroustrup`)

### Formatting
- **Indent:** 4 spaces, no tabs (except Makefiles: tabs, size 8; assembly: tabs, size 8)
- **Line length:** target 80 chars; checkpatch warns at 100
- **Braces:** Function opening brace on its own line; control-block braces on same line (`if/else if/else` all braced)
- **Trailing whitespace:** forbidden; **file ending:** newline at EOF
- **Declarations:** at block start; `for (int i = ...)` loop vars are allowed

### Naming Conventions
- **Types/structs:** PascalCase — `DeviceState`, `ARMCPU`, `CPUState`
- **Functions:** snake_case with subsystem prefix — `qemu_log()`, `qdev_realize()`, `error_setg_errno()`
- **Variables:** snake_case — `local_err`, `dev_path`; common shortcuts: `cs` (CPUState), `env` (CPUArchState), `dev` (DeviceState)
- **Constants/macros:** UPPER_SNAKE_CASE — `CPU_LOG_TB_OUT_ASM`, `GPGPU_REG_CTRL`
- **Files:** lowercase; match subsystem convention — `qemu-coroutine.c`, `g233.c`
- **Suffixes:** `_locked` (lock-required variant), `_impl` (implementation), `_compat` (compatibility shim)

### Include Order (mandatory)
1. `"qemu/osdep.h"` — ALWAYS first in `.c` files, NEVER in headers
2. System headers `<...>`
3. QEMU/internal headers `"..."`
- Headers should be self-contained; use `qemu/typedefs.h` for forward declarations
- Template includes use `.c.inc` / `.h.inc` suffixes

### Comments
- `/* ... */` only; avoid `//`; checkpatch warns on `//`
- Multi-line: leading asterisk column (`/*` on own line, `*/` on own line)
- No Doxygen-style; developer docs go in `docs/` `.rst`

### QOM Declarations (critical for device implementation)
- Instance struct: first member is `ParentType parent_obj;` (must be named `parent_obj`)
- Class struct: first member is `ParentClass parent_class;` (must be named `parent_class`)
- Separate properties (user-driven) from internal state with comments
- Typedefs are auto-generated by QOM macros — do not write them manually

### Error Handling
- Use `Error **errp` for rich diagnostics: `error_setg_errno()`, `error_propagate()`, `error_report()`
- Simple returns: non-negative on success, `-errno` or `NULL` on failure
- Never use `printf`/`fprintf` for user-visible errors; use `error_report()`
- `error_abort` / `error_fatal` — only for unrecoverable startup errors

### Memory Management
- **Forbidden:** `malloc`, `free`, `realloc`, `calloc`, `alloca`, `strdup`
- **Use:** `g_malloc`, `g_malloc0`, `g_new(Type, n)`, `g_realloc`, `g_free`
- Prefer `g_new(T, n)` over `g_malloc(sizeof(T) * n)` — type-safe, overflow-safe
- Use `g_autofree` / `g_autoptr` for automatic cleanup; always initialize g_auto* variables
- Use `g_steal_pointer(&ptr)` to transfer ownership out of g_auto* scope

### Types and Register Fields
- Fixed-width: `uint32_t`, `uint64_t` for width-critical and VMState fields
- QEMU address types: `hwaddr` (guest phys), `vaddr` (guest virt, target-independent), `target_ulong` (target-dependent), `ram_addr_t` (RAM offset)
- Annotate printf-style functions with `G_GNUC_PRINTF(n, m)`
- Use `const`-correct pointers consistently
- **Avoid C bitfields** in packed/guest-layout structs; use `include/hw/core/registerfields.h` macros instead
- Avoid reserved namespaces: no `_Capital`, `__`, or `_t` suffixes for your names

### Style Checking
```bash
perl scripts/checkpatch.pl --file <path/to/file.c>
```

## Rust Code Style

Workspace: `rust/Cargo.toml` (MSRV 1.83.0, edition 2021). The I2C module (`rust/hw/i2c/`) is built via Meson, not as a workspace member.

### Key Clippy Lints (enforced as deny)
- `missing_safety_doc` — document all `unsafe` blocks
- `dbg_macro` — no `dbg!()` in committed code
- `uninlined_format_args` — `format!("{x}")` not `format!("{}", x)`
- `unsafe_op_in_unsafe_fn` — explicit unsafe in unsafe fns
- `ptr_as_ptr`, `as_ptr_cast_mut`, `cast_lossless` — no raw pointer cast abuse
- `cognitive_complexity` — keep functions simple
- Full list: see `[workspace.lints.clippy]` in `rust/Cargo.toml`

### Formatting and Linting
```bash
cargo fmt            # rustfmt defaults
cargo clippy --workspace  # lint check
```

### Unit Tests
Rust unit tests live in the same source files (`#[cfg(test)] mod tests`). Run via Meson:
```bash
cd build && ./pyvenv/bin/meson test --no-rebuild rust-i2c-unit
```

## CI Behavior

- **Trigger:** push to `main` (ignores `README.md`, `docs/`)
- **Four parallel jobs** (CPU, SoC, GPGPU, Rust) on Ubuntu 24.04
- Each job: install deps → configure → build → run tests → calculate score → upload
- **Failing tests do not break CI** — they reduce the score
- Scores of 0 are not uploaded to the ranking platform
- **Scoring:** CPU/SoC/Rust: `passed × 10` (10 tests × 10 pts = 100). GPGPU: `passed × 100 / 17` (rounded down)
- Result logs: `build/tests/gevico/tcg/riscv64-softmmu/result.log` (CPU), `build/soc-result.log`, `build/gpgpu-result.log`, `build/rust-result.log`

## Canonical Example Files

When unsure about style, refer to these files:
- `util/error.c` — Error object patterns, `Error **errp` usage
- `util/log.c` — Include ordering, `qemu_` prefix, logging patterns
- `hw/core/qdev.c` — QOM naming, guard macros, device lifecycle
- `hw/riscv/g233.c` — G233 machine definition, QOM device patterns
- `rust/hw/i2c/src/lib.rs` — Rust module structure, doc comments, trait design
