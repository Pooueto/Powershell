function Get-YouTubeVideo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UrlVideo,
        [string]$OutputDirectory = ""
    )

    try {
        yt-dlp -f bestvideo+bestaudio[ext=mp4] --output "$OutputDirectory\%(title)s.%(ext)s" "$UrlVideo"
    }
    catch {
        Write-Warning "Erreur lors du téléchargement : $($_.Exception.Message)"
    }
}

function Get-YouTubeAudio {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UrlVideo,
        [string]$OutputDirectory = ""
    )

    try {
        yt-dlp --extract-audio --audio-format mp3 -o "$OutputDirectory\%(title)s.%(ext)s" "$UrlVideo"
    }
    catch {
        Write-Warning "Erreur lors du téléchargement : $($_.Exception.Message)"
    }
}

function Get-YouTube {
    param(
        [string]$Url,
        [string]$Format
    )

    if ($Format -eq "MP3") {
        Get-YouTubeAudio -UrlVideo $Url -OutputDirectory $OutputDirectory
    } elseif ($Format -eq "MP4") {
        Get-YouTubeVideo -UrlVideo $Url -OutputDirectory $OutputDirectory
    } else {
        Write-Warning "Format de téléchargement invalide."
    }
}

# Utilisation du script modifié
$url = Read-Host "Entrez l'URL de la vidéo YouTube"
$outputDirectory = Join-Path $env:USERPROFILE "Downloads"
$format = Read-Host "Choisissez le format de téléchargement (MP3 ou MP4)"

Get-YouTube -Url $url -Format $format -OutputDirectory $outputDirectory
