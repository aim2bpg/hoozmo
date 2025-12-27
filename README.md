# Hoozmo (Hoozuki-mod)

[![CI](https://github.com/aim2bpg/hoozmo/actions/workflows/ci.yml/badge.svg)](https://github.com/aim2bpg/hoozmo/actions/workflows/ci.yml) [![Pages](https://github.com/aim2bpg/hoozmo/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/aim2bpg/hoozmo/actions/workflows/pages/pages-build-deployment)

Hoozmo is a hobby regex engine written in Ruby, created while learning from [Hoozuki](https://github.com/ydah/hoozuki).

## Quick start

Install dependencies:

```bash
npm install
bundle install
```

Run tests:

```bash
bundle exec rspec
```

Build production assets:

```bash
npm run build
# output -> dist/
```

Run the frontend dev server:

```bash
npm run dev
# open http://localhost:3000
```

## Supported features

Hoozmo implements a tiny, educational regular-expression language. The following features are supported by the parser and matcher included in `lib/` and in the browser demo:

- Literals: single characters are matched literally (e.g. `a`, `b`, `1`).
- Concatenation: adjacent characters form a sequence (e.g. `abc` matches `abc`).
- Choice / Alternation: the `|` operator selects between alternatives (e.g. `a|b` matches `a` or `b`).

Examples (these are also available in the browser demo):

- `abc` — literal concatenation, matches exactly `abc`.
- `a|b` — alternation, matches `a` or `b`.
- `a|b|c` — multiple alternatives.

If you want to extend the parser with additional features, add tests under `spec/` and update `lib/hoozmo/parser.rb` and `lib/hoozmo.rb` accordingly.
