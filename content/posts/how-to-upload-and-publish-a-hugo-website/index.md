+++
title = 'How to upload and publish a Hugo website'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'In the second part of this series we created some content for your free Hugo website and today we want to upload and publish this content to the internet for free.'
date = 2024-12-06T15:00:00-04:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2024-12-06T15:00:00-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Hugo', 'Website', 'PaperMod']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/how-to-upload-and-publish-a-hugo-website.webp'
    alt = 'Featured image from How to upload and publish a Hugo website'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

In the [second part of this series](/posts/how-to-create-content-for-your-free-hugo-website/) we created some content for your free Hugo website and today we want to upload and publish this content to the internet for free.

## Prepare Git and create a GitHub repository

First we have to upload all the files to a GitHub repository. Git must be installed on your computer. Make sure that you are in the root directory of your website on your local machine using the terminal and then use the following command:

```
git init
```

Now a GitHub repository is initialized. Next create a `.gitmodules` file in the same folder.

```
touch .gitmodules
```

The PaperMod theme should be a submodule at the GitHub repository, so write to the `.gitmodules` file this:

```
[submodule "themes/PaperMod"]
	path = themes/PaperMod
	url = "https://github.com/adityatelange/hugo-PaperMod.git"
```

### Create a free account on GitHub

If you have no free GitHub account yet then register now and create your repository for your website. [Link to GitHub.](https://github.com)

### Create a token for secure login

A token is needed for secure login with Git to GitHub. Generate a new token on GitHub.
[Link to GitHub settings.](https://github.com/settings/tokens)

> Note: yourname website
> Expiration: 90 days
> [x] public_repo

Then paste these commands into terminal:

```
echo "# yourname" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/yourname/blog.git
git push -u origin main
```

Type username and token if asked. Now the files would be uploaded to the GitHub repository.

### How to save and update the token after 90 days

Save this token in the Mac Keychain: Click on the Spotlight icon (magnifying glass) on the right side of the menu bar.

Type Keychain Access then press the Enter key to launch the app:

- In Keychain Access, search for github.com.
- Find the internet password entry for github.com.
- Edit or delete the entry accordingly.
- You are done!

> Note: Now Git is able to upload files to GitHub without any errors!

After 90 days generate a new token on github.com and exchange the old token in the Keychain with the new generated token!

Maybe delete at first the old token from the Keychain and then make a push command with username and password/token. After this command was successful create a new entry in the Mac Keychain or restore the old one and replace the old token with the new token.

> Note: This works in a similar way with other operating systems.

## Where to deploy the website?

Next create a free account at Netlify: [https://www.netlify.com/](https://www.netlify.com/)

- New site from Git and connect with GitHub.
- Chose the repository from the website.

Deploy as yourname on yourname team from main branch using hugo command and publishing to public. Deploy yourname to Netlify.

There was a problem with the gitsubmodule and the following command resolved this issue. Use local website root directory in terminal.

```
git submodule update --remote –init
```

The link now has another number behind `tree` and it worked for me.

Deploy again with Netlify and now it should work. **The website is online!**

👉 https://sebastianzehner.netlify.app

## Register and connect a domain to the website

I am using [Hostinger](https://bit.ly/3W9oyZG) for Domain registration and renewal. The first two years, Hostinger offers a special price for only 4.99 USD per year.

After two years the regular price is 15.99 USD per year for one **.com** domain. I have only one domain left and want to use it for my new website.

We are able to [pay for this domain in crypto](/posts/how-i-paid-for-my-domain-with-cryptocurrency/) for one, two or three years. I like that and this are the only costs for our new website because the hosting with Netlifly and GitHub is free of charge. The software Hugo and the theme PaperMod are Open Source and also for free.

On the website Netlify in the backend we set up a custom domain. Add a custom domain to your site and press verify and than add domain. In domain management I received some DNS settings.

```
Point A record to xx.x.xx.x for yourdomain.com
```

I changed the IP address for my domain at Hostinger in the DNS records for the type A pointed to xx.x.xx.x and saved these settings.

After a few minutes later Netlify registered this changes and now my website is reachable under http://sebastianzehner.com and http://www.sebastianzehner.com redirects to http://sebastianzehner.com. But this is not secure and we have to set up an encryption.

## Enable the TLS certificate: Let’s Encrypt

At the domain management in the backend from Netlify I verified the DNS configuration for SSL/TLS certificate. Just one click on the button and DNS verification was successful ✅

That’s it. So easy. Now the connection is secure and the website reachable with my domain [https://sebastianzehner.com](https://sebastianzehner.com)

In the meantime domain management at Netlify says:

- Your site has HTTPS enabled ✅

Last step to configure this new domain in the `hugo.toml` config file. Insert or rename this line:

```
baseURL = 'https://yourdomain.com'
```

Upload these changes to the internet with a `git push` and we are done.

Our new secure and minimalistic Hugo website with the PaperMod theme is online and visitors are welcome to read my cool stuff 😎

Thank you for reading my blogpost and have a nice day. I will go forward in the next episode of this series with one of these topics: shortcodes, search function or analytics with GoatCounter.

Regards Sebastian

## Video: Getting started with Hugo

This great video helps for the most points. The submodule was tricky and cost me a lot of time but now its all fine and working.

{{< youtube hjD9jTi_DQ4 >}}

## Other useful sites and links

- Transform yaml to toml [Link](https://transform.tools/yaml-to-toml)
- Markdown Cheat Sheet [Link](https://www.markdownguide.org/cheat-sheet/)
- Multilingual Menus [Link](https://gohugo.io/content-management/multilingual/#menus)
- Front matter [Link](https://gohugo.io/content-management/front-matter/)
- PaperMod Features [Link](https://github.com/adityatelange/hugo-PaperMod/wiki/Features)

{{< chat how-to-upload-and-publish-a-hugo-website >}}
