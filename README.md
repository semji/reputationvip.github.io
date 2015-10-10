# ReputationVIP R&D blog

## Description

This repository contains the source code and articles which run [http://reputationvip.io](http://reputationvip.io).
This blog is powered by Jekyll and hosted on Github pages. Our current theme is based on the work of
[Michael Rose](https://mademistakes.com/) and its [Minimal Mistakes theme](https://github.com/mmistakes/minimal-mistakes).

## Development

In order to ease development and article draft writing locally,
we provide a basic Vagrantfile to get you started in just a few commands:

```
# on your host
git clone https://github.com/ReputationVIP/reputationvip.github.io.git
cd reputationvip.github.io
vagrant up
vagrant ssh

# inside your VM
cd ~/reputationvip.github.io
npm install
bundle exec jekyll serve --host 0.0.0.0
```

Then, you can access the blog with your browser at: [http://localhost:4000](http://localhost:4000).

If you need some help to customize our blog or to post new articles, get a quick look to
[theme author instructions](http://mmistakes.github.io/minimal-mistakes/theme-setup).

### Beloved Windows users

First of all, you need to start your Vagrant with admin privileges for Virtualbox to authorize symlinks inside your VM.

You could think that's enough... Not at all! Windows seems to have problems handling long file paths and NPM nested
folders exceed quite often that limit. One option is to symlink your `node_modules` folder. Inside your VM, execute the
following commands:

```
cd ~/reputationvip.github.io
mkdir -p ~/node_modules
ln -s ~/node_modules node_modules
```
