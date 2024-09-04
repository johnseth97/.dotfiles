## MacOS bootstraping 🥾

1. Install Apple's Command Line Tools, which are prerequisites for Git and Homebrew

```zsh
xcode-select --install
```


2. Clone repo into empty `~/.dotfiles` folder

`mkdir ~/.dotfiles && git clone https://github.com/johnseth97/.dotfiles .`


3. Create symlinks in the Home directory to the real files in the repo by running `.bin/sync.sh `. 


4. Install Homebrew, followed by the software listed in the Brewfile. 

*I intend to make this all part of one bootstrap script.*

```zsh
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Then pass in the Brewfile location...
brew bundle --file ~/.dotfiles/Brewfile
```
5. Now you're done!

### Features for those who fork the repo:

#### Sync:
Once installed, the alias `sync-dotfiles` should now work from anywhere in zsh. The command will alert you if changes have been made to your fork of the dotfiles. To sync your fork, preform the following:

```zsh
# Change directory to the dotifiles repo
cd ~/.dotfiles

# View the changes
git diff

# Add the changes
git add <filename>

# Or, remove the changes
git rm <filename>

# Commit the changes
git commit 

# Push to the fork
git push 

# Run sync as a sanity check
sync-dotfiles
```

*In the future, I plan to have these commands integrated into the sync-dotfiles script*


