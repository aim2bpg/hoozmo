// Smoke-test a ruby+stdlib.wasm build: it must boot and report the expected RUBY_VERSION.
import { readFileSync } from "node:fs";
import { DefaultRubyVM } from "@ruby/wasm-wasi/dist/node";

const [file, expected] = process.argv.slice(2);
if (!file || !expected) {
  console.error("usage: node scripts/verify-ruby-wasm.mjs <file.wasm> <expected-version>");
  process.exit(2);
}

const module = await WebAssembly.compile(readFileSync(file));
const { vm } = await DefaultRubyVM(module);
const actual = vm.eval("RUBY_VERSION").toString();

if (actual !== expected) {
  console.error(`expected Ruby ${expected}, got ${actual}`);
  process.exit(1);
}
console.log(`ok: ${file} boots as Ruby ${actual}`);
