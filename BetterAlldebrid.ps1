# Script PowerShell pour Alldebrid - Version prête à l'emploi
# ----------------------------------------------

# ========= CONFIGURATION PRÉDÉFINIE =========
# Entrez votre clé API ici 
$predefinedApiKey = "xFtbwg0wRYTcx6umhLOX"

# Nombre maximal de tentatives en cas d'échec de téléchargement
$maxRetries = 3

# Nom d'agent pour les requêtes API
$userAgent = "BetterAlldebrid"

# ========= FIN DE LA CONFIGURATION PRÉDÉFINIE =========

# Chargement des assemblies nécessaires
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Drawing

# Fonction pour sélectionner un dossier avec une fenêtre de dialogue
function Select-Folder {
    param (
        [string]$Description = "Sélectionnez un dossier de destination",
        [string]$InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    )
    
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    $folderBrowser.SelectedPath = $InitialDirectory
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    return $null
}

# Fonction pour créer un fichier de configuration si nécessaire
function Initialize-Config {
    # Déterminer le chemin du fichier de configuration (même dossier que le script)
    $scriptPath = $PSScriptRoot
    if (-not $scriptPath) {
        $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    }
    if (-not $scriptPath) {
        $scriptPath = [Environment]::GetFolderPath('MyDocuments')
    }
    
    # Définir un fichier de log unique dans le même dossier que le script
    $script:logFile = Join-Path -Path $scriptPath -ChildPath "alldebrid_log.txt"
    
    $script:configFilePath = Join-Path -Path $scriptPath -ChildPath "AlldebridDownloader.config"
    
    # Charger la configuration existante ou créer une nouvelle
    if (Test-Path -Path $script:configFilePath) {
        try {
            $config = Get-Content -Path $script:configFilePath | ConvertFrom-Json
            $script:currentDownloadFolder = $config.DownloadFolder
            # Ne pas charger le chemin du log depuis la config pour assurer sa cohérence
        }
        catch {
            # Fichier de configuration corrompu ou invalide, on crée un nouveau
            Create-DefaultConfig
        }
    } else {
        Create-DefaultConfig
    }
}

# Fonction pour créer une configuration par défaut
function Create-DefaultConfig {
    # Définir des chemins par défaut
    $defaultDownloadFolder = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "AlldebridDownloads"
    $script:currentDownloadFolder = $defaultDownloadFolder
    
    # Créer la configuration par défaut
    $config = @{
        DownloadFolder = $defaultDownloadFolder
        # Ne pas stocker le chemin du log dans la config
    }
    
    # S'assurer que le dossier existe
    if (-not (Test-Path -Path $defaultDownloadFolder)) {
        New-Item -ItemType Directory -Path $defaultDownloadFolder -Force | Out-Null
    }
    
    # Enregistrer la configuration
    $config | ConvertTo-Json | Set-Content -Path $script:configFilePath
}

# Fonction pour sauvegarder la configuration
function Save-Config {
    $config = @{
        DownloadFolder = $script:currentDownloadFolder
        # Ne pas stocker le chemin du log dans la config
    }
    
    # Enregistrer la configuration
    $config | ConvertTo-Json | Set-Content -Path $script:configFilePath
}

# Création des dossiers nécessaires s'ils n'existent pas
function Initialize-Environment {
    if (-not (Test-Path -Path $script:currentDownloadFolder)) {
        New-Item -ItemType Directory -Path $script:currentDownloadFolder -Force | Out-Null
        Write-Host "Dossier de téléchargement créé: $script:currentDownloadFolder" -ForegroundColor Green
    }
    
    $logDirectory = Split-Path -Path $script:logFile -Parent
    if (-not (Test-Path -Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
        Write-Host "Dossier de logs créé: $logDirectory" -ForegroundColor Green
    }
}

# Fonction pour écrire dans le fichier de log
function Write-Log {
    param (
        [string]$Message,
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Ajouter au fichier de log (crée le fichier s'il n'existe pas)
    "$timestamp - $Message" | Out-File -FilePath $script:logFile -Append
    
    if (-not $NoConsole) {
        Write-Host $Message
    }
}

# Fonction pour débloquer un lien via l'API Alldebrid
function Unlock-AlldebridLink {
    param (
        [string]$Link
    )
    
    Write-Log "Décodage du lien: $Link"
    $encodedLink = [System.Web.HttpUtility]::UrlEncode($Link)
    
    $apiUrl = "https://api.alldebrid.com/v4/link/unlock?agent=$userAgent&apikey=$predefinedApiKey&link=$encodedLink"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        
        if ($response.status -eq "success") {
            Write-Log "Lien décodé avec succès"
            return $response.data
        } else {
            Write-Log "Erreur lors du décodage: $($response.error.message)"
            return $null
        }
    } catch {
        Write-Log "Exception lors de l'appel à l'API: $_"
        return $null
    }
}

# Fonction pour télécharger un fichier avec suivi de progression et reprise
function Download-File {
    param (
        [string]$Url,
        [string]$FileName,
        [string]$Destination
    )
    
    $filePath = Join-Path -Path $Destination -ChildPath $FileName
    $tempFilePath = "$filePath.tmp"
    
    # Vérification si le fichier existe déjà
    if (Test-Path -Path $filePath) {
        Write-Log "Le fichier '$FileName' existe déjà."
        $overwrite = Read-Host "Voulez-vous l'écraser? (O/N)"
        if ($overwrite -ne "O") {
            Write-Log "Téléchargement annulé par l'utilisateur."
            return $false
        }
    }
    
    $retryCount = 0
    $downloadSuccess = $false
    
    while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
        try {
            if ($retryCount -gt 0) {
                Write-Log "Tentative $($retryCount + 1)/$maxRetries..."
            }
            
            # Vérifier si une reprise est possible
            $startPosition = 0
            if (Test-Path -Path $tempFilePath) {
                $existingFile = Get-Item -Path $tempFilePath
                $startPosition = $existingFile.Length
                Write-Log "Reprise du téléchargement à partir de $startPosition bytes"
            }
            
            $webRequest = [System.Net.HttpWebRequest]::Create($Url)
            $webRequest.Headers.Add("Range", "bytes=$startPosition-")
            $webRequest.Method = "GET"
            $webRequest.UserAgent = $userAgent
            
            $response = $webRequest.GetResponse()
            $totalLength = $response.ContentLength + $startPosition
            $responseStream = $response.GetResponseStream()
            
            $mode = if ($startPosition -gt 0) { "Append" } else { "Create" }
            $fileStream = New-Object IO.FileStream($tempFilePath, $mode)
            
            # Paramètres pour le téléchargement et l'affichage de la progression
            $buffer = New-Object byte[] 10MB
            $totalBytesRead = $startPosition
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $lastUpdateTime = Get-Date
            $lastBytesRead = $totalBytesRead
            
            # Boucle de téléchargement
            while ($true) {
                $bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)
                
                if ($bytesRead -eq 0) {
                    break
                }
                
                $fileStream.Write($buffer, 0, $bytesRead)
                $totalBytesRead += $bytesRead
                
                # Mise à jour de la progression toutes les secondes
                $currentTime = Get-Date
                $elapsedSeconds = ($currentTime - $lastUpdateTime).TotalSeconds
                
                if ($elapsedSeconds -ge 1) {
                    $percentComplete = [math]::Round(($totalBytesRead / $totalLength) * 100, 2)
                    $speed = [math]::Round(($totalBytesRead - $lastBytesRead) / $elapsedSeconds / 1MB, 2)
                    $remainingBytes = $totalLength - $totalBytesRead
                    
                    if ($speed -gt 0) {
                        $estimatedSeconds = $remainingBytes / ($speed * 1MB)
                        $timeRemaining = [TimeSpan]::FromSeconds($estimatedSeconds)
                        $timeRemainingStr = "{0:hh\:mm\:ss}" -f $timeRemaining
                    } else {
                        $timeRemainingStr = "Calcul..."
                    }
                    
                    Write-Progress -Activity "Téléchargement de $FileName" `
                        -Status "$percentComplete% Complet - $([math]::Round($totalBytesRead / 1MB, 2)) MB / $([math]::Round($totalLength / 1MB, 2)) MB (${speed} MB/s)" `
                        -PercentComplete $percentComplete `
                        -CurrentOperation "Temps restant estimé: $timeRemainingStr"
                    
                    $lastUpdateTime = $currentTime
                    $lastBytesRead = $totalBytesRead
                }
            }
            
            # Finalisation du téléchargement
            $fileStream.Close()
            $responseStream.Close()
            $response.Close()
            
            # Renommage du fichier temporaire
            Move-Item -Path $tempFilePath -Destination $filePath -Force
            
            $totalTime = $stopwatch.Elapsed
            $averageSpeed = [math]::Round($totalLength / $totalTime.TotalSeconds / 1MB, 2)
            
            Write-Progress -Activity "Téléchargement de $FileName" -Completed
            Write-Log "Téléchargement terminé: $FileName"
            Write-Log "Taille: $([math]::Round($totalLength / 1MB, 2)) MB | Temps: $($totalTime.ToString("hh\:mm\:ss")) | Vitesse moyenne: ${averageSpeed} MB/s"
            
            $downloadSuccess = $true
        }
        catch {
            $retryCount++
            Write-Log "Erreur lors du téléchargement: $_"
            
            if ($retryCount -ge $maxRetries) {
                Write-Log "Nombre maximum de tentatives atteint. Téléchargement abandonné."
                return $false
            }
            
            $waitTime = [math]::Pow(2, $retryCount) # Attente exponentielle
            Write-Log "Nouvelle tentative dans $waitTime secondes..."
            Start-Sleep -Seconds $waitTime
        }
    }
    
    return $downloadSuccess
}

# Fonction principale du script
function Start-AlldebridDownload {
    param (
        [string[]]$Links,
        [string]$Category = ""
    )
    
    Initialize-Environment
    
    # Création d'un sous-dossier pour la catégorie si spécifiée
    $destinationFolder = $script:currentDownloadFolder
    if ($Category -ne "") {
        $destinationFolder = Join-Path -Path $script:currentDownloadFolder -ChildPath $Category
        if (-not (Test-Path -Path $destinationFolder)) {
            New-Item -ItemType Directory -Path $destinationFolder | Out-Null
            Write-Log "Dossier de catégorie créé: $destinationFolder"
        }
    }
    
    $successCount = 0
    $failCount = 0
    
    foreach ($link in $Links) {
        Write-Log "---------------------------------------------"
        Write-Log "Traitement du lien: $link"
        
        $unlocked = Unlock-AlldebridLink -Link $link
        
        if ($null -ne $unlocked) {
            $downloadLink = $unlocked.link
            $fileName = $unlocked.filename
            
            # Si le nom de fichier est vide, en générer un basé sur l'URL
            if ([string]::IsNullOrEmpty($fileName)) {
                $uri = New-Object System.Uri($downloadLink)
                $fileName = [System.IO.Path]::GetFileName($uri.LocalPath)
                
                if ([string]::IsNullOrEmpty($fileName)) {
                    $fileName = "download_$(Get-Date -Format 'yyyyMMdd_HHmmss').bin"
                }
            }
            
            Write-Log "Lien direct obtenu pour: $fileName"
            
            $success = Download-File -Url $downloadLink -FileName $fileName -Destination $destinationFolder
            
            if ($success) {
                $successCount++
            } else {
                $failCount++
            }
        } else {
            $failCount++
        }
    }
    
    Write-Log "---------------------------------------------"
    Write-Log "Résumé des téléchargements:"
    Write-Log "Réussis: $successCount | Échoués: $failCount | Total: $($Links.Count)"
}

# Fonction pour vérifier la validité de l'API
<#function Test-ApiValidity {
    # Vérification simple de l'API
    $apiUrl = "https://api.alldebrid.com/v4/user/login?agent=$userAgent&apikey=$predefinedApiKey"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        
        if ($response.status -eq "success") {
            Write-Host "✅ Connexion API Alldebrid réussie!" -ForegroundColor Green
            Write-Host "Nom d'utilisateur: $($response.data.user.username)" -ForegroundColor Cyan
            
            if ($response.data.user.isPremium) {
                Write-Host "Type de compte: Premium" -ForegroundColor Green
                Write-Host "Expiration: $($response.data.user.premiumUntil)" -ForegroundColor Cyan
            } else {
                Write-Host "Type de compte: Gratuit" -ForegroundColor Yellow
            }
            
            return $true
        } else {
            Write-Host "❌ Erreur avec la clé API: $($response.error.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Exception lors de la vérification de l'API: $_" -ForegroundColor Red
        return $false
    }
}#>

# Interface graphique pour l'entrée des liens
function Show-DownloadDialog {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Téléchargement rapide Alldebrid"
    $form.Size = New-Object System.Drawing.Size(600, 400)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    
    # Labels
    $labelLinks = New-Object System.Windows.Forms.Label
    $labelLinks.Location = New-Object System.Drawing.Point(20, 20)
    $labelLinks.Size = New-Object System.Drawing.Size(560, 20)
    $labelLinks.Text = "Collez vos liens (un par ligne):"
    $form.Controls.Add($labelLinks)
    
    # Zone de texte multi-lignes pour les liens
    $textBoxLinks = New-Object System.Windows.Forms.TextBox
    $textBoxLinks.Location = New-Object System.Drawing.Point(20, 40)
    $textBoxLinks.Size = New-Object System.Drawing.Size(560, 200)
    $textBoxLinks.Multiline = $true
    $textBoxLinks.ScrollBars = "Vertical"
    $form.Controls.Add($textBoxLinks)
    
    # Label pour la catégorie
    $labelCategory = New-Object System.Windows.Forms.Label
    $labelCategory.Location = New-Object System.Drawing.Point(20, 250)
    $labelCategory.Size = New-Object System.Drawing.Size(200, 20)
    $labelCategory.Text = "Catégorie (facultatif):"
    $form.Controls.Add($labelCategory)
    
    # Textbox pour la catégorie
    $textBoxCategory = New-Object System.Windows.Forms.TextBox
    $textBoxCategory.Location = New-Object System.Drawing.Point(20, 270)
    $textBoxCategory.Size = New-Object System.Drawing.Size(200, 20)
    $form.Controls.Add($textBoxCategory)
    
    # Bouton pour choisir le dossier
    $buttonFolder = New-Object System.Windows.Forms.Button
    $buttonFolder.Location = New-Object System.Drawing.Point(230, 270)
    $buttonFolder.Size = New-Object System.Drawing.Size(200, 23)
    $buttonFolder.Text = "Changer le dossier de destination"
    # Modification dans le bouton de l'interface graphique
    $buttonFolder.Add_Click({
        $selectedFolder = Select-Folder -Description "Choisissez le dossier de destination pour les téléchargements" -InitialDirectory $script:currentDownloadFolder
        if ($selectedFolder) {
            $script:currentDownloadFolder = $selectedFolder
            # Ne pas modifier l'emplacement du fichier de log
            Save-Config
            $labelFolder.Text = "Dossier: $script:currentDownloadFolder"
        }
    })
    $form.Controls.Add($buttonFolder)
    
    # Label pour afficher le dossier actuel
    $labelFolder = New-Object System.Windows.Forms.Label
    $labelFolder.Location = New-Object System.Drawing.Point(20, 300)
    $labelFolder.Size = New-Object System.Drawing.Size(560, 20)
    $labelFolder.Text = "Dossier: $script:currentDownloadFolder"
    $form.Controls.Add($labelFolder)
    
    # Bouton de téléchargement
    $buttonDownload = New-Object System.Windows.Forms.Button
    $buttonDownload.Location = New-Object System.Drawing.Point(440, 270)
    $buttonDownload.Size = New-Object System.Drawing.Size(140, 23)
    $buttonDownload.Text = "Télécharger"
    $buttonDownload.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $buttonDownload.ForeColor = [System.Drawing.Color]::White
    $buttonDownload.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $buttonDownload.Add_Click({
        $links = $textBoxLinks.Text -split "`r`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        
        if ($links.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Veuillez entrer au moins un lien.", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $form.Hide()
        
        # Démarrer le téléchargement
        Start-AlldebridDownload -Links $links -Category $textBoxCategory.Text
        
        [System.Windows.Forms.MessageBox]::Show("Opération terminée. Consultez les logs pour plus de détails.", "Téléchargement terminé", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        
        $form.Close()
    })
    $form.Controls.Add($buttonDownload)
    
    # Centrer la fenêtre
    $form.Add_Shown({$form.Activate()})
    
    # Afficher la fenêtre
    $form.ShowDialog() | Out-Null
}

# Fonction pour détecter l'installation de VLC
function Find-VlcPath {
    $possiblePaths = @(
        "${env:ProgramFiles}\VideoLAN\VLC\vlc.exe",
        "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path -Path $path) {
            return $path
        }
    }
    
    return $null
}

# Fonction pour lire un lien directement avec VLC
function Start-VlcStreaming {
    param (
        [string]$Link
    )
    
    Write-Log "Préparation du streaming pour: $Link"
    
    # Décoder le lien via l'API Alldebrid
    $unlocked = Unlock-AlldebridLink -Link $Link
    
    if ($null -eq $unlocked) {
        Write-Log "Impossible de débloquer le lien pour le streaming."
        return $false
    }
    
    $streamLink = $unlocked.link
    $fileName = $unlocked.filename
    
    Write-Log "Lien direct obtenu pour streaming: $fileName"
    
    # Trouver le chemin vers VLC
    $vlcPath = Find-VlcPath
    
    if ($null -eq $vlcPath) {
        Write-Host "VLC n'a pas été trouvé sur votre système." -ForegroundColor Red
        Write-Host "Veuillez spécifier manuellement le chemin vers vlc.exe:" -ForegroundColor Yellow
        $vlcPath = Read-Host "Chemin vers vlc.exe"
        
        if (-not (Test-Path -Path $vlcPath)) {
            Write-Log "Chemin VLC invalide. Streaming annulé."
            return $false
        }
    }
    
    try {
        Write-Log "Lancement de VLC avec le lien streaming..."
        Write-Host "Lancement de la lecture avec VLC..." -ForegroundColor Green
        Write-Host "Titre: $fileName" -ForegroundColor Cyan
        
        # Démarrer VLC avec le lien en paramètre
        Start-Process -FilePath $vlcPath -ArgumentList "--fullscreen `"$streamLink`"" -NoNewWindow
        
        Write-Log "VLC démarré avec succès pour le streaming."
        return $true
    }
    catch {
        Write-Log "Erreur lors du lancement de VLC: $_"
        return $false
    }
}

# Fonction pour télécharger un torrent via l'API Alldebrid
function Add-AlldebridTorrent {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TorrentSource
    )
    
    Write-Log "Ajout du torrent: $TorrentSource"
    
    # Déterminer si c'est un magnet, une URL ou un fichier local
    if ($TorrentSource -match "^magnet:\?") {
        # C'est un lien magnet
        $encodedMagnet = [System.Web.HttpUtility]::UrlEncode($TorrentSource)
        $apiUrl = "https://api.alldebrid.com/v4/magnet/upload?agent=$userAgent&apikey=$predefinedApiKey&magnets[]=$encodedMagnet"
        
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Get
            
            if ($response.status -eq "success") {
                Write-Log "Magnet ajouté avec succès"
                return $response.data.magnets[0]
            } else {
                Write-Log "Erreur lors de l'ajout du magnet: $($response.error.message)"
                return $null
            }
        } catch {
            Write-Log "Exception lors de l'appel à l'API: $_"
            return $null
        }
    }
    elseif ($TorrentSource -match "^https?://") {
        # C'est une URL de torrent
        $encodedUrl = [System.Web.HttpUtility]::UrlEncode($TorrentSource)
        $apiUrl = "https://api.alldebrid.com/v4/magnet/upload/url?agent=$userAgent&apikey=$predefinedApiKey&url=$encodedUrl"
        
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Get
            
            if ($response.status -eq "success") {
                Write-Log "Torrent URL ajouté avec succès"
                return $response.data.magnet
            } else {
                Write-Log "Erreur lors de l'ajout du torrent URL: $($response.error.message)"
                return $null
            }
        } catch {
            Write-Log "Exception lors de l'appel à l'API: $_"
            return $null
        }
    }
    else {
        # On suppose que c'est un fichier local
        if (Test-Path -Path $TorrentSource) {
            $apiUrl = "https://api.alldebrid.com/v4/magnet/upload/file?agent=$userAgent&apikey=$predefinedApiKey"
            
            try {
                $fileBin = [System.IO.File]::ReadAllBytes($TorrentSource)
                $fileEnc = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileBin)
                $boundary = [System.Guid]::NewGuid().ToString()
                $LF = "`r`n"
                
                $bodyLines = (
                    "--$boundary",
                    "Content-Disposition: form-data; name=`"file`"; filename=`"$(Split-Path -Leaf $TorrentSource)`"",
                    "Content-Type: application/x-bittorrent$LF",
                    $fileEnc,
                    "--$boundary--$LF"
                ) -join $LF
                
                $response = Invoke-RestMethod -Uri $apiUrl -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines
                
                if ($response.status -eq "success") {
                    Write-Log "Fichier torrent ajouté avec succès"
                    return $response.data.magnets[0]
                } else {
                    Write-Log "Erreur lors de l'ajout du fichier torrent: $($response.error.message)"
                    return $null
                }
            } catch {
                Write-Log "Exception lors de l'upload du fichier torrent: $_"
                return $null
            }
        } else {
            Write-Log "Fichier torrent non trouvé: $TorrentSource"
            return $null
        }
    }
}

# Fonction pour obtenir le statut d'un torrent
function Get-TorrentStatus {
    param (
        [Parameter(Mandatory=$true)]
        [string]$MagnetId
    )
    
    $apiUrl = "https://api.alldebrid.com/v4/magnet/status?agent=$userAgent&apikey=$predefinedApiKey&id=$MagnetId"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        
        if ($response.status -eq "success") {
            return $response.data.magnets
        } else {
            Write-Log "Erreur lors de la vérification du statut: $($response.error.message)"
            return $null
        }
    } catch {
        Write-Log "Exception lors de l'appel à l'API: $_"
        return $null
    }
}

# Fonction pour lister tous les torrents
function Get-AllTorrents {
    $apiUrl = "https://api.alldebrid.com/v4/magnet/status?agent=$userAgent&apikey=$predefinedApiKey"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        
        if ($response.status -eq "success") {
            return $response.data.magnets
        } else {
            Write-Log "Erreur lors de la récupération des torrents: $($response.error.message)"
            return $null
        }
    } catch {
        Write-Log "Exception lors de l'appel à l'API: $_"
        return $null
    }
}

# Fonction pour supprimer un torrent
function Remove-Torrent {
    param (
        [Parameter(Mandatory=$true)]
        [string]$MagnetId
    )
    
    $apiUrl = "https://api.alldebrid.com/v4/magnet/delete?agent=$userAgent&apikey=$predefinedApiKey&id=$MagnetId"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        
        if ($response.status -eq "success") {
            Write-Log "Torrent supprimé avec succès"
            return $true
        } else {
            Write-Log "Erreur lors de la suppression: $($response.error.message)"
            return $false
        }
    } catch {
        Write-Log "Exception lors de l'appel à l'API: $_"
        return $false
    }
}

# Interface pour gérer les torrents
function Show-TorrentManager {
    Clear-Host
    Write-Host "===== Gestionnaire de Torrents Alldebrid =====" -ForegroundColor Cyan
    
    $torrents = Get-AllTorrents
    
    #if ($null -eq $torrents) {
    #    Write-Host "Impossible de récupérer la liste des torrents." -ForegroundColor Red
    #    Pause
    #    return
    #}
    
    if ($torrents.Count -eq 0) {
        Write-Host "Aucun torrent en cours." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Ajouter un nouveau torrent"
        Write-Host "R. Retour au menu principal"
        
        $choice = Read-Host "Choisissez une option"
        
        switch ($choice) {
            "1" { Show-AddTorrentDialog }
            "R" { return }
            default {
                Write-Host "Option invalide." -ForegroundColor Red
                Pause
                Show-TorrentManager
            }
        }
    } else {
        # Afficher la liste des torrents
        Write-Host ""
        Write-Host "ID  | Statut       | Progression | Nom"
        Write-Host "----|--------------+------------+-------------------------"
        
        $i = 1
        foreach ($torrent in $torrents) {
            $status = $torrent.status
            $progress = if ($torrent.processing) { "$($torrent.processing.progress)%" } else { "N/A" }
            $name = $torrent.filename
            
            # Colorisation en fonction du statut
            $statusColor = switch ($status) {
                "active" { "Yellow" }
                "downloading" { "Blue" }
                "downloaded" { "Green" }
                "error" { "Red" }
                default { "White" }
            }
            
            Write-Host ("{0,3} | " -f $i) -NoNewline
            Write-Host ("{0,-12} | " -f $status) -ForegroundColor $statusColor -NoNewline
            Write-Host ("{0,10} | " -f $progress) -NoNewline
            Write-Host $name
            
            $i++
        }
        
        Write-Host ""
        Write-Host "1. Ajouter un nouveau torrent"
        Write-Host "2. Actualiser la liste"
        Write-Host "3. Voir les détails d'un torrent"
        Write-Host "4. Télécharger les fichiers d'un torrent"
        Write-Host "5. Supprimer un torrent"
        Write-Host "6. Changer le chemin de téléchargement du torrent"
        Write-Host "R. Retour au menu principal"
        
        $choice = Read-Host "Choisissez une option"
        
        switch ($choice) {
            "1" { Show-AddTorrentDialog; Show-TorrentManager }
            "2" { Show-TorrentManager }
            "3" { 
                $torrentId = Read-Host "Entrez le numéro du torrent à afficher"
                if ($torrentId -match "^\d+$" -and [int]$torrentId -gt 0 -and [int]$torrentId -le $torrents.Count) {
                    Show-TorrentDetails -Torrent $torrents[[int]$torrentId - 1]
                } else {
                    Write-Host "Numéro de torrent invalide." -ForegroundColor Red
                    Pause
                }
                Show-TorrentManager
            }
            "4" {
                $torrentId = Read-Host "Entrez le numéro du torrent à télécharger"
                if ($torrentId -match "^\d+$" -and [int]$torrentId -gt 0 -and [int]$torrentId -le $torrents.Count) {
                    Download-TorrentFiles -Torrent $torrents[[int]$torrentId - 1]
                } else {
                    Write-Host "Numéro de torrent invalide." -ForegroundColor Red
                    Pause
                }
                Show-TorrentManager
            }
            "5" {
                $torrentId = Read-Host "Entrez le numéro du torrent à supprimer"
                if ($torrentId -match "^\d+$" -and [int]$torrentId -gt 0 -and [int]$torrentId -le $torrents.Count) {
                    $confirm = Read-Host "Êtes-vous sûr de vouloir supprimer ce torrent? (O/N)"
                    if ($confirm -eq "O") {
                        $result = Remove-Torrent -MagnetId $torrents[[int]$torrentId - 1].id
                        if ($result) {
                            Write-Host "Torrent supprimé avec succès." -ForegroundColor Green
                        } else {
                            Write-Host "Échec de la suppression du torrent." -ForegroundColor Red
                        }
                        Pause
                    }
                } else {
                    Write-Host "Numéro de torrent invalide." -ForegroundColor Red
                    Pause
                }
                Show-TorrentManager
            }

            "6" {
            # Sélection du dossier de téléchargement avec Windows Forms
            Write-Host "Ouverture du sélecteur de dossier..." -ForegroundColor Cyan
            $selectedFolder = Select-Folder -Description "Choisissez le dossier de destination pour les téléchargements" -InitialDirectory $script:currentDownloadFolder
            
            if ($selectedFolder) {
                $script:currentDownloadFolder = $selectedFolder
                # Ne pas modifier l'emplacement du fichier de log
                Save-Config
                Write-Host "Nouveau dossier de téléchargement défini: $script:currentDownloadFolder" -ForegroundColor Green
            }
            
            Pause
            Show-TorrentManager
        }
            
            "R" { return }
            default {
                Write-Host "Option invalide." -ForegroundColor Red
                Pause
                Show-TorrentManager
            }
        }
    }
}

# Fonction pour ajouter un nouveau torrent
function Show-AddTorrentDialog {
    Clear-Host
    Write-Host "===== Ajout d'un nouveau torrent =====" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Ajouter par lien magnet"
    Write-Host "R. Retour"
    
    $choice = Read-Host "Choisissez une option"
    
    switch ($choice) {
        "1" {
            $magnet = Read-Host "Entrez le lien magnet"
            $result = Add-AlldebridTorrent -TorrentSource $magnet
            if ($result) {
                Write-Host "Torrent ajouté avec succès. ID: $($result.id)" -ForegroundColor Green
                # Optionnel : attendre que le torrent soit analysé
                Wait-ForTorrentInitialization -MagnetId $result.id
            } else {
                Write-Host "Échec de l'ajout du torrent." -ForegroundColor Red
            }
            Pause
            Show-TorrentManager
        }
        "R" { return }
        default {
            Write-Host "Option invalide." -ForegroundColor Red
            Pause
            Show-AddTorrentDialog
        }
    }
}

# Fonction pour afficher les détails d'un torrent
function Show-TorrentDetails {
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]$Torrent
    )
    
    # Récupérer les informations à jour
    $updatedTorrent = Get-TorrentStatus -MagnetId $Torrent.id
    
    if ($null -eq $updatedTorrent) {
        Write-Host "Impossible de récupérer les détails du torrent." -ForegroundColor Red
        Pause
        return
    }
    
    Clear-Host
    Write-Host "===== Détails du Torrent =====" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ID: $($updatedTorrent.id)"
    Write-Host "Nom: $($updatedTorrent.filename)"
    Write-Host "Statut: $($updatedTorrent.status)" -ForegroundColor $(
        switch ($updatedTorrent.status) {
            "active" { "Yellow" }
            "downloading" { "Blue" }
            "downloaded" { "Green" }
            "error" { "Red" }
            default { "White" }
        }
    )
    
    if ($updatedTorrent.processing) {
        Write-Host "Progression: $($updatedTorrent.processing.progress)%"
        if ($updatedTorrent.processing.speed.bytes -gt 0) {
            $speed = Format-Size -Bytes $updatedTorrent.processing.speed.bytes
            Write-Host "Vitesse: $speed/s"
        }
        if ($updatedTorrent.processing.eta.seconds -gt 0) {
            $eta = [TimeSpan]::FromSeconds($updatedTorrent.processing.eta.seconds)
            Write-Host "Temps restant: $($eta.ToString("hh\:mm\:ss"))"
        }
    }
    
    Write-Host "Taille: $(Format-Size -Bytes $updatedTorrent.size.bytes)"
    Write-Host "Date d'ajout: $($updatedTorrent.uploadDate)"
    
    # Afficher les fichiers si disponibles
    if ($updatedTorrent.links -and $updatedTorrent.links.Count -gt 0) {
        Write-Host ""
        Write-Host "Fichiers disponibles:" -ForegroundColor Green
        $i = 1
        foreach ($link in $updatedTorrent.links) {
            Write-Host "$i. $($link.filename) ($(Format-Size -Bytes $link.size))"
            $i++
        }
    } elseif ($updatedTorrent.files -and $updatedTorrent.files.Count -gt 0) {
        Write-Host ""
        Write-Host "Fichiers à télécharger (pas encore prêts):" -ForegroundColor Yellow
        $i = 1
        foreach ($file in $updatedTorrent.files) {
            Write-Host "$i. $($file.n) ($(Format-Size -Bytes $file.s))"
            $i++
        }
    }
    
    Write-Host ""
    Pause
}

# Fonction pour télécharger les fichiers d'un torrent
function Download-TorrentFiles {
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]$Torrent
    )
    
    # Récupérer les informations à jour
    $updatedTorrent = Get-TorrentStatus -MagnetId $Torrent.id
    
    if ($null -eq $updatedTorrent) {
        Write-Host "Impossible de récupérer les détails du torrent." -ForegroundColor Red
        Pause
        return
    }
    
    # Vérifier si le torrent est prêt à être téléchargé
    <# if ($updatedTorrent.status -ne "downloaded" -or $null -eq $updatedTorrent.links -or $updatedTorrent.links.Count -eq 0) {
        Write-Host "Ce torrent n'est pas encore prêt à être téléchargé." -ForegroundColor Yellow
        if ($updatedTorrent.status -eq "downloading") {
            Write-Host "Statut actuel: Téléchargement en cours ($($updatedTorrent.processing.progress)%)"
            
            $waitForDownload = Read-Host "Voulez-vous attendre la fin du téléchargement? (O/N)"
            if ($waitForDownload -eq "O") {
                Wait-ForTorrentCompletion -MagnetId $updatedTorrent.id
                # Récupérer à nouveau le torrent après l'attente
                $updatedTorrent = Get-TorrentStatus -MagnetId $Torrent.id
            } else {
                Pause
                return
            }
        } else {
            Pause
            return
        }
    } #>
    
    Clear-Host
    Write-Host "===== Téléchargement des fichiers du torrent =====" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Torrent: $($updatedTorrent.filename)"
    Write-Host "Fichiers disponibles:"
    
    $i = 1
    foreach ($link in $updatedTorrent.links) {
        Write-Host "$i. $($link.filename) ($(Format-Size -Bytes $link.size))"
        $i++
    }
    
    Write-Host ""
    Write-Host "Options:"
    Write-Host "1-$($updatedTorrent.links.Count): Télécharger un fichier spécifique"
    Write-Host "A. Télécharger tous les fichiers"
    Write-Host "R. Retour"
    
    $choice = Read-Host "Choisissez une option"
    
    if ($choice -eq "A") {
        # Créer un sous-dossier pour le torrent
        $torrentFolder = Join-Path -Path $script:currentDownloadFolder -ChildPath (Remove-InvalidFileNameChars -Name $updatedTorrent.filename)
        if (-not (Test-Path -Path $torrentFolder)) {
            New-Item -ItemType Directory -Path $torrentFolder | Out-Null
        }
        
        # Télécharger tous les fichiers
        $links = @()
        foreach ($link in $updatedTorrent.links) {
            $links += $link.link
        }
        
        Start-AlldebridDownload -Links $links -Category (Split-Path -Leaf $torrentFolder)
    }
    elseif ($choice -match "^\d+$" -and [int]$choice -gt 0 -and [int]$choice -le $updatedTorrent.links.Count) {
        $fileIndex = [int]$choice - 1
        $fileLink = $updatedTorrent.links[$fileIndex].link
        
        Start-AlldebridDownload -Links @($fileLink)
    }
    elseif ($choice -eq "R") {
        return
    }
    else {
        Write-Host "Option invalide." -ForegroundColor Red
        Pause
        Download-TorrentFiles -Torrent $updatedTorrent
    }
}

# Fonction pour attendre l'initialisation d'un torrent
function Wait-ForTorrentInitialization {
    param (
        [Parameter(Mandatory=$true)]
        [string]$MagnetId
    )
    
    Write-Host "Attente de l'initialisation du torrent..." -ForegroundColor Cyan
    
    $retry = 0
    $maxRetry = 10
    $initialized = $false
    
    while (-not $initialized -and $retry -lt $maxRetry) {
        Start-Sleep -Seconds 2
        
        $status = Get-TorrentStatus -MagnetId $MagnetId
        
        if ($null -ne $status -and ($status.status -ne "magnet_conversion" -and $status.status -ne "magnet_error")) {
            $initialized = $true
            Write-Host "Torrent initialisé avec succès!" -ForegroundColor Green
            Show-TorrentDetails -Torrent $status
        } else {
            Write-Host "." -NoNewline -ForegroundColor Yellow
            $retry++
        }
    }
    
    if (-not $initialized) {
        Write-Host "Délai d'initialisation dépassé. Veuillez vérifier l'état du torrent plus tard." -ForegroundColor Red
    }
}

# Fonction pour attendre la fin du téléchargement d'un torrent
function Wait-ForTorrentCompletion {
    param (
        [Parameter(Mandatory=$true)]
        [string]$MagnetId
    )
    
    Clear-Host
    Write-Host "Attente de la fin du téléchargement..." -ForegroundColor Cyan
    Write-Host "Appuyez sur Ctrl+C pour annuler l'attente"
    Write-Host ""
    
    $complete = $false
    $lastProgress = 0
    $lastUpdate = Get-Date
    
    while (-not $complete) {
        $status = Get-TorrentStatus -MagnetId $MagnetId
        
        if ($null -eq $status) {
            Write-Host "Erreur lors de la récupération du statut." -ForegroundColor Red
            break
        }
        
        if ($status.status -eq "downloaded") {
            Write-Host "`nTéléchargement terminé!" -ForegroundColor Green
            $complete = $true
        }
        elseif ($status.status -eq "error") {
            Write-Host "`nErreur lors du téléchargement du torrent." -ForegroundColor Red
            break
        }
        else {
            $currentTime = Get-Date
            
            # Mise à jour toutes les 3 secondes
            if (($currentTime - $lastUpdate).TotalSeconds -ge 3) {
                $progress = if ($status.processing) { $status.processing.progress } else { 0 }
                $speed = if ($status.processing -and $status.processing.speed.bytes -gt 0) { 
                    Format-Size -Bytes $status.processing.speed.bytes
                } else { "N/A" }
                
                $eta = if ($status.processing -and $status.processing.eta.seconds -gt 0) {
                    $etaTime = [TimeSpan]::FromSeconds($status.processing.eta.seconds)
                    $etaTime.ToString("hh\:mm\:ss")
                } else { "Calcul..." }
                
                Clear-Host
                Write-Host "Attente de la fin du téléchargement..." -ForegroundColor Cyan
                Write-Host "Appuyez sur Ctrl+C pour annuler l'attente"
                Write-Host ""
                Write-Host "Torrent: $($status.filename)"
                Write-Host "Statut: $($status.status)" -ForegroundColor Yellow
                Write-Host "Progression: $progress%" -ForegroundColor Green
                Write-Host "Vitesse: $speed/s"
                Write-Host "Temps restant: $eta"
                
                if ($progress -gt $lastProgress) {
                    $lastProgress = $progress
                }
                
                $lastUpdate = $currentTime
            }
            
            Start-Sleep -Milliseconds 500
        }
    }
    
    Pause
}

# Fonction utilitaire pour formater la taille des fichiers
function Format-Size {
    param (
        [Parameter(Mandatory=$true)]
        [double]$Bytes
    )
    
    if ($Bytes -lt 1KB) {
        return "$Bytes B"
    }
    elseif ($Bytes -lt 1MB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }
    elseif ($Bytes -lt 1GB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -lt 1TB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }
    else {
        return "{0:N2} TB" -f ($Bytes / 1TB)
    }
}

# Fonction pour supprimer les caractères invalides dans les noms de fichiers
function Remove-InvalidFileNameChars {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
    return ($Name -replace $re, '_')
}
function Write-Centered {
    param(
        [string]$Message
    )
    
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $messageLength = $Message.Length
    $padding = $consoleWidth / 2 - $messageLength / 2
    
    Write-Host ("{0}{1}" -f (' ' * [Math]::Floor($padding)), $Message)
}

# Interface simple pour l'entrée des liens (console)
function Show-Menu {
    Clear-Host
    Write-Centered " █████╗ ██╗     ██╗     ██████╗ ███████╗██████╗ ██████╗ ██╗██████╗ "
    Write-Centered "██╔══██╗██║     ██║     ██╔══██╗██╔════╝██╔══██╗██╔══██╗██║██╔══██╗"
    Write-Centered "███████║██║     ██║     ██║  ██║█████╗  ██████╔╝██████╔╝██║██║  ██║"
    Write-Centered "██╔══██║██║     ██║     ██║  ██║██╔══╝  ██╔══██╗██╔══██╗██║██║  ██║"
    Write-Centered "██║  ██║███████╗███████╗██████╔╝███████╗██████╔╝██║  ██║██║██████╔╝"
    Write-Centered "╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝ "

    Write-Centered "===== Alldebrid PowerShell Downloader =====" -ForegroundColor Cyan
    
    # Vérifier l'API au lancement
    <#$apiValid = Test-ApiValidity
    
    if (-not $apiValid) {
        Write-Host "`nLa clé API semble invalide. Veuillez vérifier la configuration." -ForegroundColor Red
        Pause
        exit
    }#>
    
    Write-Host "`n1. Mode rapide (interface graphique)"
    Write-Host "2. Télécharger un lien unique"
    Write-Host "3. Télécharger plusieurs liens"
    Write-Host "4. Télécharger depuis un fichier texte"
    Write-Host "5. Modifier le dossier de téléchargement"
    Write-Host "6. Lire directement avec VLC (streaming)"
    Write-Host "7. Gestionnaire de torrents"
    Write-Host "Q. Quitter"
    Write-Host "========================================"
    Write-Host "Dossier de téléchargement actuel: $script:currentDownloadFolder" -ForegroundColor Yellow
    Write-Host "========================================"
    
    $choice = Read-Host "Choisissez une option (1-7 Or Q)"
    
    switch ($choice) {
        "1" {
            # Lancer l'interface graphique
            Show-DownloadDialog
            Show-Menu
        }
        "2" {
            $link = Read-Host "Entrez le lien à débloquer"
            $category = Read-Host "Catégorie (facultatif, laissez vide si aucune)"
            Start-AlldebridDownload -Links @($link) -Category $category
            Pause
            Show-Menu
        }
        "3" {
            $links = @()
            Write-Host "Entrez les liens un par un. Tapez 'terminé' pour finir."
            
            do {
                $link = Read-Host "Lien (ou 'terminé')"
                if ($link -ne "terminé") {
                    $links += $link
                }
            } while ($link -ne "terminé")
            
            $category = Read-Host "Catégorie (facultatif, laissez vide si aucune)"
            Start-AlldebridDownload -Links $links -Category $category
            Pause
            Show-Menu
        }
        "4" {
            $filePath = Read-Host "Chemin du fichier contenant les liens (un par ligne)"
            
            if (Test-Path -Path $filePath) {
                $links = Get-Content -Path $filePath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                $category = Read-Host "Catégorie (facultatif, laissez vide si aucune)"
                Start-AlldebridDownload -Links $links -Category $category
            } else {
                Write-Host "Fichier introuvable!" -ForegroundColor Red
            }
            
            Pause
            Show-Menu
        }
        "5" {
            # Sélection du dossier de téléchargement avec Windows Forms
            Write-Host "Ouverture du sélecteur de dossier..." -ForegroundColor Cyan
            $selectedFolder = Select-Folder -Description "Choisissez le dossier de destination pour les téléchargements" -InitialDirectory $script:currentDownloadFolder
            
            if ($selectedFolder) {
                $script:currentDownloadFolder = $selectedFolder
                # Ne pas modifier l'emplacement du fichier de log
                Save-Config
                Write-Host "Nouveau dossier de téléchargement défini: $script:currentDownloadFolder" -ForegroundColor Green
            }
            
            Pause
            Show-Menu
        }
        "6" {
            $link = Read-Host "Entrez le lien à streamer avec VLC"
            $result = Start-VlcStreaming -Link $link
            
            if ($result) {
                Write-Host "Lecture lancée dans VLC. Profitez de votre vidéo!" -ForegroundColor Green
            } else {
                Write-Host "Échec du lancement de la lecture." -ForegroundColor Red
            }
            
            Pause
            Show-Menu
        }
        "7" {
            # Nouvelle option pour le gestionnaire de torrents
            Show-TorrentManager
            Show-Menu
        }
        
        "blyat" {
        Write-Host "☭ Gloire à la mère patrie !" -ForegroundColor Red

        # Télécharger l'hymne
        $anthemPath = "$env:TEMP\blyat.mp3"
        Invoke-WebRequest -Uri "https://github.com/Pooueto/blyatAnthem/raw/main/National_Anthem_of_USSR.mp3" -OutFile $anthemPath

        # Monter le volume (nécessite nircmd)
        $nircmdPath = "$env:TEMP\nircmd.exe"
        if (-not (Test-Path $nircmdPath)) {
            Invoke-WebRequest -Uri "https://www.nirsoft.net/utils/nircmd.zip" -OutFile "$env:TEMP\nircmd.zip"
            Expand-Archive "$env:TEMP\nircmd.zip" -DestinationPath "$env:TEMP"
        }
        Start-Process -FilePath $nircmdPath -ArgumentList "setsysvolume 65535"

        # Lire le MP3 avec Windows Media Player
        Start-Process -FilePath "wmplayer.exe" -ArgumentList $anthemPath
        }
        
        "Q" {
            Write-Host "Au revoir!" -ForegroundColor Cyan
            return
        }
        default {
            Write-Host "Option invalide. Veuillez réessayer." -ForegroundColor Red
            Pause
            Show-Menu
        }
    }
}

# ===== DÉMARRAGE DU SCRIPT =====

# Initialisation de la configuration
Initialize-Config

# Lancement du menu principal
Show-Menu