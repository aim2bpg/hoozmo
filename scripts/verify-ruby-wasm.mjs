// Smoke-test a ruby+stdlib.wasm build: it must boot and report the expected RUBY_VERSION.
import { readFileSync } from "node:fs";
import { DefaultRubyVM } from "@ruby/wasm-wasi/dist/node";

const [file, expected] = process.argv.slice(2);
if (!file || !expected) {
  console.error("usage: node scripts/verify-ruby-wasm.mjs <file.wasm> <expected-version>");
  process.exit(2);
}

// Print enough detail to diagnose a failed boot (Node's default output can be empty).
const describe = (e) =>
  `${e?.name ?? typeof e}: ${e?.message ?? String(e)}\n${e?.stack ?? ""}` +
  (e?.cause ? `\ncause: ${describe(e.cause)}` : "");

let actual;
try {
  const module = await WebAssembly.compile(readFileSync(file));
  const { vm } = await DefaultRubyVM(module);
  actual = vm.eval("RUBY_VERSION").toString();
} catch (e) {
  console.error(`failed to boot ${file}:\n${describe(e)}`);
  process.exit(1);
}

if (actual !== expected) {
  console.error(`expected Ruby ${expected}, got ${actual}`);
  process.exit(1);
}
console.log(`ok: ${file} boots as Ruby ${actual}`);
