+++
title = 'How to create content for your free Hugo website'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'Today I will show you how to create content with a Hugo website, how to add a menu, tags and categories and how to make some special settings.'
date = 2024-08-13T16:05:39-04:00
lastmod = 2024-08-13T16:05:39-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Website', 'Hugo', 'PaperMod']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/how-to-create-content-for-your-free-hugo-website.webp'
    alt = 'Featured image from How to create content for your free Hugo website'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

In the [first part of this series](/posts/how-to-build-a-minimalistic-and-self-hosted-website-for-free/) we installed our Hugo website with the PaperMod theme locally on our computer and configured everything so that we are now be able to add some content to our new website.

Today I'll show you how to create this content, how to add a menu, tags and categories and how to make some special settings.

## Create content for your new website

### File structure explained

The folder **content** is for website content like new sites or blogposts.

The folders **layouts** and **assets** are for overwrite the standard layout settings of the installed theme folder. For changes copy the file from the theme layouts or assets folder in the hugo layouts or assets folder and overwrite it there.

In our case this is the PaperMod theme and we don't make some changes at the `/themes/PaperMod` folder. Instead we copy the files to our layouts or assets folder and change the files there. This will automatically overwrite the standard layout settings if we deploy our website.

The folder **static** is for all static assets like images and our language files are stored in the **i18n** folder.

If we once started the hugo server we will also find a **public** folder with all the html and css files from our website to review in the browser.

### Create the first blogpost

To create a blogpost on the Hugo website go to the terminal and type:

```CMD
hugo new posts/first.md
```

It's important to be in the root website folder. In my case the folder **sebastianzehner** but later I renamed this folder to **blog**.

Back in Visual Studio Code open the new first.md file to edit. The file extension .md stands for Markdown.

### How to write and format

Use the Markdown Basic Syntax to write and format your sites and blogposts. Here are some links for more information:

- [Markdown Basic Syntax](https://www.markdownguide.org/basic-syntax/)
- [Content Management](https://gohugo.io/content-management/front-matter/)
- [PaperMod Features](https://github.com/adityatelange/hugo-PaperMod/wiki/Features)

This is one option to create a new post by using the command line.

Another option is directly in Visual Studio Code and create a new file e.g. second.md in the editor. It’s an empty file, so after creating copy or write some content to the new file and save.

Also Visual Studio Code is only one option more to use an editor. You can still use any other editor you like.

I started with Visual Studio Code but later switched to [Neovim](https://neovim.io/) and made some customizations for a nice and nerdy developer setup and I like it.

Maybe I will write a blogpost about Neovim later on.

## Create menus

Open the `hugo.toml` file and add some code to create the menu.

Here one example for a simple menu structure:

```TOML
[menus]
  [[menus.main]]
    name = 'Products'
    pageRef = '/products'
    weight = 10
  [[menus.main]]
    name = 'Hardware'
    pageRef = '/products/hardware'
    parent = 'Products'
    weight = 1
  [[menus.main]]
    name = 'Software'
    pageRef = '/products/software'
    parent = 'Products'
    weight = 2
  [[menus.main]]
    name = 'Services'
    pageRef = '/services'
    weight = 20
  [[menus.main]]
    name = 'Hugo'
    pre = '<i class="fa fa-heart"></i>'
    url = 'https://gohugo.io/'
    weight = 30
    [menus.main.params]
      rel = 'external'
```

I am using a multilingual menu structure. This is an example with my blog menu structure:

```TOML
defaultContentLanguage = 'en'
defaultContentLanguageInSubdir = true
[languages]
  [languages.en]
    languageCode = 'en-US'
    languageName = 'English'
    weight = 1
    [languages.en.menus]
        [[languages.en.menus.main]]
            name = 'Home'
            pageRef = '/'
            weight = 10
        [[languages.en.menus.main]]
            identifier = 'categories'
            name = 'Categories'
            pageRef = '/categories/'
            weight = 20
        [[languages.en.menus.main]]
            identifier = 'tags'
            name = 'Tags'
            pageRef = '/tags/'
            weight = 30
        [[languages.en.menus.main]]
            identifier = 'archives'
            name = 'Archives'
            pageRef = '/archives/'
            weight = 40
  [languages.de]
    languageCode = 'de-DE'
    languageName = 'Deutsch'
    weight = 2
    [languages.de.menus]
        [[languages.de.menus.main]]
            name = 'Start'
            pageRef = '/'
            weight = 10
        [[languages.de.menus.main]]
            identifier = 'categories'
            name = 'Kategorien'
            pageRef = '/categories/'
            weight = 20
        [[languages.de.menus.main]]
            identifier = 'tags'
            name = 'Tags'
            pageRef = '/tags/'
            weight = 30
        [[languages.de.menus.main]]
            identifier = 'archives'
            name = 'Archiv'
            pageRef = '/archives/'
            weight = 40
```

This is from the beginning. Later I added Spanish as well and changed some menus and settings.

## Add tags and categories

The tags and categories are set in the front matter of every post or site. Example:

```TOML
tags = ['Hugo', 'Website', 'PaperMod']
categories = ['Tech']
```

It's very important to use only one category for each site or blogpost. You can use more different tags instead. Usually I am using one category and three tags within a post or site.

If you also use the menus categories or tags like me this is useful to structure your blog and the visitors could find and sort the sites for their respective interessts.

## Some more special settings

If you want to show BreadCrumbs, ShareButtons, ReadingTime or PostNavLinks on the website. Add this to your hugo.toml file:

```TOML
[params]
    ShowBreadCrumbs = true
    ShowShareButtons = true
    ShowReadingTime = true
    ShowPostNavLinks = true
```

I am using the Home-Info Mode from the PaperMod theme and added this to my hugo.toml file. I also added some social media icons and links like Facebook and Youtube for example:

```TOML
[params.homeInfoParams]
    title = 'Hello my friend...'
    content = 'Welcome to my blog. Here you will find a lot of cool information about a lot of cool stuff.'
    [[params.socialIcons]]
        name = 'facebook'
        url = 'https://www.facebook.com/yourfacebook'
    [[params.socialIcons]]
        name = 'youtube'
        url = 'https://www.youtube.com/@youryoutube'
```

Now we did some basic configuration and added some content to our new website. Next step is to deploy and publish our new website to the internet.

In the next blogpost I will show you how I did this with GitHub and Netlify for free. Stay tuned and see you soon.

Regards Sebastian

{{< chat how-to-create-content-for-your-free-hugo-website >}}
