// Smoke-test a ruby+stdlib.wasm build: it must boot and report the expected RUBY_VERSION.
import { openSync, readFileSync, readSync, fstatSync } from "node:fs";
import { WASI } from "node:wasi";
import { RubyVM } from "@ruby/wasm-wasi/dist/vm";

const [file, expected] = process.argv.slice(2);
if (!file || !expected) {
  console.error("usage: node scripts/verify-ruby-wasm.mjs <file.wasm> <expected-version>");
  process.exit(2);
}

// Print enough detail to diagnose a failed boot (Node's default output can be empty).
const describe = (e) =>
  `${e?.name ?? typeof e}: ${e?.message ?? String(e)}\n${e?.stack ?? ""}` +
  (e?.cause ? `\ncause: ${describe(e.cause)}` : "");

// Same as DefaultRubyVM, but keeps the WASI instance so we can read the exit code
// when the Ruby VM calls exit during boot (Node reports that as a thrown Symbol).
// stdout/stderr go to files so we can show what Ruby printed before it exited.
const outPath = `${file}.stdout.log`;
const errPath = `${file}.stderr.log`;
const wasi = new WASI({
  version: "preview1",
  returnOnExit: true,
  stdout: openSync(outPath, "w"),
  stderr: openSync(errPath, "w"),
});
const tail = (path) => {
  const fd = openSync(path, "r");
  const { size } = fstatSync(fd);
  const buf = Buffer.alloc(Math.min(size, 4000));
  readSync(fd, buf, 0, buf.length, Math.max(0, size - buf.length));
  return buf.toString("utf8").trimEnd() || "(empty)";
};

let actual;
try {
  const module = await WebAssembly.compile(readFileSync(file));
  const { vm } = await RubyVM.instantiateModule({ module, wasip1: wasi });
  actual = vm.eval("RUBY_VERSION").toString();
} catch (e) {
  const exitSymbol = Object.getOwnPropertySymbols(wasi).find((s) => s.description === "kExitCode");
  // The Ruby VM exited (vs. failing to compile/instantiate) when a Symbol is thrown.
  const exited = typeof e === "symbol" && exitSymbol !== undefined;
  const exitInfo = exited ? `exited with code ${wasi[exitSymbol]}` : "did not exit";
  console.error(`failed to boot ${file} (${exitInfo}):\n${describe(e)}`);
  console.error(`--- ruby stderr ---\n${tail(errPath)}`);
  console.error(`--- ruby stdout ---\n${tail(outPath)}`);
  process.exit(1);
}

if (actual !== expected) {
  console.error(`expected Ruby ${expected}, got ${actual}`);
  process.exit(1);
}
console.log(`ok: ${file} boots as Ruby ${actual}`);
