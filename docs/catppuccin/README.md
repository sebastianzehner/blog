# Catppuccin Reference File

File `mocha.css` comes from the npm package:

- [`@catppuccin/tailwindcss`](https://github.com/catppuccin/tailwindcss).

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
highlighting).

## About the @custom-variant lines

```css
@custom-variant latte (&:where(.latte, .latte *));
@custom-variant frappe (&:where(.frappe, .frappe *));
@custom-variant macchiato (&:where(.macchiato, .macchiato *));
@custom-variant mocha (&:where(.mocha, .mocha *));
```

These define variant selectors (e.g. `latte:bg-`..., `mocha:text-`...) for
projects that use `@catppuccin/tailwindcss` directly in a Tailwind v4 setup. Not
active on this blog – although Blowfish uses modern Tailwind v4, it manages its
color themes natively via custom CSS variables (see `catppuccin.css`). This file
is kept purely as a value reference.

## Future Improvements: Dynamic Tailwind Integration

Currently, the Catppuccin flavors are integrated via static value references to
keep the build process lightweight and native to Blowfish's default CSS variable
system.

If we ever want to use actual dynamic utility variants (like `mocha:text-mauve`
or `latte:bg-base`) directly inside Hugo markdown or layouts, we can unlock the
full Tailwind v4 compilation pipeline.

To achieve this:

1. We need to build the Blowfish theme CSS directly from source.
2. Integrate the `@catppuccin/tailwindcss` package into the main compilation step.

For a complete guide on how to set up the local Tailwind compiler and adjust the
`package.json` build scripts within the Hugo project, refer to the official
Blowfish documentation:
👉 [Blowfish Docs: Building the theme CSS from source](https://blowfish.page/docs/advanced-customisation/#building-the-theme-css-from-source)

## Source

- Repo: [@catppuccin/tailwindcss](https://github.com/catppuccin/tailwindcss)
- Installed temporarily via: `npm install @catppuccin/tailwindcss` (in a
  scratch directory, not part of this repo)
- Date: June 2026
