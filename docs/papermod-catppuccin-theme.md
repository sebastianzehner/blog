# Catppuccin + PaperMod Theme Mapping

This document explains and provides **clean, semantically correct
mappings** between **Catppuccin** color roles and **PaperMod** theme
variables for Hugo.

------------------------------------------------------------------------

## Catppuccin Mocha --- Dark Theme (PaperMod)

### Semantics

-   Background: Base
-   Cards / Containers: Surface0
-   Main Text & Headlines: Text
-   Meta / Secondary Text: Subtext0
-   UI Decorations: Overlay1
-   Borders: Surface2
-   Code Blocks: Surface0
-   Inline Code: Surface1

### CSS

``` css
.dark {
  /* Catppuccin Mocha Accents */
  --rosewater: #f5e0dc;
  --flamingo: #f2cdcd;
  --pink: #f5c2e7;
  --mauve: #cba6f7;
  --red: #f38ba8;
  --maroon: #eba0ac;
  --peach: #fab387;
  --yellow: #f9e2af;
  --green: #a6e3a1;
  --teal: #94e2d5;
  --sky: #89dceb;
  --sapphire: #74c7ec;
  --blue: #89b4fa;
  --lavender: #b4befe;

  /* PaperMod mapping */
  --theme: #1e1e2e;        /* Base */
  --entry: #313244;        /* Surface0 */
  --primary: #cdd6f4;      /* Text */
  --secondary: #a6adc8;    /* Subtext0 */
  --tertiary: #7f849c;     /* Overlay1 */
  --content: #cdd6f4;      /* Text */
  --code-block-bg: #313244;/* Surface0 */
  --code-bg: #45475a;      /* Surface1 */
  --border: #585b70;       /* Surface2 */
}
```

------------------------------------------------------------------------

## Catppuccin Latte --- Light Theme (PaperMod)

### Semantics

-   Background: Base
-   Cards / Containers: Surface0
-   Main Text & Headlines: Text
-   Meta / Secondary Text: Subtext0
-   UI Decorations: Overlay1
-   Borders: Surface2
-   Code Blocks: Surface0
-   Inline Code: Surface1

### CSS

``` css
.light {
  /* Catppuccin Latte Accents */
  --rosewater: #dc8a78;
  --flamingo: #dd7878;
  --pink: #ea76cb;
  --mauve: #8839ef;
  --red: #d20f39;
  --maroon: #e64553;
  --peach: #fe640b;
  --yellow: #df8e1d;
  --green: #40a02b;
  --teal: #179299;
  --sky: #04a5e5;
  --sapphire: #209fb5;
  --blue: #1e66f5;
  --lavender: #7287fd;

  /* PaperMod mapping */
  --theme: #eff1f5;        /* Base */
  --entry: #e6e9ef;        /* Surface0 */
  --primary: #4c4f69;      /* Text */
  --secondary: #6c6f85;    /* Subtext0 */
  --tertiary: #9ca0b0;     /* Overlay1 */
  --content: #4c4f69;      /* Text */
  --code-block-bg: #e6e9ef;/* Surface0 */
  --code-bg: #dce0e8;      /* Surface1 */
  --border: #bcc0cc;       /* Surface2 */
}
```

------------------------------------------------------------------------

## Notes

-   The accent palette is intentionally kept complete for links, active
    states, status messages, and UI highlights.
-   This mapping preserves **contrast**, **hierarchy**, and **Catppuccin
    semantics** while fitting PaperMod's variable model.

Happy theming 🌿
