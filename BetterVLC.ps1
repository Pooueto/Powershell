param(
    [string]$repertoire = (Get-Location).Path,  # Utilise le chemin courant du terminal par défaut
    [switch]$random = $false,
    [switch]$repeat = $false,
    [int]$volume = 100,
    [int]$elementsParPage = 10  # Nouveau paramètre pour la pagination
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

# Fonction pour naviguer dans les répertoires
function Navigate-Directories {
    param(
        [string]$startPath
    )
    
    $currentPath = $startPath
    
    while ($true) {
        Clear-Host
        Write-ColorMessage "`n" -NoNewline
        Write-ColorMessage "
            ██████╗ ███████╗████████╗████████╗███████╗██████╗     ██╗   ██╗██╗      ██████╗
            ██╔══██╗██╔════╝╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗    ██║   ██║██║     ██╔════╝
            ██████╔╝█████╗     ██║      ██║   █████╗  ██████╔╝    ██║   ██║██║     ██║     
            ██╔══██╗██╔══╝     ██║      ██║   ██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██║     ██║     
            ██████╔╝███████╗   ██║      ██║   ███████╗██║  ██║     ╚████╔╝ ███████╗╚██████╗
            ╚═════╝ ╚══════╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚══════╝ ╚═════╝" 
        Write-ColorMessage "                  A VLC interpreter for windows terminal, by Pooueto" 
        Write-ColorMessage "`n### MODE NAVIGATION ###`n" -ForegroundColor Green
        
        # Afficher le chemin actuel
        Write-ColorMessage "Répertoire actuel : $currentPath" -ForegroundColor Yellow
        Write-Host ""
        
        try {
            # Obtenir les dossiers
            $directories = Get-ChildItem -Path $currentPath -Directory -ErrorAction Stop | Sort-Object Name
            
            # Afficher option retour parent (sauf pour la racine)
            if ($currentPath -ne (Split-Path -Path $currentPath -Qualifier)) {
                Write-ColorMessage "0 - [..] Dossier parent" -ForegroundColor DarkYellow
            }
            
            # Afficher les dossiers
            for ($i=0; $i -lt $directories.Count; $i++) {
                Write-ColorMessage "$($i+1) - [$($directories[$i].Name)]" -ForegroundColor Cyan
            }
            
            Write-Host ""
            Write-ColorMessage "S - Sélectionner ce répertoire" -ForegroundColor Green
            Write-ColorMessage "Q - Quitter" -ForegroundColor Red
            Write-Host ""
            
            $choice = Read-Host "Votre choix"
            
            switch ($choice.ToUpper()) {
                "S" {
                    return $currentPath
                }
                "Q" {
                    exit
                }
                "0" {
                    if ($currentPath -ne (Split-Path -Path $currentPath -Qualifier)) {
                        $currentPath = Split-Path -Path $currentPath -Parent
                    }
                }
                default {
                    $choiceNum = $choice -as [int]
                    if ($null -ne $choiceNum -and $choiceNum -gt 0 -and $choiceNum -le $directories.Count) {
                        $currentPath = $directories[$choiceNum-1].FullName
                    } else {
                        Write-ColorMessage "Choix invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    }
                }
            }
        } catch {
            Write-ColorMessage "Erreur lors de l'accès au répertoire: $_" -ForegroundColor Red
            Write-ColorMessage "Appuyez sur une touche pour revenir au répertoire parent..." -ForegroundColor Red
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            
            # Revenir au répertoire parent en cas d'erreur
            if ($currentPath -ne (Split-Path -Path $currentPath -Qualifier)) {
                $currentPath = Split-Path -Path $currentPath -Parent
            }
        }
    }
}

# Fonction pour obtenir les informations d'un fichier multimédia
# Fonction pour obtenir les informations d'un fichier multimédia avec MediaInfo
function Get-MediaInfo {
    param(
        [System.IO.FileInfo]$mediaFile
    )
    
    $info = [PSCustomObject]@{
        Name = $mediaFile.Name
        Extension = $mediaFile.Extension
        Size = [Math]::Round($mediaFile.Length / 1MB, 2)  # Taille en MB
        LastModified = $mediaFile.LastWriteTime
        Type = if ($mediaFile.Extension -in $extensionsVideo) { "Vidéo" } else { "Audio" }
        HasSubtitles = $false
        Duration = "Inconnue"
        Resolution = "Inconnue"  # Pour les vidéos
        BitRate = "Inconnu"      # Pour les fichiers audio
    }
    
    # Vérifier la présence de sous-titres pour les vidéos
    if ($info.Type -eq "Vidéo") {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($mediaFile.FullName)
        $subtitleExtensions = @(".srt", ".sub", ".sbv", ".ass", ".ssa", ".vtt")
        
        foreach ($ext in $subtitleExtensions) {
            $potentialSubtitle = Join-Path $mediaFile.DirectoryName "$baseName$ext"
            if (Test-Path $potentialSubtitle) {
                $info.HasSubtitles = $true
                break
            }
        }
    }
    
    # Utiliser MediaInfo pour récupérer plus d'informations
    try {
        # Durée du fichier
        $info.Duration = (& mediainfo "--Output=General;%Duration/String3%" "$($mediaFile.FullName)" 2>$null).Trim()
        
        if ($info.Type -eq "Vidéo") {
            # Résolution pour les vidéos
            $info.Resolution = (& mediainfo "--Output=Video;%Width%x%Height%" "$($mediaFile.FullName)" 2>$null).Trim()
        } else {
            # Bitrate pour les fichiers audio
            $info.BitRate = (& mediainfo "--Output=Audio;%BitRate/String%" "$($mediaFile.FullName)" 2>$null).Trim()
        }
    } catch {
        Write-Verbose "Erreur lors de la récupération des informations MediaInfo: $_"
    }
    
    return $info
}

# Fonction modifiée pour afficher la prévisualisation avec plus d'informations
function Show-MediaPreview {
    param(
        [System.IO.FileInfo]$mediaFile
    )
    
    $info = Get-MediaInfo -mediaFile $mediaFile
    
    Clear-Host
    Write-ColorMessage "`n### PRÉVISUALISATION ###`n" -ForegroundColor Green
    Write-ColorMessage "Fichier : $($info.Name)" -ForegroundColor Yellow
    Write-ColorMessage "Type : $($info.Type)" -ForegroundColor Cyan
    Write-ColorMessage "Taille : $($info.Size) MB" -ForegroundColor White
    Write-ColorMessage "Durée : $($info.Duration)" -ForegroundColor Magenta
    
    if ($info.Type -eq "Vidéo") {
        if ($info.Resolution -ne "Inconnue") {
            Write-ColorMessage "Résolution : $($info.Resolution)" -ForegroundColor Magenta
        }
    } else {
        if ($info.BitRate -ne "Inconnu") {
            Write-ColorMessage "Bitrate : $($info.BitRate)" -ForegroundColor Magenta
        }
    }
    
    Write-ColorMessage "Dernière modification : $($info.LastModified)" -ForegroundColor White
    
    if ($info.Type -eq "Vidéo" -and $info.HasSubtitles) {
        Write-ColorMessage "Sous-titres : Disponibles" -ForegroundColor Green
    } elseif ($info.Type -eq "Vidéo") {
        Write-ColorMessage "Sous-titres : Non disponibles" -ForegroundColor DarkGray
    }
    
    # Suite de la fonction inchangée...
    Write-Host "`nOptions :"
    Write-ColorMessage "1 - Lecture normale" -ForegroundColor White
    
    if ($info.Type -eq "Vidéo") {
        Write-ColorMessage "2 - Lecture en plein écran" -ForegroundColor White
    }
    
    Write-ColorMessage "3 - Lecture en boucle" -ForegroundColor White
    
    if ($info.Type -eq "Vidéo") {
        Write-ColorMessage "4 - Lecture en plein écran et en boucle" -ForegroundColor White
    }
    
    Write-ColorMessage "R - Retour" -ForegroundColor White
    
    $choice = Read-Host "`nVotre choix"
    return $choice
}

# Fonction pour afficher une liste paginée
function Show-PagedList {
    param(
        [array]$items,
        [int]$pageSize,
        [string]$title,
        [scriptblock]$displayItem
    )
    
    $totalItems = $items.Count
    $totalPages = [Math]::Ceiling($totalItems / $pageSize)
    $currentPage = 1
    
    while ($true) {
        Clear-Host
        Write-ColorMessage "`n$title - Page $currentPage/$totalPages`n" -ForegroundColor Green
        
        $startIndex = ($currentPage - 1) * $pageSize
        $endIndex = [Math]::Min($startIndex + $pageSize - 1, $totalItems - 1)
        
        for ($i = $startIndex; $i -le $endIndex; $i++) {
            & $displayItem $items[$i] ($i + 1)
        }
        
        Write-Host "`nNavigation :"
        if ($currentPage -gt 1) {
            Write-ColorMessage "P - Page précédente" -ForegroundColor Yellow
        }
        if ($currentPage -lt $totalPages) {
            Write-ColorMessage "N - Page suivante" -ForegroundColor Yellow
        }
        Write-ColorMessage "Q - Quitter la pagination" -ForegroundColor Red
        
        $choice = Read-Host "`nVotre choix (ou entrez un numéro pour sélectionner)"
        
        switch ($choice.ToUpper()) {
            "P" {
                if ($currentPage -gt 1) {
                    $currentPage--
                }
            }
            "N" {
                if ($currentPage -lt $totalPages) {
                    $currentPage++
                }
            }
            "Q" {
                return $null
            }
            default {
                $choiceNum = $choice -as [int]
                if ($null -ne $choiceNum -and $choiceNum -gt 0 -and $choiceNum -le $totalItems) {
                    return $choiceNum
                }
            }
        }
    }
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

# Option pour naviguer dans les répertoires
Write-ColorMessage "Voulez-vous naviguer dans les répertoires pour sélectionner un dossier ? (O/N)" -ForegroundColor Yellow
$navigateOption = Read-Host

if ($navigateOption.ToUpper() -eq "O") {
    $repertoire = Navigate-Directories -startPath $repertoire
}

# Vérifier si VLC est installé
$vlcExePath = Test-VLCInstalled
if (-not $vlcExePath) {
    Write-ColorMessage "VLC n'est pas installé ou n'a pas été trouvé aux emplacements standards." -ForegroundColor Red
    Write-ColorMessage "Veuillez installer VLC ou spécifier le chemin correct dans le script." -ForegroundColor Red
    Write-ColorMessage "Appuyez sur une touche pour quitter..." -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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

# Récupérer tous les fichiers multimédia avec gestion d'erreurs
try {
    $fichiersMultimedia = Get-ChildItem -Path $repertoire -File -ErrorAction Stop | Where-Object { 
        $_.Extension -in $extensionsSupported 
    } | Sort-Object Extension, Name
} catch {
    Write-ColorMessage "Erreur lors de l'accès au répertoire: $_" -ForegroundColor Red
    Write-ColorMessage "Appuyez sur une touche pour quitter..." -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

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
    
    # Afficher les fichiers avec la pagination
    if ($fichiersMultimedia.Count -gt $elementsParPage) {
        Write-ColorMessage "Utilisation de la pagination ($elementsParPage éléments par page)" -ForegroundColor Yellow
        
        # Définir comment afficher chaque élément
        $displayItem = {
            param($item, $index)
            $couleur = if ($item.Extension -in $extensionsVideo) { "Cyan" } else { "Magenta" }
            $type = if ($item.Extension -in $extensionsVideo) { "[Video] " } else { "[Audio] " }
            Write-ColorMessage "$index - $type$($item.Name)" -ForegroundColor $couleur
        }
        
        # Afficher la liste paginée
        $selectedIndex = Show-PagedList -items $fichiersMultimedia -pageSize $elementsParPage -title "Liste des fichiers multimédia" -displayItem $displayItem
        
        if ($null -eq $selectedIndex) {
            # L'utilisateur a quitté la pagination sans sélectionner
            Write-ColorMessage "Aucun fichier sélectionné. Affichage du menu principal..." -ForegroundColor Yellow
            Write-Host ""
        } else {
            # L'utilisateur a sélectionné un fichier
            $fichierSelectionne = $fichiersMultimedia[$selectedIndex - 1]
            
            # Afficher la prévisualisation et les options de lecture
            $optionLecture = Show-MediaPreview -mediaFile $fichierSelectionne
            
            # Préparer les arguments VLC de base
            $vlcArgs = @()
            
            # Ajouter des options en fonction des paramètres
            if ($repeat) {
                $vlcArgs += "--loop"
            }
            if ($volume -ne 100) {
                $vlcArgs += "--volume=$volume"
            }
            
            # Traiter le choix de l'utilisateur
            $estVideo = $fichierSelectionne.Extension -in $extensionsVideo
            
            switch ($optionLecture.ToUpper()) {
                "1" {
                    Start-Process $vlcExePath -ArgumentList ($vlcArgs + "`"$($fichierSelectionne.FullName)`"")
                    Write-ColorMessage "Lecture de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                }
                "2" {
                    if ($estVideo) {
                        Start-Process $vlcExePath -ArgumentList ($vlcArgs + "--fullscreen `"$($fichierSelectionne.FullName)`"")
                        Write-ColorMessage "Lecture plein écran de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                    } else {
                        Write-ColorMessage "Option invalide pour un fichier audio. Lecture normale lancée." -ForegroundColor Yellow
                        Start-Process $vlcExePath -ArgumentList ($vlcArgs + "`"$($fichierSelectionne.FullName)`"")
                        Write-ColorMessage "Lecture de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                    }
                }
                "3" {
                    Start-Process $vlcExePath -ArgumentList ($vlcArgs + "--loop `"$($fichierSelectionne.FullName)`"")
                    Write-ColorMessage "Lecture en boucle de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                }
                "4" {
                    if ($estVideo) {
                        Start-Process $vlcExePath -ArgumentList ($vlcArgs + "--fullscreen --loop `"$($fichierSelectionne.FullName)`"")
                        Write-ColorMessage "Lecture plein écran et en boucle de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                    } else {
                        Write-ColorMessage "Option invalide pour un fichier audio. Lecture en boucle lancée." -ForegroundColor Yellow
                        Start-Process $vlcExePath -ArgumentList ($vlcArgs + "--loop `"$($fichierSelectionne.FullName)`"")
                        Write-ColorMessage "Lecture en boucle de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                    }
                }
                "R" {
                    # Relancer le script
                    & $MyInvocation.MyCommand.Path -repertoire $repertoire
                    exit 0
                }
                default {
                    Write-ColorMessage "Option invalide. Lecture normale lancée." -ForegroundColor Yellow
                    Start-Process $vlcExePath -ArgumentList ($vlcArgs + "`"$($fichierSelectionne.FullName)`"")
                    Write-ColorMessage "Lecture de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                }
            }
            
            exit 0
        }
    } else {
        # Afficher la liste simple si peu d'éléments
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
    }
    
    Write-Host ""
    Write-ColorMessage "Options disponibles :" -ForegroundColor Yellow
    Write-ColorMessage "- Entrez un numéro (1-$($fichiersMultimedia.Count)) pour lire un fichier spécifique" -ForegroundColor White
    Write-ColorMessage "- Entrez 'A' pour lire tous les fichiers en séquence" -ForegroundColor White
    Write-ColorMessage "- Entrez 'V' pour lire uniquement les fichiers vidéo" -ForegroundColor White
    Write-ColorMessage "- Entrez 'M' pour lire uniquement les fichiers audio" -ForegroundColor White
    Write-ColorMessage "- Entrez 'R' pour lire tous les fichiers en mode aléatoire" -ForegroundColor White
    Write-ColorMessage "- Entrez 'N' pour naviguer dans un autre répertoire" -ForegroundColor White
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
            try {
                # Créer une playlist temporaire pour tous les fichiers
                $playlistPath = [System.IO.Path]::Combine($env:TEMP, "vlc_playlist_$(Get-Random).m3u")
                $fichiersMultimedia | ForEach-Object { $_.FullName } | Out-File -FilePath $playlistPath -Encoding utf8 -ErrorAction Stop
                
                # Lancer VLC avec la playlist
                $vlcArgs += "`"$playlistPath`""
                Start-Process $vlcExePath -ArgumentList $vlcArgs
                
                Write-ColorMessage "Lecture de tous les fichiers lancée..." -ForegroundColor Green
            } catch {
                Write-ColorMessage "Erreur lors de la création de la playlist: $_" -ForegroundColor Red
                Write-ColorMessage "Appuyez sur une touche pour continuer..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
        "V" {
            if ($fichiersVideo.Count -gt 0) {
                try {
                    # Créer une playlist temporaire pour les vidéos uniquement
                    $playlistPath = [System.IO.Path]::Combine($env:TEMP, "vlc_playlist_$(Get-Random).m3u")
                    $fichiersVideo | ForEach-Object { $_.FullName } | Out-File -FilePath $playlistPath -Encoding utf8 -ErrorAction Stop
                    
                    # Lancer VLC avec la playlist
                    $vlcArgs += "`"$playlistPath`""
                    Start-Process $vlcExePath -ArgumentList $vlcArgs
                    
                    Write-ColorMessage "Lecture des fichiers vidéo lancée..." -ForegroundColor Green
                } catch {
                    Write-ColorMessage "Erreur lors de la création de la playlist: $_" -ForegroundColor Red
                    Write-ColorMessage "Appuyez sur une touche pour continuer..." -ForegroundColor Red
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            } else {
                Write-ColorMessage "Aucun fichier vidéo trouvé." -ForegroundColor Red
                Write-ColorMessage "Appuyez sur une touche pour continuer..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                # Relancer le script
                & $MyInvocation.MyCommand.Path -repertoire $repertoire
                exit 0
            }
        }
        "M" {
            if ($fichiersAudio.Count -gt 0) {
                try {
                    # Créer une playlist temporaire pour les audios uniquement
                    $playlistPath = [System.IO.Path]::Combine($env:TEMP, "vlc_playlist_$(Get-Random).m3u")
                    $fichiersAudio | ForEach-Object { $_.FullName } | Out-File -FilePath $playlistPath -Encoding utf8 -ErrorAction Stop
                    
                    # Lancer VLC avec la playlist
                    $vlcArgs += "`"$playlistPath`""
                    Start-Process $vlcExePath -ArgumentList $vlcArgs
                    
                    Write-ColorMessage "Lecture des fichiers audio lancée..." -ForegroundColor Green
                } catch {
                    Write-ColorMessage "Erreur lors de la création de la playlist: $_" -ForegroundColor Red
                    Write-ColorMessage "Appuyez sur une touche pour continuer..." -ForegroundColor Red
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            } else {
                Write-ColorMessage "Aucun fichier audio trouvé." -ForegroundColor Red
                Write-ColorMessage "Appuyez sur une touche pour continuer..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                # Relancer le script
                & $MyInvocation.MyCommand.Path -repertoire $repertoire
                exit 0
            }
        }
        "R" {
            try {
                # Créer une playlist temporaire avec ordre aléatoire
                $playlistPath = [System.IO.Path]::Combine($env:TEMP, "vlc_playlist_$(Get-Random).m3u")
                $fichiersMultimedia | Get-Random -Count $fichiersMultimedia.Count | ForEach-Object { $_.FullName } | Out-File -FilePath $playlistPath -Encoding utf8 -ErrorAction Stop
                
                # Lancer VLC avec la playlist
                $vlcArgs += "--random"
                $vlcArgs += "`"$playlistPath`""
                Start-Process $vlcExePath -ArgumentList $vlcArgs
                
                Write-ColorMessage "Lecture aléatoire de tous les fichiers lancée..." -ForegroundColor Green
            } catch {
                Write-ColorMessage "Erreur lors de la création de la playlist: $_" -ForegroundColor Red
                Write-ColorMessage "Appuyez sur une touche pour continuer..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
        "N" {
            # Relancer le script avec l'option de navigation
            $nouveauRepertoire = Navigate-Directories -startPath $repertoire
            & $MyInvocation.MyCommand.Path -repertoire $nouveauRepertoire
            exit 0
        }
        "Q" {
            Write-ColorMessage "Au revoir !" -ForegroundColor Cyan
            exit 0
        }
        default {
            # Vérifier si le choix est un numéro valide
            $choixNum = $choix.Trim() -as [int]  # Supprimer les espaces et convertir en entier
            
            if ($null -ne $choixNum -and $choixNum -gt 0 -and $choixNum -le $fichiersMultimedia.Count) {
                $fichierSelectionne = $fichiersMultimedia[$choixNum - 1]
                
                # Afficher la prévisualisation et les options de lecture
                $optionLecture = Show-MediaPreview -mediaFile $fichierSelectionne
                
                $estVideo = $fichierSelectionne.Extension -in $extensionsVideo
                
                switch ($optionLecture.ToUpper()) {
                    "1" {
                        Start-Process $vlcExePath -ArgumentList ($vlcArgs + "`"$($fichierSelectionne.FullName)`"")
                        Write-ColorMessage "Lecture de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                    }
                    "2" {
                        if ($estVideo) {
                            Start-Process $vlcExePath -ArgumentList ($vlcArgs + "--fullscreen `"$($fichierSelectionne.FullName)`"")
                            Write-ColorMessage "Lecture plein écran de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                        } else {
                            Write-ColorMessage "Option invalide pour un fichier audio. Lecture normale lancée." -ForegroundColor Yellow
                            Start-Process $vlcExePath -ArgumentList ($vlcArgs + "`"$($fichierSelectionne.FullName)`"")
                            Write-ColorMessage "Lecture de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                        }
                    }
                    "3" {
                        Start-Process $vlcExePath -ArgumentList ($vlcArgs + "--loop `"$($fichierSelectionne.FullName)`"")
                        Write-ColorMessage "Lecture en boucle de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                    }
                    "4" {
                        if ($estVideo) {
                            Start-Process $vlcExePath -ArgumentList ($vlcArgs + "--fullscreen --loop `"$($fichierSelectionne.FullName)`"")
                            Write-ColorMessage "Lecture plein écran et en boucle de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                        } else {
                            Write-ColorMessage "Option invalide pour un fichier audio. Lecture en boucle lancée." -ForegroundColor Yellow
                            Start-Process $vlcExePath -ArgumentList ($vlcArgs + "--loop `"$($fichierSelectionne.FullName)`"")
                            Write-ColorMessage "Lecture en boucle de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                        }
                    }
                    "R" {
                        # Relancer le script
                        & $MyInvocation.MyCommand.Path -repertoire $repertoire
                        exit 0
                    }
                    default {
                        Write-ColorMessage "Option invalide. Lecture normale lancée." -ForegroundColor Yellow
                        Start-Process $vlcExePath -ArgumentList ($vlcArgs + "`"$($fichierSelectionne.FullName)`"")
                        Write-ColorMessage "Lecture de $($fichierSelectionne.Name) lancée..." -ForegroundColor Green
                    }
                }
            } else {
                Write-ColorMessage "Choix invalide: '$choix'. Veuillez entrer un numéro entre 1 et $($fichiersMultimedia.Count)." -ForegroundColor Red
                Write-ColorMessage "Appuyez sur une touche pour continuer..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                # Relancer le script
                & $MyInvocation.MyCommand.Path -repertoire $repertoire
                exit 0
            }
        }
    }
} else {
    Write-ColorMessage "Aucun fichier multimédia trouvé dans le répertoire $repertoire" -ForegroundColor Red
    Write-ColorMessage "Extensions vidéo recherchées : $($extensionsVideo -join ', ')" -ForegroundColor Yellow
    Write-ColorMessage "Extensions audio recherchées : $($extensionsAudio -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    
    # Proposer de naviguer vers un autre répertoire
    Write-ColorMessage "Souhaitez-vous naviguer vers un autre répertoire ? (O/N)" -ForegroundColor Yellow
    $navigateAgain = Read-Host
    
    if ($navigateAgain.ToUpper() -eq "O") {
        $nouveauRepertoire = Navigate-Directories -startPath $repertoire
        & $MyInvocation.MyCommand.Path -repertoire $nouveauRepertoire
    } else {
        Write-ColorMessage "Au revoir !" -ForegroundColor Cyan
    }
}