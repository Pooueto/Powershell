Add-Type -AssemblyName System.Windows.Forms

function Select-Folder {
    param( 
        [string]$CheminInitial = [Environment]::GetFolderPath('MyMusic')
    )

    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.InitialDirectory = $CheminInitial
    $FolderBrowser.Description = "Sélectionnez un dossier de téléchargement"
    $FolderBrowser.ShowDialog() | Out-Null
    return $FolderBrowser.SelectedPath
}

function Get-YouTubeVideo {
    param(
        [string]$UrlVideo,
        [string]$OutputDirectory
    )

    try {
        if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
            Write-Error "yt-dlp n'est pas installé. Installez-le avant d'exécuter ce script."
            return
        }

        Write-Host "🔄 Téléchargement de la vidéo en MP4..."
        yt-dlp -f "bestvideo+bestaudio[ext=mp4]" --merge-output-format mp4 --progress -o "$OutputDirectory\%(title)s.%(ext)s" "$UrlVideo" --cookies-from-browser chrome
    }
    catch {
        Write-Warning "❌ Erreur : $($_.Exception.Message)"
    }
}

function Get-YouTubeAudio {
    param(
        [string]$UrlVideo,
        [string]$OutputDirectory
    )

    try {
        if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
            Write-Error "yt-dlp n'est pas installé. Installez-le avant d'exécuter ce script."
            return
        }

        Write-Host "🔄 Téléchargement de l'audio en MP3..."
        yt-dlp --extract-audio --audio-format mp3 --progress -o "$OutputDirectory\%(title)s.%(ext)s" "$UrlVideo"
    }
    catch {
        Write-Warning "❌ Erreur : $($_.Exception.Message)"
    }
}

function Get-YouTubeThumbnail {
    param(
        [string]$UrlVideo,
        [string]$OutputDirectory
    )

    try {
        if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
            Write-Error "yt-dlp n'est pas installé. Installez-le avant d'exécuter ce script."
            return
        }

        Write-Host "🖼️ Téléchargement de la miniature..."
        # Obtenir les informations de la vidéo
        $videoInfo = yt-dlp --dump-json "$UrlVideo" | ConvertFrom-Json
        $videoTitle = $videoInfo.title
        
        # Nettoyer le titre pour créer un nom de fichier valide
        $validTitle = $videoTitle -replace '[\\/:*?"<>|]', '_'
        
        # Télécharger la miniature en utilisant la meilleure qualité disponible
        yt-dlp --write-thumbnail --skip-download --convert-thumbnails jpg -o "$OutputDirectory\$validTitle.%(ext)s" "$UrlVideo"
    }
    catch {
        Write-Warning "❌ Erreur lors du téléchargement de la miniature : $($_.Exception.Message)"
    }
}
function Get-YouTube {
    param(
        [string]$Url,
        [string]$Format,
        [string]$OutputDirectory,
        [bool]$DownloadThumbnail = $false
    )

    # Récupérer les informations détaillées de la vidéo
    $videoInfo = yt-dlp --dump-json "$Url" | ConvertFrom-Json
    
    # Vérifier si la vidéo nécessite une connexion
    if ($videoInfo.age_limit -gt 0) {
        Write-Host "⚠️ Cette vidéo est restreinte par âge. Vous devez utiliser un fichier de cookies."
        return
    }

    # Détection automatique intelligente du format
    if (-not ($Format -match "MP3|MP4")) {
        Write-Host "🔍 Détection automatique du format..."
        
        # Vérifier si c'est une musique basée sur la catégorie ou les tags
        $isMusic = $false
        
        # Vérifier la catégorie YouTube
        if ($videoInfo.categories -contains "Music" -or $videoInfo.categories -contains "Musique") {
            $isMusic = $true
        }
        
        # Vérifier les mots-clés dans le titre
        $musicKeywords = @("audio", "music", "musique", "song", "chanson", "official audio", "audio officiel", "lyric", "paroles")
        foreach ($keyword in $musicKeywords) {
            if ($videoInfo.title -match $keyword) {
                $isMusic = $true
                break
            }
        }
        
        # Vérifier les tags/keywords si disponibles
        if ($videoInfo.tags) {
            foreach ($tag in $videoInfo.tags) {
                if ($musicKeywords -contains $tag.ToLower()) {
                    $isMusic = $true
                    break
                }
            }
        }
        
        # Décision finale basée sur les critères
        if ($isMusic) {
            $Format = "MP3"
            Write-Host "📊 Contenu musical détecté. Téléchargement en MP3..."
        } else {
            # Fallback sur la durée si pas détecté comme musique
            $Format = if ($videoInfo.duration -lt 600) { "MP4" } else { "MP3" }
            Write-Host "📊 Format choisi basé sur la durée: $Format"
        }
    }

    # Télécharger la miniature si demandé
    if ($DownloadThumbnail) {
        Get-YouTubeThumbnail -UrlVideo $Url -OutputDirectory $OutputDirectory
    }

    if ($Format -eq "MP3") {
        Get-YouTubeAudio -UrlVideo $Url -OutputDirectory $OutputDirectory
    } elseif ($Format -eq "MP4") {
        Get-YouTubeVideo -UrlVideo $Url -OutputDirectory $OutputDirectory
    } else {
        Write-Warning "❌ Format de téléchargement invalide. Choisissez MP3 ou MP4."
    }
}

# 🌟 Interface améliorée
Write-Host "`n"
Write-Host "


██╗   ██╗████████╗████████╗ ██████╗       ██████╗ ██╗     
╚██╗ ██╔╝╚══██╔══╝╚══██╔══╝██╔═══██╗      ██╔══██╗██║     
 ╚████╔╝    ██║█████╗██║   ██║   ██║█████╗██║  ██║██║     
  ╚██╔╝     ██║╚════╝██║   ██║   ██║╚════╝██║  ██║██║     
   ██║      ██║      ██║   ╚██████╔╝      ██████╔╝███████╗
   ╚═╝      ╚═╝      ╚═╝    ╚═════╝       ╚═════╝ ╚══════╝
                                                          
                                                                                                      
"
            Write-Host "A YTDownloader, by Pooueto"
Write-Host "`n"

# Demander l'URL
$url = Read-Host "🔗 Entrez l'URL de la vidéo YouTube"

# Sélectionner le dossier de sortie
$outputDirectory = Select-Folder
if (-not $outputDirectory) { $outputDirectory = Join-Path $env:USERPROFILE "Downloads" } 

# Choisir le format ou activer la détection automatique
$format = Read-Host "🎶 Choisissez le format (MP3, MP4, ou AUTO)"

# Demander si l'utilisateur veut télécharger la miniature
$downloadThumbnailResponse = Read-Host "🖼️ Télécharger la miniature de la vidéo? (O/N)"
$downloadThumbnail = $downloadThumbnailResponse -match "^[OoYy]"

# Télécharger la vidéo/audio
Get-YouTube -Url $url -Format $format -OutputDirectory $outputDirectory -DownloadThumbnail $downloadThumbnail

Write-Host "✅ Téléchargement terminé !" -ForegroundColor Green