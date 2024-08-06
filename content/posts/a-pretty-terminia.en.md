+++
title = 'A modern and beautiful Terminal'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'Zusammenfassung'
date = 2024-07-28T16:14:53-04:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2024-07-28T16:14:53-04:00
draft = true #Entwurf wird noch nicht veröffentlicht
tags = ['Terminal', 'Linux', 'Fish', 'Starship', 'Alacritty']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/image.webp'
    alt = 'Beitragsbild von Quincho und Behandlungsraum sind fertig'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

This is a short guide on how to take your ugly terminal and make it modern and beautiful in just a few minutes.

## Fish

I will uninstall fish because I am using zsh-autosuggestions and zsh-syntax-highlighting.

[Link](https://fishshell.com/)

## Starship

I will uninstall starship because I am using the powerlevel10k theme. No, I want to use starship because powerlevel10k is outdated with no support and starship is nice with support and updates. I am using the Gruvbox Rainbow Preset.

### Installation

```
curl -sS https://starship.rs/install.sh | sh
```

### Setup Wezterm shell to use Starship

```
# ~/.zshrc

eval "$(starship init zsh)"
```

[Link](https://starship.rs/)

## WezTerm

I am using this shell with the powerlevel10k theme.

```
brew install --cask wezterm
```

First I used the [Spacegray (Gogh)](https://wezfurlong.org/wezterm/colorschemes/s/index.html#spacegray-gogh) Color Scheme but then switched to the custom colores from [Josean](https://www.josean.com/posts/how-to-setup-wezterm-terminal).

How to setup WezTerm? - [Link](https://www.josean.com/posts/how-to-setup-wezterm-terminal)

## Alacritty

I will uninstall Alacritty because I am using WezTerm Shell and I did not like the --no-quarantine point.
Is now uninstalled!!!

```
brew install --cask alacritty --no-quarantine
```

My config file `alacritty.toml` in `~/.config/alacritty`

```
live_config_reload = true

[font]
size = 22.0

[font.normal]
family = "Monoid Nerd Font Propo"
style = "Retina"

[window]
dimensions = { columns = 100, lines = 50 }
decorations = "Transparent"
dynamic_padding = false
opacity = 0.80
blur = true

[window.position]
x = 50
y = 200

[window.padding]
x = 20
y = 40

[colors.primary]
foreground = "#D4B680"
background = "#111111"

[colors]
cursor = { text = "#111111", cursor = "#D4B680" }

[cursor]
unfocused_hollow = true

[mouse]
hide_when_typing = true
```

Website [Link](https://alacritty.org/) and Homebrew [Link](https://formulae.brew.sh/cask/alacritty)

## Nerd Fonts

I am using the Monoid Nerd Font Mono in the .wezterm config file.

Website [Link](https://www.nerdfonts.com/)

## Eza

Installed and created a alias with "ls" in the .zshrc config file.

Website [Link](https://eza.rocks/)

## Yabai

Website [Link](https://www.josean.com/posts/yabai-setup)

## Skhd

Shortcuts for Yabai.

## NeoVim

Vim-based text editor.

{{< chat testroom >}}
