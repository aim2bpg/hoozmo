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

Hoozmo provides a minimal, educational regular-expression engine suitable for learning and experimentation. The parser and matcher in `lib/` (and the browser demo) support the core constructs below.

- **Literals**: match single characters exactly (examples: `a`, `b`, `1`).
- **Concatenation**: adjacent tokens are matched in sequence (example: `abc` matches `abc`).
- **Grouping**: parentheses `()` create groups for sequencing or alternation (example: `a(bc)d`).
- **Alternation / Choice**: the `|` operator selects between alternatives (examples: `a|b`, `a|b|c`).
- **Nested groups**: groups may be nested to express more complex structure (example: `a((b|c)|d)e`).
- **Kleene closure / Repetition**: `*` matches the preceding element zero or more times (example: `a*`).

Notes:
- This project focuses on clarity and pedagogical value rather than full PCRE compatibility.
- To add features, update the parser in `lib/hoozmo/parser.rb` and add tests under `spec/`.

Examples (these are also available in the browser demo):

- `abc` — literal concatenation, matches exactly `abc`.
- `a|b` — alternation, matches `a` or `b`.
- `a|b|c` — multiple alternatives.
- `a(b|c)d` — grouping with alternation (e.g. matches `acd`).
- `a((b|c)|d)e` — nested grouping with alternation (e.g. matches `ade`).
- `a*` — Matches zero or more (e.g. `a*`).
 
### Browser demo examples (pattern + test string)

- Pattern: `abc` — Test string: `abc`
- Pattern: `a|b` — Test string: `b`
- Pattern: `a|b|c` — Test string: `c`
- Pattern: `a(b|c)d` — Test string: `acd`
- Pattern: `a((b|c)|d)e` — Test string: `ade`
- Pattern: `a*` — Test string: `aaa`

Browser demo: open the project in a browser (or run the dev server with `npm run dev`) and open `index.html` — the Examples panel on the page inserts the pattern and test string into the fields when clicked.

If you want to extend the parser with additional features, add tests under `spec/` and update `lib/hoozmo/parser.rb` and `lib/hoozmo.rb` accordingly.
