param(
    [string]$repertoire = (Get-Location).Path,  # Utilise le chemin courant du terminal par défaut
    [switch]$random = $false,
    [switch]$repeat = $false,
    [int]$volume = 100
)

# Fonction pour vérifier si VLC est installé
function Test-VLCInstalled {
    $vlcPath = "C:\Program Files\VideoLAN\VLC\vlc.exe"
    $vlcPath32 = "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
    
    if (Test-Path $vlcPath) {
        return $vlcPath
    } elseif (Test-Path $vlcPath32) {
        return $vlcPath32
    } else {
        return $false
    }
}

# Fonction pour afficher des messages colorés
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Afficher le banner ASCII
Clear-Host
Write-Host "`n" -NoNewline
Write-ColorMessage "
            ██████╗ ███████╗████████╗████████╗███████╗██████╗     ██╗   ██╗██╗      ██████╗
            ██╔══██╗██╔════╝╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗    ██║   ██║██║     ██╔════╝
            ██████╔╝█████╗     ██║      ██║   █████╗  ██████╔╝    ██║   ██║██║     ██║     
            ██╔══██╗██╔══╝     ██║      ██║   ██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██║     ██║     
            ██████╔╝███████╗   ██║      ██║   ███████╗██║  ██║     ╚████╔╝ ███████╗╚██████╗
            ╚═════╝ ╚══════╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚══════╝ ╚═════╝" 
Write-ColorMessage "                  A VLC interpreter for windows terminal, by Pooueto" 
Write-Host "`n"

# Vérifier si VLC est installé
$vlcExePath = Test-VLCInstalled
if (-not $vlcExePath) {
    Write-ColorMessage "VLC n'est pas installé ou n'a pas été trouvé aux emplacements standards." -ForegroundColor Red
    Write-ColorMessage "Veuillez installer VLC ou spécifier le chemin correct dans le script." -ForegroundColor Red
    exit 1
}

# Extensions vidéo courantes
$extensionsVideo = @(".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm", ".m4v", ".mpg", ".mpeg", ".3gp", ".ts")

# Extensions audio courantes
$extensionsAudio = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".m4a", ".opus")

# Extensions supportées (video + audio)
$extensionsSupported = $extensionsVideo + $extensionsAudio

Write-ColorMessage "Dossier actuel : $repertoire" -ForegroundColor Green
Write-Host ""

# Récupérer tous les fichiers multimédia
$fichiersMultimedia = Get-ChildItem $repertoire | Where-Object { 
    $_.Extension -in $extensionsSupported 
} | Sort-Object Extension, Name

# Créer des tableaux séparés pour vidéo et audio
$fichiersVideo = $fichiersMultimedia | Where-Object { $_.Extension -in $extensionsVideo }
$fichiersAudio = $fichiersMultimedia | Where-Object { $_.Extension -in $extensionsAudio }

# Vérifier si des fichiers multimédia ont été trouvés
if ($fichiersMultimedia.Count -gt 0) {
    # Afficher le nombre de fichiers trouvés par type
    Write-ColorMessage "Fichiers trouvés :" -ForegroundColor Green
    if ($fichiersVideo.Count -gt 0) {
        Write-ColorMessage "  - Vidéos : $($fichiersVideo.Count)" -ForegroundColor Yellow
    }
    if ($fichiersAudio.Count -gt 0) {
        Write-ColorMessage "  - Audio : $($fichiersAudio.Count)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Afficher les fichiers avec leurs indices
    Write-ColorMessage "Liste des fichiers multimédia :" -ForegroundColor Green
    for ($i=0; $i -lt $fichiersMultimedia.Count; $i++) {
        $fichier = $fichiersMultimedia[$i]
        $couleur = "White"
        $type = ""
        
        # Afficher un préfixe et utiliser une couleur différente selon le type de fichier
        if ($fichier.Extension -in $extensionsVideo) {
            $couleur = "Cyan"
            $type = "[Video] "
        } else {
            $couleur = "Magenta"
            $type = "[Audio] "
        }
        
        Write-ColorMessage "$($i+1) - $type$($fichier.Name)" -ForegroundColor $couleur
    }
    
    Write-Host ""
    Write-ColorMessage "Options disponibles :" -ForegroundColor Yellow
    Write-ColorMessage "- Entrez un numéro (1-$($fichiersMultimedia.Count)) pour lire un fichier spécifique" -ForegroundColor White
    Write-ColorMessage "- Entrez 'A' pour lire tous les fichiers en séquence" -ForegroundColor White
    Write-ColorMessage "- Entrez 'V' pour lire uniquement les fichiers vidéo" -ForegroundColor White
    Write-ColorMessage "- Entrez 'M' pour lire uniquement les fichiers audio" -ForegroundColor White
    Write-ColorMessage "- Entrez 'R' pour lire tous les fichiers en mode aléatoire" -ForegroundColor White
    Write-ColorMessage "- Entrez 'Q' pour quitter" -ForegroundColor White
    Write-Host ""
    
    # Récupérer le choix de l'utilisateur
    $choix = Read-Host "Entrez votre choix"
    
    # Préparer les arguments VLC de base
    $vlcArgs = @()
    
    # Ajouter des options en fonction des paramètres
    if ($repeat) {
        $vlcArgs += "--loop"
    }
    if ($volume -ne 100) {
        $vlcArgs += "--volume=$volume"
    }
    
    switch ($choix.ToUpper()) {
        "A" {
            # Créer une playlist temporaire pour tous les fichiers
            $playlistPath = [System.IO.Path]::Combine($env:TEMP, "vlc_playlist_$(Get-Random).m3u")
            $fichiersMultimedia | ForEach-Object { $_.FullName } | Out-File -FilePath $playlistPath -Encoding utf8
            
            # Lancer VLC avec la playlist
            $vlcArgs += "`"$playlistPath`""
            Start-Process $vlcExePath -ArgumentList $vlcArgs
            
            Write-ColorMessage "Lecture de tous les fichiers lancée..." -ForegroundColor Green
        }
        "V" {
            if ($fichiersVideo.Count -gt 0) {
                # Créer une playlist temporaire pour les vidéos uniquement
                $playlistPath = [System.IO.Path]::Combine($env:TEMP, "vlc_playlist_$(Get-Random).m3u")
                $fichiersVideo | ForEach-Object { $_.FullName } | Out-File -FilePath $playlistPath -Encoding utf8
                
                # Lancer VLC avec la playlist
                $vlcArgs += "`"$playlistPath`""
                Start-Process $vlcExePath -ArgumentList $vlcArgs
                
                Write-ColorMessage "Lecture des fichiers vidéo lancée..." -ForegroundColor Green
            } else {
                Write-ColorMessage "Aucun fichier vidéo trouvé." -ForegroundColor Red
            }
        }
        "M" {
            if ($fichiersAudio.Count -gt 0) {
                # Créer une playlist temporaire pour les audios uniquement
                $playlistPath = [System.IO.Path]::Combine($env:TEMP, "vlc_playlist_$(Get-Random).m3u")
                $fichiersAudio | ForEach-Object { $_.FullName } | Out-File -FilePath $playlistPath -Encoding utf8
                
                # Lancer VLC avec la playlist
                $vlcArgs += "`"$playlistPath`""
                Start-Process $vlcExePath -ArgumentList $vlcArgs
                
                Write-ColorMessage "Lecture des fichiers audio lancée..." -ForegroundColor Green
            } else {
                Write-ColorMessage "Aucun fichier audio trouvé." -ForegroundColor Red
            }
        }
        "R" {
            # Créer une playlist temporaire avec ordre aléatoire
            $playlistPath = [System.IO.Path]::Combine($env:TEMP, "vlc_playlist_$(Get-Random).m3u")
            $fichiersMultimedia | Get-Random -Count $fichiersMultimedia.Count | ForEach-Object { $_.FullName } | Out-File -FilePath $playlistPath -Encoding utf8
            
            # Lancer VLC avec la playlist
            $vlcArgs += "--random"
            $vlcArgs += "`"$playlistPath`""
            Start-Process $vlcExePath -ArgumentList $vlcArgs
            
            Write-ColorMessage "Lecture aléatoire de tous les fichiers lancée..." -ForegroundColor Green
        }
        "Q" {
            Write-ColorMessage "Au revoir !" -ForegroundColor Cyan
            exit 0
        }
        default {
            # Vérifier si le choix est un numéro valide - CODE CORRIGÉ
            $choixNum = $choix.Trim() -as [int]  # Supprimer les espaces et convertir en entier
            
            if ($null -ne $choixNum -and $choixNum -gt 0 -and $choixNum -le $fichiersMultimedia.Count) {
                $fichierSelectionne = $fichiersMultimedia[$choixNum - 1]
                $estVideo = $fichierSelectionne.Extension -in $extensionsVideo
                
                # Menu des options pour ce fichier
                Write-Host ""
                Write-ColorMessage "Options de lecture pour $($fichierSelectionne.Name) :" -ForegroundColor Yellow
                Write-ColorMessage "1 - Lecture normale" -ForegroundColor White
                
                if ($estVideo) {
                    Write-ColorMessage "2 - Lecture en plein écran" -ForegroundColor White
                }
                
                Write-ColorMessage "3 - Lecture en boucle" -ForegroundColor White
                
                if ($estVideo) {
                    Write-ColorMessage "4 - Lecture en plein écran et en boucle" -ForegroundColor White
                }
                
                Write-ColorMessage "R - Retour" -ForegroundColor White
                Write-Host ""
                
                $optionLecture = Read-Host "Choisissez une option de lecture"
                
                switch ($optionLecture.ToUpper()) {
                    "1" {
                        Start-Process $vlcExePath -ArgumentList "`"$($fichierSelectionne.FullName)`""
                    }
                    "2" {
                        if ($estVideo) {
                            Start-Process $vlcExePath -ArgumentList "--fullscreen `"$($fichierSelectionne.FullName)`""
                        } else {
                            Write-ColorMessage "Option invalide pour un fichier audio. Lecture normale lancée." -ForegroundColor Yellow
                            Start-Process $vlcExePath -ArgumentList "`"$($fichierSelectionne.FullName)`""
                        }
                    }
                    "3" {
                        Start-Process $vlcExePath -ArgumentList "--loop `"$($fichierSelectionne.FullName)`""
                    }
                    "4" {
                        if ($estVideo) {
                            Start-Process $vlcExePath -ArgumentList "--fullscreen --loop `"$($fichierSelectionne.FullName)`""
                        } else {
                            Write-ColorMessage "Option invalide pour un fichier audio. Lecture en boucle lancée." -ForegroundColor Yellow
                            Start-Process $vlcExePath -ArgumentList "--loop `"$($fichierSelectionne.FullName)`""
                        }
                    }
                    "R" {
                        # Relancer le script
                        & $MyInvocation.MyCommand.Path -repertoire $repertoire
                        exit 0
                    }
                    default {
                        Write-ColorMessage "Option invalide. Lecture normale lancée." -ForegroundColor Yellow
                        Start-Process $vlcExePath -ArgumentList "`"$($fichierSelectionne.FullName)`""
                    }
                }
                
                Write-ColorMessage "Lecture de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
            } else {
                Write-ColorMessage "Choix invalide: '$choix'. Veuillez entrer un numéro entre 1 et $($fichiersMultimedia.Count)." -ForegroundColor Red
            }
        }
    }
} else {
    Write-ColorMessage "Aucun fichier multimédia trouvé dans le répertoire $repertoire" -ForegroundColor Red
    Write-ColorMessage "Extensions vidéo recherchées : $($extensionsVideo -join ', ')" -ForegroundColor Yellow
    Write-ColorMessage "Extensions audio recherchées : $($extensionsAudio -join ', ')" -ForegroundColor Yellow
}