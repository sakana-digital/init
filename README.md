# init

## Usage

```sh
# 初回
git clone https://github.com/sakana-digital/init.git ~/Documents/GitHub.nosync/init
cd ~/Documents/GitHub.nosync/init
./bootstrap.sh

# 反映
sudo darwin-rebuild switch --flake "path:$HOME/Documents/GitHub.nosync/init#default"

# アップデート
nix flake update && sudo darwin-rebuild switch --flake "path:$HOME/Documents/Github.nosync/init#default"
```

## 管理対象

- Homebrew
  - Visual Studio Code

- dotfiles
  - `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`: いずれも dotfiles/AGENTS.md への symlink
  - `~/.config/karabiner/karabiner.json`
  - `~/.config/zed/settings.json`
  
- macOS の環境設定
