# dotfiles
My dotfiles handled with GNU stow

# setup

The current `setup.sh` is a shell script that I made for my Ubuntu on WSL 2.0

# arch ml4w

If you installed the ArchLinux with the ml4w dotfiles, you should not clone this in your `dotfiles` but in a custom folder of your choice, then you can stow whatever you want to override from the ml4w dotfiles.

In my case, I only stow `tmux` and `nvim`

```
cd ~/my_custom_dotfiles
stow tmux nvim
```

## packages to install

Here is the list of packages I'm using on a day to day basis

* Cursor AI
* Discord
* Slack
* NWG Displays (display settings GUI)
* Nvidia (official display drivers)
* Chrome (official Google Chrome)
  
```
yay -S cursor-bin discord slack-desktop nwg-displays nvidia google-chrome
```
