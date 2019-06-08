

# Protect access to this behind exported functions
$Script:InitialCache = @(
    @{Name = "containerd"; Extension = "zip"; Version = "dev"; Url = "https://acsenginedev.blob.core.windows.net/cri-containerd/windows-cri-containerd-05072019.zip"},
    @{Name = "sdnbridge"; Extension = "zip"; Version = "dev"; Url = "https://acsenginedev.blob.core.windows.net/cri-containerd/windows-cni-containerd-05072019.zip"}
    
)

$Script:LocalCacheDir = [Io.path]::Combine($ENV:ProgramData,"aks","cache")

function DownloadFileOverHttp
{
    Param(
        [Parameter(Mandatory=$true)][string]
        $Url,
        [Parameter(Mandatory=$true)][string]
        $DestinationPath
    )
    $secureProtocols = @()
    $insecureProtocols = @([System.Net.SecurityProtocolType]::SystemDefault, [System.Net.SecurityProtocolType]::Ssl3)

    foreach ($protocol in [System.Enum]::GetValues([System.Net.SecurityProtocolType]))
    {
        if ($insecureProtocols -notcontains $protocol)
        {
            $secureProtocols += $protocol
        }
    }
    [System.Net.ServicePointManager]::SecurityProtocol = $secureProtocols

    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest $Url -UseBasicParsing -OutFile $DestinationPath -Verbose
    $ProgressPreference = $oldProgressPreference
}

function Build-Cache
{
    if (-Not (Test-Path $LocalCacheDir) ) {
        New-Item -Type Directory -Path $Script:LocalCacheDir
    }

    workflow RunDownloads {
        param(
            $InitialCache,
            $LocalCacheDir
        )
        ForEach -Parallel ($cacheItem in $InitialCache) {
            $destinationDir = [Io.path]::Combine($LocalCacheDir, $cacheItem.Name, $cacheItem.Version)
            $destinationFilename = "$($cacheItem.Name).$($cacheItem.Extension)"
            if (-Not (Test-Path $destinationDir)) {
                New-Item -Type Directory -Path $destinationDir
            }
            $destinationFullName = [Io.path]::Combine($destinationDir,$destinationFilename)
            DownloadFileOverHttp -Url $cacheItem.Url -DestinationPath $destinationFullName
        }
    }

    RunDownloads -InitialCache $Script:InitialCache -LocalCacheDir $Script:LocalCacheDir
}

function Get-CachedFile
{
    param(
        $Name,
        $Version
    )
}

function Add-CachedFile
{
    param(
        $Name,
        $Version,
        $Url
    )
}

Export-ModuleMember Build-Cache
Export-ModuleMember Get-CachedFile
Export-ModuleMember Add-CachedFile