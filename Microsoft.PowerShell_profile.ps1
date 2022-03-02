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
