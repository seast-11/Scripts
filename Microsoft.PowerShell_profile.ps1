[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Set-PoshPrompt -Theme powerlevel10k_rainbow

Import-Module -Name Terminal-Icons
Import-Module -Name posh-git

# Env
$env:GIT_SSH = "C:\Windows\system32\OpenSSH\ssh.exe"

# PSReadLine
Set-PSReadLineOption -EditMode Vi 
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -ShowToolTips
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key 'Ctrl+Spacebar' -Function AcceptSuggestion 
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar

# Alias - CLI
Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'
Set-Alias tail 'C:\Program Files\Git\usr\bin\tail.exe'
Set-Alias grep 'C:\Program Files\Git\usr\bin\grep.exe'
function ll {ls -Force}

# Alias - Git
function g {git $arg[0]}
function gst {git status}
function gd {git diff}
function glod {git checkout develop}
function glo {git log --oneline --decorate --color}
function gb {git branch}
function gsub {git submodule update --init}
function gsubr {git submodule foreach git submodule update --init}
function gcob {git checkout -b $args[0]}
function gcmsg {git commit -m $args[0]}
function gaa {git add .}
function gbd {git branch -d $args[0]}

# Project Alias
function codes {set-location "C:\src\work"}

# Utilities
function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
  }
