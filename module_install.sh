#!/bin/bash

pip install black neovim pyright
pip list

npm install -g neovim dockerfile-language-server-nodejs vscode-langservers-extracted yaml-language-server
npm ls -g

sudo pacman -S fd
yay -S stylua-git lua-language-server-git omnisharp-roslyn nerd-fonts-jetbrains-mono
