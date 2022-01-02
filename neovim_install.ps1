#powershell.exe -noprofile -executionpolicy bypass -file .\neovim_install.ps1

function Add-ToUserEnvPath {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $dir
    )

    $dir = (Resolve-Path $dir)

    $path = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
    if (!($path.Contains($dir))) {
        # backup the current value
        "PATH=$path" | Set-Content -Path "$env:USERPROFILE/path.env"
        # append dir to path
        [Environment]::SetEnvironmentVariable("PATH", $path + ";$dir", [EnvironmentVariableTarget]::User)
        Write-Host "Added $dir to PATH"
        return
    }
    Write-Warning "$dir is already in PATH"
}

function Install-NerdFont {
        param (
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $nerdFont,
            
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $name
        )
        
        $FONTS = 0x14
        $objShell = New-Object -ComObject Shell.Application
        $objFolder = $objShell.Namespace($FONTS)
        $objFolder.CopyHere("C:\Tools\Temp\unzip\$name\$nerdfont")
}

function DownloadUnzip-Item {
        param (
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $url,
          
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $name
        )
        
        $DownloadZipFile = "C:\Tools\Temp\zip\" + $(Split-Path -Path $Url -Leaf)
        $ExtractPath = "C:\Tools\Temp\unzip\$name"
        Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile
        Expand-Archive -Path $DownloadZipFile -DestinationPath $ExtractPath -Force
    }

#Create working dirs
New-Item -Path 'C:\Tools\Temp\zip' -ItemType Directory -force
New-Item -Path 'C:\Tools\Temp\unzip' -ItemType Directory -force

#Download and unzip everything
DownloadUnzip-Item "https://github.com/sumneko/lua-language-server/releases/download/2.5.6/lua-language-server-2.5.6-win32-x64.zip" "LuaServer"
DownloadUnzip-Item "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip" "JetBrainsMonoFonts"
DownloadUnzip-Item "https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.38.0/omnisharp-win-x64.zip" "OmniSharp"
DownloadUnzip-Item "https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-x86_64-pc-windows-gnu.zip" "RipGrep"
DownloadUnzip-Item "https://github.com/neovim/neovim/releases/download/v0.6.0/nvim-win64.zip" "Neovim"
DownloadUnzip-Item "https://ziglang.org/builds/zig-windows-x86_64-0.9.0-dev.1815+20e19e75f.zip" "Zig"
DownloadUnzip-Item "https://github.com/sharkdp/fd/releases/download/v8.3.0/fd-v8.3.0-x86_64-pc-windows-gnu.zip" "Fd"
DownloadUnzip-Item "https://github.com/JohnnyMorganz/StyLua/releases/download/v0.11.2/stylua-0.11.2-win64.zip" "StyLua"
DownloadUnzip-Item "https://github.com/clangd/clangd/releases/download/13.0.0/clangd-windows-13.0.0.zip" "ClangD"

#Copy specific files/folders we need
Copy-Item 'C:\Tools\Temp\unzip\LuaServer' -Recurse 'C:\Tools\Sumneko_Lua' -force
Write-Output "Installed Sumneko_Lua"

Copy-Item 'C:\Tools\Temp\unzip\OmniSharp' -Recurse 'C:\Tools\OmniSharp' -force
Write-Output "Installed Omnisharp"

Copy-Item 'C:\Tools\Temp\unzip\StyLua\stylua.exe' 'C:\Tools\bin\stylua.exe' -force
Write-Output "Installed StyLua"

Copy-Item 'C:\Tools\Temp\unzip\RipGrep\ripgrep-13.0.0-x86_64-pc-windows-gnu\rg.exe' 'C:\Tools\bin\rg.exe' -force
Write-Output "Installed RipGrep"

Copy-Item 'C:\Tools\Temp\unzip\ClangD\clangd_13.0.0\bin\clangd.exe' 'C:\Tools\bin\clangd.exe' -force
Write-Output "Installed ClangD"

Copy-Item 'C:\Tools\Temp\unzip\Fd\fd-v8.3.0-x86_64-pc-windows-gnu\fd.exe' 'C:\Tools\bin\fd.exe' -force
Write-Output "Installed Fd"

Copy-Item 'C:\Tools\Temp\unzip\Neovim\Neovim' -Recurse 'C:\Tools' -force
Write-Output "Installed NeoVim"

Copy-Item 'C:\Tools\Temp\unzip\Zig\zig-windows-x86_64-0.9.0-dev.1815+20e19e75f\*' -Recurse 'C:\Tools\bin' -Force
Write-Output "Installed Zig"

#NERDS!
Install-NerdFont "JetBrains Mono Regular Nerd Font Complete Mono Windows Compatible.ttf" "JetBrainsMonoFonts"
Write-Output "Installed Nerd Fonts"

#Packer plugin manager 
git clone https://github.com/wbthomason/packer.nvim "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"
Write-Output "Installed Packer plugin manager"

#Add paths for cmd line usage
Add-ToUserEnvPath "C:\Tools\bin"
Add-ToUserEnvPath "C:\Tools\Neovim\bin"
Write-Output "Updated PATH environment variables"

#Cleanup
Remove-Item 'C:\Tools\Temp' -Recurse
Write-Output "Cleaning up..."
