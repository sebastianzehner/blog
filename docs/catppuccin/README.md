# Catppuccin Reference File

`mocha.css` comes from the npm package [`@catppuccin/tailwindcss`](https://github.com/catppuccin/tailwindcss).
Despite the filename, it contains the official color values for **all four
Catppuccin flavors** (Latte, Frappé, Macchiato, Mocha), including the generated
50-950 ramps for every accent color (Mauve, Blue, Sapphire, etc.) and the
neutral tones (Text, Subtext, Overlay, Surface, Base, Mantle, Crust).

## Structure

The file uses Tailwind v4 syntax:

- `@theme inline { ... }` - defines the color tokens as CSS custom properties
- `@layer base { ... }` - base layer styles
- `@variant dark`, `.latte`, `.frappe`, `.macchiato`, `.mocha` - each flavor's
  values are scoped under its own variant block

## Usage

These values were the basis for `assets/css/schemes/catppuccin.css` (Blowfish
color scheme) and `assets/css/custom.css` (Catppuccin Mocha Chroma syntax
highlighting). See the wiki section "Theme Catppuccin" for details on the
implementation.

## About the @custom-variant lines

```css
@custom-variant latte (&:where(.latte, .latte *));
@custom-variant frappe (&:where(.frappe, .frappe *));
@custom-variant macchiato (&:where(.macchiato, .macchiato *));
@custom-variant mocha (&:where(.mocha, .mocha *));
```

These define variant selectors (e.g. `latte:bg-...`, `mocha:text-...`) for
projects that use `@catppuccin/tailwindcss` directly in a Tailwind v4 setup.
**Not relevant for this blog** - Blowfish uses its own (older) color system
based on `--color-*` CSS variables, see `catppuccin.css`. This file is kept
purely as a value reference.

## Source

- Repo: https://github.com/catppuccin/tailwindcss
- Installed temporarily via: `npm install @catppuccin/tailwindcss` (in a
  scratch directory, not part of this repo)
- Date: June 2026
