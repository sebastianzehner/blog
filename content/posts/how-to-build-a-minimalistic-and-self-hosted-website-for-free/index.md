+++
title = 'How to build a simple and self-hosted website for free'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = '''You're here on my new minimalistic and free website. I built this website some weeks ago because I like it simple and replaced WordPress with Hugo and PaperMod Theme for my personal blog on the Internet.'''
date = 2024-07-22T10:29:42-04:00 #Ctrl+Shift+I to insert date and time
lastmod = 2024-07-22T10:29:42-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Website', 'Hugo', 'PaperMod']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/how-to-build-a-minimalistic-and-self-hosted-website-for-free.webp'
    alt = 'Featured image from How to build a simple and self-hosted website for free'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

You're here on my new minimalistic and free website. I built this website some weeks ago because I like it simple and replaced WordPress with Hugo and PaperMod Theme for my personal blog on the Internet. I moved some older blog posts and wrote some new posts on this platform. It's really nice and I like this - it's free and open source.

Today I want to show you how to build a minimalistic and self-hosted website for free - how I did it. I installed Hugo on a Mac Studio but it works also on Linux or Windows machines. I like this so much that I will create a second Hugo site with the Smol Theme for my Intranet at home.

But now let's start with the installation and first steps:

## Download and install Visual Studio Code

I'm using Visual Studio Code on my Mac Studio to write an config all my stuff. This application is open source and works on other systems as well. I downloaded the Mac version and just unzipped the file and moved it to the application folder. That's all and now we can run Visual Studio Code with one simple mouse click on the app.

I also commit und sync my website with Visual Studio Code on GitHub.

It's all for free and you can host your website directly on GitHub and create a URL or use Netlify as I do. Maybe I will tell you later how this works. First you can download Visual Studio Code [here](https://code.visualstudio.com/).

## Install Homebrew on Mac

The easiest way to install Hugo is using the package manager Homebrew.

By the way this also works for other Linux machines. I copied the command from the [website](https://brew.sh/) and pasted it to the terminal command line on my Mac. The installation was finished automatically. The Command Line Tools for Xcode will also be automatically installed with this command.

After the installation is complete run two commands in your terminal to add Homebrew to your PATH. They are listet behind "next steps" in the terminal. You can copy & paste them.

To opting out the Homebrew analytics this command will prevent analytics from ever being sent:

`brew analytics off`

Check the installed version with:

`brew -v`

In my case: Homebrew 4.3.8

## Install Hugo with the open-source package manager Homebrew

This installation is very easy. You can find some documentation [here](https://gohugo.io/installation/macos/).

As I said before I used the package manager Homebrew for MacOS and installed the extended edition of Hugo with the following command in the terminal:

`brew install hugo`

That's all - Hugo is now installed.

## Create a new website with Hugo

On my system I created a new folder `MyHugoWebsites` in my `Documents` folder and switched to this folder in the command line.

My new website is called `sebastianzehner` and with the following command I created this new website:

`hugo new site sebastianzehner`

It's possible to create different config files like YAML or TOML. I used the standard configuration with the TOML config file.

I found a website to transform YAML to TOML [here](https://transform.tools/yaml-to-toml). Sometimes it helps if you read a tutorial and they use different configuration files. I'm using always TOML for my sites.

## Install a theme to Hugo

I decided to use the theme [PaperMod](https://themes.gohugo.io/themes/hugo-papermod/) as a fast, clean, responsive Hugo theme. You can find a documentation for the installation [here](https://github.com/adityatelange/hugo-PaperMod/wiki/Installation).

I used the following command in the terminal and switched to my website folder `sebastianzehner`:

`git clone https://github.com/adityatelange/hugo-PaperMod themes/PaperMod –depth=1`

Now the PaperMod theme will be downloaded and saved to the local website theme folder.

For my local Intranet I will use the [Smol](https://github.com/colorchestra/smol) theme. The installation process is the same. My Intranet is installed on a Raspberry Pi.

## Hugo website configuration

In the Visual Studio Code searchbar: _> install Shell Command: Install code command in PATH_

Then type in terminal: `code .` and Visual Studio Code will open with the installed website path.

Open `hugo.toml` and edit the configuration. I changed:

```
baseURL = 'localhost'
languageCode = 'en-us'
title = 'My new Hugo website'
theme = 'PaperMod'
```

After that type the following command in the terminal to start the local develop web server:

`hugo server`

The result will be this: `Web Server is available at //localhost:1313/`

Now my website ist running locally on my Mac Studio as a server service and updates all changes immediately. Press `Ctrl+C` to stop the server if needed or finished your work. **That was also a very easy installation!**

In my next blog post I will show you how to create content for your new website. How to add a menu, tags and categories, some special setting etc.

Kind regards Sebastian

{{< chat how-to-build-a-minimalistic-and-self-hosted-website-for-free >}}
