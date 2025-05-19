
#  ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗██████╗
#  ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
#  ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  ██████╔╝
#  ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  ██╔══██╗
#  ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗██║  ██║
#   ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

$LocalVersion = "3.0.2"

$RemoteScriptUrl = "https://raw.githubusercontent.com/Pooueto/Powershell/refs/heads/main/BetterAlldebrid.ps1"

try {
    $RemoteScript = Invoke-WebRequest -Uri $RemoteScriptUrl -UseBasicParsing
    if ($RemoteScript.StatusCode -eq 200) {
        if ($RemoteScript.Content -match '\$LocalVersion\s*=\s*\"([^\"]+)\"') {
            $RemoteVersion = $matches[1]
            if ([version]$RemoteVersion -gt [version]$LocalVersion) {
                Write-Host "Nouvelle version disponible ($RemoteVersion), mise à jour en cours..."
                Copy-Item -Path $MyInvocation.MyCommand.Definition -Destination "$env:TEMP\BetterAlldebridFriendAPI_backup.ps1"
                $RemoteScript.Content | Out-File -Encoding UTF8 -FilePath $MyInvocation.MyCommand.Definition -Force
                Write-Host "Mise à jour terminée. Relance du script..."
                Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -WindowStyle Hidden
                exit
            }
        }
    }
} catch {
    Write-Warning "Impossible de vérifier la version distante : $_"
}


#  ██╗      ██████╗  ██████╗ ██╗███╗   ██╗     ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗
#  ██║     ██╔═══██╗██╔════╝ ██║████╗  ██║    ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝
#  ██║     ██║   ██║██║  ███╗██║██╔██╗ ██║    ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
#  ██║     ██║   ██║██║   ██║██║██║╚██╗██║    ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
#  ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║    ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
#  ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝

# Entrez votre clé API ici
$predefinedApiKey = "geH6Zqg4EDxrYxBt5bLl"

# Au début du script
$currentProcess = [System.Diagnostics.Process]::GetCurrentProcess()
$currentProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::AboveNormal

[System.Net.ServicePointManager]::DefaultConnectionLimit = 20
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::UseNagleAlgorithm = $false

# Nombre maximal de tentatives en cas d'échec de téléchargement
$maxRetries = 3

# Nom d'agent pour les requêtes API
$userAgent = "BetterAlldebrid"


#   █████╗ ███████╗███████╗███████╗███╗   ███╗██████╗ ██╗     ██╗███████╗███████╗
#  ██╔══██╗██╔════╝██╔════╝██╔════╝████╗ ████║██╔══██╗██║     ██║██╔════╝██╔════╝
#  ███████║███████╗███████╗█████╗  ██╔████╔██║██████╔╝██║     ██║█████╗  ███████╗
#  ██╔══██║╚════██║╚════██║██╔══╝  ██║╚██╔╝██║██╔══██╗██║     ██║██╔══╝  ╚════██║
#  ██║  ██║███████║███████║███████╗██║ ╚═╝ ██║██████╔╝███████╗██║███████╗███████║
#  ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚══════╝

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Drawing


#   ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗     ███████╗██╗██╗     ███████╗
#  ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝     ██╔════╝██║██║     ██╔════╝
#  ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗    █████╗  ██║██║     █████╗
#  ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║    ██╔══╝  ██║██║     ██╔══╝
#  ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝    ██║     ██║███████╗███████╗
#   ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝     ╚═╝     ╚═╝╚══════╝╚══════╝

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


#  ██╗   ██╗████████╗██╗██╗     ███████╗
#  ██║   ██║╚══██╔══╝██║██║     ██╔════╝
#  ██║   ██║   ██║   ██║██║     ███████╗
#  ██║   ██║   ██║   ██║██║     ╚════██║
#  ╚██████╔╝   ██║   ██║███████╗███████║
#   ╚═════╝    ╚═╝   ╚═╝╚══════╝╚══════╝

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

function Start-SpeedTest {
    Write-Host "------------------------------------"
    Write-Host " Test de Vitesse Internet (Download) "
    Write-Host "------------------------------------" -ForegroundColor Green

    $testFiles = @(
        # --- Serveurs Français ---
        @{ Name = "OVH (France - proof.ovh.net) - 100 MiB";  Url = "https://proof.ovh.net/files/100Mb.dat";  SizeBytes = 100 * 1024 * 1024 },
        @{ Name = "OVH (France - proof.ovh.net) - 1 GiB";   Url = "https://proof.ovh.net/files/1Gb.dat";    SizeBytes = 1 * 1024 * 1024 * 1024 },
        @{ Name = "OVH (France - proof.ovh.net) - 10 GiB";  Url = "https://proof.ovh.net/files/10Gb.dat";   SizeBytes = 10 * 1024 * 1024 * 1024 },

        @{ Name = "Scaleway (France - Paris) - 100 MiB"; Url = "https://scaleway.testdebit.info/100M.iso"; SizeBytes = 100 * 1024 * 1024 },
        @{ Name = "Scaleway (France - Paris) - 1 GiB";   Url = "https://scaleway.testdebit.info/1G.iso";    SizeBytes = 1 * 1024 * 1024 * 1024 },
        @{ Name = "Scaleway (France - Paris) - 10 GiB";  Url = "https://scaleway.testdebit.info/10G.iso";    SizeBytes = 10 * 1024 * 1024 * 1024 },

        # --- Serveurs Européens (pour variété et fallback) ---
        @{ Name = "Tele2 (Europe - Anycast) - 100 MiB";  Url = "http://speedtest.tele2.net/100MB.zip";  SizeBytes = 100 * 1024 * 1024 },
        @{ Name = "Tele2 (Europe - Anycast) - 1 GiB";    Url = "http://speedtest.tele2.net/1GB.zip";    SizeBytes = 1 * 1024 * 1024 * 1024 },

        @{ Name = "ThinkBroadband (UK) - 50 MiB";   Url = "http://ipv4.download.thinkbroadband.com/50MB.zip";  SizeBytes = 50 * 1024 * 1024 },
        @{ Name = "ThinkBroadband (UK) - 200 MiB";  Url = "http://ipv4.download.thinkbroadband.com/200MB.zip"; SizeBytes = 200 * 1024 * 1024 },
        @{ Name = "ThinkBroadband (UK) - 512 MiB";  Url = "http://ipv4.download.thinkbroadband.com/512MB.zip"; SizeBytes = 512 * 1024 * 1024 }
    )

    Write-Host "`nChoisissez un serveur et une taille de fichier pour le test :"
    for ($i = 0; $i -lt $testFiles.Count; $i++) {
        # On ajuste l'affichage pour que les numéros correspondent à l'index + 1
        Write-Host "$($i+1). $($testFiles[$i].Name)"
    }

    $choiceInput = ""
    $selectedFile = $null

    while ($true) { # Boucle infinie jusqu'à un choix valide ou Quitter
        $choiceInput = Read-Host "`nEntrez le numéro de votre choix (1-$($testFiles.Count)), ou 'Q' pour quitter"

        if ($choiceInput -eq 'Q' -or $choiceInput -eq 'q') {
            Write-Host "Retour au menu principal..." -ForegroundColor Yellow
            return # Quitte la fonction Start-SpeedTest
        }

        try {
            $choiceInt = [int]$choiceInput
            if ($choiceInt -ge 1 -and $choiceInt -le $testFiles.Count) {
                $selectedFile = $testFiles[$choiceInt - 1]
                break # Sort de la boucle while, choix valide
            } else {
                Write-Warning "Choix invalide. Veuillez réessayer."
            }
        }
        catch {
            Write-Warning "Entrée invalide. Veuillez entrer un nombre ou 'Q'."
        }
    }

    # Si on arrive ici, $selectedFile est défini
    $fileUrl = $selectedFile.Url
    $fileSizeBytes = $selectedFile.SizeBytes

    Write-Host "`nTest en cours avec : $($selectedFile.Name)..." -ForegroundColor Yellow

    $tempFile = [System.IO.Path]::GetTempFileName()

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        Invoke-WebRequest -Uri $fileUrl -OutFile $tempFile -UseBasicParsing -TimeoutSec 300

        $stopwatch.Stop()
        $durationSeconds = $stopwatch.Elapsed.TotalSeconds

        if ($durationSeconds -eq 0) {
            Write-Error "Le téléchargement a été trop rapide ou a échoué (durée nulle)."
            # [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null # S'assurer de réinitialiser si utilisé
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
            return
        }

        $speedMbps = ($fileSizeBytes * 8) / $durationSeconds / 1000000

        Write-Host "------------------------------------" -ForegroundColor Green
        Write-Host " Résultat du Test de Vitesse" -ForegroundColor Green
        Write-Host "------------------------------------" -ForegroundColor Green
        Write-Host "Serveur/Fichier: $($selectedFile.Name)"
        Write-Host "Taille du fichier: $([math]::Round($fileSizeBytes / (1024*1024), 2)) MiB"
        Write-Host "Temps de téléchargement: $([math]::Round($durationSeconds, 2)) secondes"
        Write-Host "Vitesse de téléchargement: $([math]::Round($speedMbps, 2)) Mbps" -ForegroundColor Cyan
        Write-Host "------------------------------------"

    }
    catch {
        Write-Error "Une erreur est survenue pendant le test : $($_.Exception.Message)"
        if ($_.Exception.InnerException) {
            Write-Error "Détails de l'erreur interne : $($_.Exception.InnerException.Message)"
        }
        Write-Warning "Vérifiez votre connexion internet ou essayez un autre serveur/fichier."
        Write-Warning "L'URL testée était : $fileUrl"
    }
    finally {
        # [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}
function Write-Centered {
    param (
        [string]$Message,
        [ConsoleColor]$ForegroundColor = 'White'
    )
    $windowWidth = (Get-Host).UI.RawUI.WindowSize.Width
    $padding = ($windowWidth - $Message.Length) / 2
    if ($padding -lt 0) { $padding = 0 } # S'assurer que le padding n'est pas négatif pour les lignes très longues
    Write-Host (" " * [int]$padding + $Message) -ForegroundColor $ForegroundColor
}


#   █████╗ ██╗     ██╗     ██████╗ ███████╗██████╗ ██████╗ ██╗██████╗     ██╗   ██╗████████╗██╗██╗     ███████╗
#  ██╔══██╗██║     ██║     ██╔══██╗██╔════╝██╔══██╗██╔══██╗██║██╔══██╗    ██║   ██║╚══██╔══╝██║██║     ██╔════╝
#  ███████║██║     ██║     ██║  ██║█████╗  ██████╔╝██████╔╝██║██║  ██║    ██║   ██║   ██║   ██║██║     ███████╗
#  ██╔══██║██║     ██║     ██║  ██║██╔══╝  ██╔══██╗██╔══██╗██║██║  ██║    ██║   ██║   ██║   ██║██║     ╚════██║
#  ██║  ██║███████╗███████╗██████╔╝███████╗██████╔╝██║  ██║██║██████╔╝    ╚██████╔╝   ██║   ██║███████╗███████║
#  ╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝      ╚═════╝    ╚═╝   ╚═╝╚══════╝╚══════╝

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

            # Configuration optimisée des requêtes web
            $webRequest = [System.Net.HttpWebRequest]::Create($Url)
            $webRequest.Headers.Add("Range", "bytes=$startPosition-")
            $webRequest.Method = "GET"
            $webRequest.UserAgent = $userAgent

            # Optimisations pour la vitesse
            $webRequest.KeepAlive = $true
            $webRequest.Pipelined = $true
            $webRequest.AllowAutoRedirect = $true
            $webRequest.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
            $webRequest.Timeout = 30000 # 30 secondes
            $webRequest.ReadWriteTimeout = 300000 # 5 minutes

            # Augmenter le nombre maximum de connexions concurrentes vers un même serveur
            [System.Net.ServicePointManager]::DefaultConnectionLimit = 10
            [System.Net.ServicePointManager]::Expect100Continue = $false

            $response = $webRequest.GetResponse()
            $totalLength = $response.ContentLength + $startPosition
            $responseStream = $response.GetResponseStream()

            $mode = if ($startPosition -gt 0) { "Append" } else { "Create" }
            $fileStream = New-Object IO.FileStream($tempFilePath, $mode)

            # Augmenter la taille du buffer pour de meilleures performances
            $buffer = New-Object byte[] 16MB
            $totalBytesRead = $startPosition
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $lastUpdateTime = Get-Date
            $lastBytesRead = $totalBytesRead
            $updateInterval = 2 # Mettre à jour l'affichage toutes les 2 secondes au lieu de chaque seconde

            # Boucle de téléchargement
            while ($true) {
                $bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)

                if ($bytesRead -eq 0) {
                    break
                }

                $fileStream.Write($buffer, 0, $bytesRead)
                $totalBytesRead += $bytesRead

                # Mise à jour de la progression moins fréquemment
                $currentTime = Get-Date
                $elapsedSeconds = ($currentTime - $lastUpdateTime).TotalSeconds

                if ($elapsedSeconds -ge $updateInterval) {
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
            $fileStream.Flush()
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

function Get-AlldebridHistory {
    param (
        [string]$ApiKey = $predefinedApiKey,
        [string]$Agent = $userAgent
    )

    Write-Log "Récupération de l'historique des liens débridés..."

    $apiUrl = "https://api.alldebrid.com/v4/user/history?agent=$Agent&apikey=$ApiKey"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get

        if ($response.status -eq "success") {
            Write-Log "Historique récupéré avec succès."

            if ($response.data.links -and $response.data.links.Count -gt 0) {
                Write-Host "`n===== Historique des liens débridés =====" -ForegroundColor Cyan
                foreach ($linkEntry in $response.data.links) {
                    Write-Host "Lien original: $($linkEntry.link)"
                    Write-Host "Lien débridé: $($linkEntry.unlockedLink)"
                    Write-Host "Nom du fichier: $($linkEntry.filename)"
                    Write-Host "Date: $($linkEntry.addedDate)"
                    Write-Host "-------------------------------------"
                }
                 Write-Host "===== Fin de l'historique =====" -ForegroundColor Cyan
            } else {
                Write-Host "Aucun lien débridé trouvé dans l'historique." -ForegroundColor Yellow
            }

        } else {
            Write-Log "Erreur lors de la récupération de l'historique: $($response.error.message)"
             Write-Host "Erreur lors de la récupération de l'historique: $($response.error.message)" -ForegroundColor Red
        }
    } catch {
        Write-Log "Exception lors de l'appel à l'API pour l'historique: $_"
        Write-Host "Une erreur est survenue lors de la récupération de l'historique." -ForegroundColor Red
    }
}


#  ███████╗ ██████╗ ██████╗ ███╗   ███╗    ██╗   ██╗██╗
#  ██╔════╝██╔═══██╗██╔══██╗████╗ ████║    ██║   ██║██║
#  █████╗  ██║   ██║██████╔╝██╔████╔██║    ██║   ██║██║
#  ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║    ██║   ██║██║
#  ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║    ╚██████╔╝██║
#  ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝     ╚═════╝ ╚═╝

# Interface graphique pour l'entrée des liens
function Show-DownloadDialog {
    # Configuration principale de la fenêtre
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "BetterAlldebrid Downloader" # Titre de la fenêtre
    $form.Size = New-Object System.Drawing.Size(700, 620) # Taille de la fenêtre (augmentée pour le GIF plus grand)
    $form.StartPosition = "CenterScreen" # Position au centre de l'écran
    $form.FormBorderStyle = "FixedSingle" # Empêche le redimensionnement
    $form.MaximizeBox = $false # Désactive le bouton maximiser
    $form.MinimizeBox = $true # Active le bouton minimiser
    $form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F0F0F0") # Couleur de fond claire
    $font = New-Object System.Drawing.Font("Segoe UI", 9) # Police par défaut
    $form.Font = $font

    # TableLayoutPanel principal pour la disposition générale des éléments majeurs
    $tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $tableLayoutPanel.Dock = "Fill" # Remplit la fenêtre parente
    $tableLayoutPanel.ColumnCount = 1 # Une seule colonne pour empiler les GroupBoxes, le label et le bouton
    $tableLayoutPanel.RowCount = 4 # Rangée pour GroupBox Liens, Rangée pour GroupBox Options, Rangée pour Statut, Rangée pour Bouton Télécharger

    # Styles des colonnes (100% pour la seule colonne)
    $tableLayoutPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100)))

    # Styles des rangées (pour répartir l'espace verticalement)
    $tableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 60))) # GroupBox "Liens et Catégorie" (prend 60% de l'espace restant)
    $tableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) # GroupBox "Options et Actions" (prend 20% de l'espace restant)
    $tableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 30))) # Label de statut (hauteur fixe de 30 pixels)
    $tableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 55))) # Bouton "Télécharger" (hauteur fixe de 55 pixels)

    $tableLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(15) # Marge intérieure pour l'espace autour des éléments
    $tableLayoutPanel.CellBorderStyle = "None" # Pas de bordures entre les cellules
    $form.Controls.Add($tableLayoutPanel) # Ajoute le TableLayoutPanel à la fenêtre

    # --- GroupBox pour les liens et la catégorie ---
    $groupBoxLinks = New-Object System.Windows.Forms.GroupBox
    $groupBoxLinks.Text = "Liens de Téléchargement et Catégorie" # Titre du groupe
    $groupBoxLinks.Dock = "Fill" # Remplit l'espace alloué dans le TableLayoutPanel principal
    $groupBoxLinks.Padding = New-Object System.Windows.Forms.Padding(10) # Espacement interne

    # TableLayoutPanel interne pour organiser les contrôles dans le GroupBox "Links"
    $innerTableLinks = New-Object System.Windows.Forms.TableLayoutPanel
    $innerTableLinks.Dock = "Fill" # Remplit le GroupBox
    $innerTableLinks.ColumnCount = 2 # Colonne 1: Texte (Liens, Catégorie), Colonne 2: Bouton Coller + GIF
    $innerTableLinks.RowCount = 5 # Rangée 1: Label liens, Rangée 2: Textbox liens, Rangée 3: Espace pour GIF, Rangée 4: Label catégorie, Rangée 5: Textbox catégorie

    $innerTableLinks.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 75))) # Colonne principale (75%)
    $innerTableLinks.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 25))) # Colonne pour le bouton Coller et le GIF (25%)

    $innerTableLinks.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 25))) # Label liens (hauteur fixe)
    $innerTableLinks.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) # Textbox liens (prend le reste de l'espace vertical)
    $innerTableLinks.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 150))) # Nouvelle rangée pour le GIF (hauteur augmentée)
    $innerTableLinks.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 25))) # Label catégorie (hauteur fixe)
    $innerTableLinks.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 30))) # Textbox catégorie (hauteur fixe)

    $groupBoxLinks.Controls.Add($innerTableLinks) # Ajoute le TableLayoutPanel interne au GroupBox

    # Label "Collez vos liens"
    $labelLinks = New-Object System.Windows.Forms.Label
    $labelLinks.Text = "Collez vos liens (un par ligne) avec CTRL/ENTER:"
    $labelLinks.AutoSize = $true # Ajuste la taille automatiquement
    $innerTableLinks.Controls.Add($labelLinks, 0, 0) # Col 0, Row 0
    $innerTableLinks.SetColumnSpan($labelLinks, 2) # S'étend sur les deux colonnes

    # Zone de texte multi-lignes pour les liens
    $textBoxLinks = New-Object System.Windows.Forms.TextBox
    $textBoxLinks.Multiline = $true # Permet plusieurs lignes
    $textBoxLinks.ScrollBars = "Vertical" # Ajoute une barre de défilement verticale si nécessaire
    $textBoxLinks.Dock = "Fill" # Remplit l'espace alloué
    $innerTableLinks.Controls.Add($textBoxLinks, 0, 1) # Col 0, Row 1
    $innerTableLinks.SetRowSpan($textBoxLinks, 2)

    # Bouton "Coller"
    $buttonPaste = New-Object System.Windows.Forms.Button
    $buttonPaste.Text = "Coller"
    $buttonPaste.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#00A0B0") # Couleur vive
    $buttonPaste.ForeColor = [System.Drawing.Color]::White # Texte blanc
    $buttonPaste.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Style plat
    $buttonPaste.FlatAppearance.BorderSize = 0 # Pas de bordure
    $buttonPaste.Cursor = [System.Windows.Forms.Cursors]::Hand # Curseur main au survol
    $buttonPaste.Dock = "Top" # Ancré en haut pour s'aligner avec le haut de la textbox
    $buttonPaste.Margin = New-Object System.Windows.Forms.Padding(5,0,0,0) # Petite marge à gauche et pas de marge en haut
    $buttonPaste.Add_Click({
        # Action au clic : coller le contenu du presse-papiers
        if ([System.Windows.Forms.Clipboard]::ContainsText()) {
            $textBoxLinks.Text = [System.Windows.Forms.Clipboard]::GetText()
            $statusLabel.Text = "Contenu du presse-papiers collé."
            $statusLabel.ForeColor = [System.Drawing.Color]::Gray
        } else {
            $statusLabel.Text = "Le presse-papiers est vide ou ne contient pas de texte."
            $statusLabel.ForeColor = [System.Drawing.Color]::OrangeRed
        }
    })
    $innerTableLinks.Controls.Add($buttonPaste, 1, 1) # Col 1, Row 1 (à côté de la textbox des liens)

    # --- PictureBox pour le GIF ---
    $pictureBoxGif = New-Object System.Windows.Forms.PictureBox
    $pictureBoxGif.Dock = "Fill" # Remplit l'espace de la cellule
    $pictureBoxGif.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom # Redimensionne l'image pour tenir dans le contrôle

    $pictureBoxGif.Add_Click({
    # Ici commence le code de la commande "blyat"
    Write-Host "☭ Gloire à la mère patrie !" -ForegroundColor Red

    # Liste des hymnes possibles
    $anthems = @(
        "https://github.com/Pooueto/blyatAnthem/raw/main/National_Anthem_of_USSR.mp3",
        "https://github.com/Pooueto/blyatAnthem/raw/main/tachanka_kalinka.mp4"
    )

    # Sélectionner une URL d'hymne aléatoire
    $randomIndex = Get-Random -Maximum $anthems.Count
    $selectedAnthemUrl = $anthems[$randomIndex]

    Write-Host "Playing: $selectedAnthemUrl" -ForegroundColor Yellow

    # Déterminer l'extension du fichier pour choisir le lecteur approprié
    $fileExtension = [System.IO.Path]::GetExtension($selectedAnthemUrl)

    # Télécharger l'hymne sélectionné
    $anthemPath = "$env:TEMP\blyat_anthem$fileExtension"
    try {
        Invoke-WebRequest -Uri $selectedAnthemUrl -OutFile $anthemPath -UseBasicParsing
    } catch {
        Write-Host "Error downloading anthem from $selectedAnthemUrl $($_.Exception.Message)" -ForegroundColor Red
        # Pas de "Pause" ni "Show-Menu" ici, l'interface graphique reste active.
        [System.Windows.Forms.MessageBox]::Show("Erreur lors du téléchargement de l'hymne.", "Erreur Blyat", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return # Sortie du gestionnaire de clic en cas d'erreur
    }


    # Augmenter le volume (nécessite nircmd)
    $nircmdPath = "$env:TEMP\nircmd.exe"
    if (-not (Test-Path $nircmdPath)) {
        try {
            Invoke-WebRequest -Uri "https://www.nirsoft.net/utils/nircmd.zip" -OutFile "$env:TEMP\nircmd.zip"
            Expand-Archive "$env:TEMP\nircmd.zip" -DestinationPath "$env:TEMP" -Force
            Write-Host "nircmd downloaded and extracted." -ForegroundColor Green
        } catch {
            Write-Host "Error downloading or extracting nircmd: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Volume may not be set." -ForegroundColor Yellow
        }
    }
    if (Test-Path $nircmdPath) {
        try {
            Start-Process -FilePath $nircmdPath -ArgumentList "setsysvolume 65535" -WindowStyle Hidden -ErrorAction Stop
            Write-Host "Volume set to maximum." -ForegroundColor Green
        } catch {
            Write-Host "Error setting volume with nircmd: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Volume may not be set." -ForegroundColor Yellow
        }
    } else {
        Write-Host "nircmd not found. Volume not set." -ForegroundColor Yellow
    }


    # Jouer le fichier téléchargé
    try {
        # Utilise le lecteur par défaut pour le type de fichier
        Start-Process -FilePath $anthemPath
    } catch {
        Write-Host "Error playing anthem file '$anthemPath': $($_.Exception.Message)" -ForegroundColor Red
    }

    # Changer le fond d'écran
    $wallpaperUrl = "https://raw.githubusercontent.com/Pooueto/blyatAnthem/main/Flag_of_the_Soviet_Union.png"
    $wallpaperFileName = $wallpaperUrl.Split('/')[-1] # Extrait le nom de fichier de l'URL
    $wallpaperPath = Join-Path $env:TEMP $wallpaperFileName

    try {
        Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath -UseBasicParsing
        Set-DesktopWallpaper -ImagePath $wallpaperPath

    } catch {
        Write-Host "Erreur lors du téléchargement ou de la configuration du fond d'écran: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Changer le titre de la fenêtre console (visible derrière la GUI)
    $Host.UI.RawUI.WindowTitle = "Слава Родине ! ☭"
    Write-Host "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                            ⢀⣀⣀⣀⣤⣤⣴⣶⣶⣶⣶⣶⣶⣶⣤⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣴⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⢠⣿⣿⣿⣿⣿⡏⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠉⣠⡿⢻⣿⡿⢿⣿⠟⠙⣿⣙⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⢸⡿⣿⢻⠏⠻⠁⢸⠛⣿⣿⣿⣿⣿⣿⣿⣿⡏⣴⣠⣾⣯⣽⡶⠀⣤⠘⢁⣀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀
            ⠀⠀⠀⢸⣧⡀⠀⠀⠀⢠⣿⣦⣽⣻⢻⣿⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⡿⢣⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀
            ⠀⠀⠀⣾⣟⠃⠀⠀⠘⣿⣟⣿⣿⣿⣾⣿⢸⣿⣿⣿⠛⠛⢿⣿⣿⡿⠿⠋⠀⢀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀
            ⠀⠀⠀⣿⣿⣿⠆⠀⠀⠙⠙⠿⠟⠉⠟⠁⠙⠋⠈⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠈⠁⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
            ⠀⠀⠀⢹⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
            ⠀⠀⠀⠠⢯⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
            ⠀⠀⠀⠀⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢬⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
            ⠀⠀⠀⠘⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
            ⠀⠀⢀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣬⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
            ⠀⠀⢸⣿⣿⣷⣄⡀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣴⣶⣿⣿⣷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
            ⠀⠀⠈⢇⣀⣙⣻⣿⣷⡆⠀⠀⠀⠚⠻⣿⣭⡀⠀⠀⠀⠈⠙⠿⣷⣤⠀⠀⠀⠀⠀⠀⠀⢲⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀⠀
            ⠀⠀⠀⠸⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⣼⣿⣿⣿⣷⡶⢤⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⠿⠛⠉⠉⠉⠻⣿⣿⡿⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⠀⢸⣿⡿⠁⠀⠀⠀⠀⠀⠀⢹⣿⣿⠋⠁⠀⠀⠙⢦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢻⡿⠁⠀⠀⣴⡇⠙⣦⢸⣿⠇⠀⠀⠀⠀
            ⠀⠀⠀⠀⢀⣠⣾⣿⠃⠀⠀⠀⠀⠀⠀⠀⠈⠉⠻⠷⠶⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⣼⣁⠀⠀⢸⢸⡏⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⢸⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠋⢻⣿⠀⠟⢸⠃⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⢉⡏⠀⠀⠀⠀⠀⠀⠀⠀⢠⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⣡⣿⠁⢀⡎⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⣾⡇⠀⠀⠀⠀⢀⣀⢀⣀⡀⢻⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠒⠒⠉⠁⠀⡼⠁⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⢸⣿⣿⣦⣶⣦⣀⡈⠉⠉⠉⠀⠀⠙⢿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡼⠁⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⢈⣿⣿⣿⣿⣿⣿⣿⣿⣶⣄⣀⡀⠀⠀⠙⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣇⠀⠀⣠⡞⠁⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠿⠖⠚⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠉⢻⣿⣿⡿⠿⠛⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⢻⣿⣤⣶⣾⣿⣿⣭⡙⠛⠛⠿⠿⣿⣿⣿⣿⣿⡿⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⠘⣿⡛⠛⠙⠛⠛⠛⠻⠷⠀⠀⠀⠀⠀⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⣴⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⠀⠹⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⠀⠀⠀⠑⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣶⣶⣤⣤⣤⣄⣀⣠⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀
            ⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣟⣛⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⡄
            ⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
            ⠀⠀⣀⣤⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠛⢿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
            ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⠙⠛⠻⢿⠟⠓⠀⠀⢀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
            ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣀⠀⢀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡃
            ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁
            ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀
            ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀
            ⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡃
            ⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
            ⠀⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠇" -ForegroundColor Red

    # Message final en MessageBox (remplace Pause et Show-Menu)
    [System.Windows.Forms.MessageBox]::Show("Camarade, your downloads will be glorious!, For the Motherland!", "Gloire à la Mère Patrie!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

    # On ne ferme pas la fenêtre ici si vous souhaitez qu'elle reste ouverte.
    # Si vous voulez qu'elle se ferme après le message, décommentez la ligne ci-dessous:
    # $script:form.Close()
})

    # Chemin où le GIF sera temporairement sauvegardé
    $gifLocalPath = Join-Path ([System.IO.Path]::GetTempPath()) "alldebrid_paste_gif.gif"

    try {
        # URL du GIF sur le dépôt GitHub (remplacez par l'URL de votre GIF)
        # Assurez-vous que c'est l'URL RAW du fichier sur GitHub
        $gifUrl = "https://raw.githubusercontent.com/Pooueto/ascci-art/main/urssCat.gif" # Exemple d'URL RAW

        # Télécharger le GIF
        $webClient = New-Object System.Net.WebClient
        $gifBytes = $webClient.DownloadData($gifUrl)

        if ($null -ne $gifBytes -and $gifBytes.Length -gt 0) {
            # Sauvegarder le GIF localement
            [System.IO.File]::WriteAllBytes($gifLocalPath, $gifBytes)

            # Charger l'image depuis le fichier local
            # Utiliser FromFile permet à GDI+ de gérer le fichier directement
            $pictureBoxGif.Image = [System.Drawing.Image]::FromFile($gifLocalPath)

            # Optionnel : Supprimer le fichier temporaire après le chargement
            # Remove-Item $gifLocalPath -Force -ErrorAction SilentlyContinue

        } else {
            Write-Host "Erreur lors du chargement du GIF : Les données téléchargées sont vides ou nulles." -ForegroundColor Red
            $pictureBoxGif.Visible = $false # Cacher la PictureBox si les données sont vides
        }

    } catch {
        Write-Host "Erreur lors du chargement du GIF depuis GitHub/local : $($_.Exception.Message)" -ForegroundColor Red
        # Cacher la PictureBox en cas d'erreur de chargement
        $pictureBoxGif.Visible = $false
        # Assurez-vous que le fichier temporaire est supprimé même en cas d'erreur
        if (Test-Path $gifLocalPath) {
             Remove-Item $gifLocalPath -Force -ErrorAction SilentlyContinue
        }
    }

    $innerTableLinks.Controls.Add($pictureBoxGif, 1, 2) # Col 1, Row 2 (sous le bouton Coller)
    # --- Fin PictureBox GIF ---


    # Label pour la catégorie
    $labelCategory = New-Object System.Windows.Forms.Label
    $labelCategory.Text = "Catégorie (facultatif):"
    $labelCategory.AutoSize = $true
    $innerTableLinks.Controls.Add($labelCategory, 0, 3) # Col 0, Row 3 (ajusté à cause de la nouvelle rangée pour le GIF)
    $innerTableLinks.SetColumnSpan($labelCategory, 2) # S'étend sur les deux colonnes

    # Textbox pour la catégorie
    $textBoxCategory = New-Object System.Windows.Forms.TextBox
    $textBoxCategory.Anchor = "Left, Right" # Ancré à gauche et à droite pour s'adapter à la largeur
    $innerTableLinks.Controls.Add($textBoxCategory, 0, 4) # Col 0, Row 4 (ajusté)
    $innerTableLinks.SetColumnSpan($textBoxCategory, 2) # S'étend sur les deux colonnes

    # Ajoute le GroupBox "Links" au TableLayoutPanel principal
    $tableLayoutPanel.Controls.Add($groupBoxLinks, 0, 0)


    # --- GroupBox pour les options et actions ---
    $groupBoxActions = New-Object System.Windows.Forms.GroupBox
    $groupBoxActions.Text = "Options et Actions" # Titre du groupe
    $groupBoxActions.Dock = "Fill" # Remplit l'espace alloué dans le TableLayoutPanel principal
    $groupBoxActions.Padding = New-Object System.Windows.Forms.Padding(10) # Espacement interne

    # TableLayoutPanel interne pour organiser les contrôles dans le GroupBox "Actions"
    $innerTableActions = New-Object System.Windows.Forms.TableLayoutPanel
    $innerTableActions.Dock = "Fill" # Remplit le GroupBox
    $innerTableActions.ColumnCount = 3 # Colonnes pour Changer dossier, Ouvrir dossier, Vider liens
    $innerTableActions.RowCount = 2 # Rangée 1: Label dossier, Rangée 2: Boutons

    # Styles des colonnes ajustés pour donner un peu plus d'espace aux boutons
    $innerTableActions.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30))) # 30% de la largeur pour le bouton "Changer dossier"
    $innerTableActions.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 40))) # 40% de la largeur pour le bouton "Ouvrir dossier" (celui du milieu)
    $innerTableActions.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30))) # 30% de la largeur pour le bouton "Vider liens"

    $innerTableActions.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 25))) # Label dossier actuel (hauteur fixe)
    $innerTableActions.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) # Ligne des boutons (prend le reste de l'espace)

    $groupBoxActions.Controls.Add($innerTableActions) # Ajoute le TableLayoutPanel interne au GroupBox

    # Label pour afficher le dossier actuel
    $labelFolder = New-Object System.Windows.Forms.Label
    $labelFolder.Text = "Dossier: $script:currentDownloadFolder"
    $labelFolder.AutoSize = $true
    $innerTableActions.Controls.Add($labelFolder, 0, 0) # Col 0, Row 0
    $innerTableActions.SetColumnSpan($labelFolder, 3) # S'étend sur les 3 colonnes

    # Bouton "Changer le dossier"
    $buttonFolder = New-Object System.Windows.Forms.Button
    $buttonFolder.Text = "Changer dossier"
    $buttonFolder.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0078D4") # Bleu Windows
    $buttonFolder.ForeColor = [System.Drawing.Color]::White
    $buttonFolder.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Style plat
    $buttonFolder.FlatAppearance.BorderSize = 0 # Pas de bordure
    $buttonFolder.Cursor = [System.Windows.Forms.Cursors]::Hand # Curseur main au survol
    $buttonFolder.Dock = "Fill" # Remplit l'espace de la cellule
    $buttonFolder.Margin = New-Object System.Windows.Forms.Padding(5) # Ajoute des marges autour du bouton
    $buttonFolder.Add_Click({
        # Action au clic : ouvrir la boîte de dialogue de sélection de dossier
        $selectedFolder = Select-Folder -Description "Choisissez le dossier de destination pour les téléchargements" -InitialDirectory $script:currentDownloadFolder
        if ($selectedFolder) {
            $script:currentDownloadFolder = $selectedFolder
            Save-Config # Sauvegarde le nouveau dossier dans la configuration
            $labelFolder.Text = "Dossier: $script:currentDownloadFolder" # Met à jour le label
            $statusLabel.Text = "Dossier de téléchargement mis à jour."
            $statusLabel.ForeColor = [System.Drawing.Color]::Green
        }
    })
    $innerTableActions.Controls.Add($buttonFolder, 0, 1) # Col 0, Row 1

    # Bouton "Ouvrir dossier"
    $buttonOpenFolder = New-Object System.Windows.Forms.Button
    $buttonOpenFolder.Text = "Ouvrir dossier"
    $buttonOpenFolder.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50") # Vert
    $buttonOpenFolder.ForeColor = [System.Drawing.Color]::White
    $buttonOpenFolder.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Style plat
    $buttonOpenFolder.FlatAppearance.BorderSize = 0 # Pas de bordure
    $buttonOpenFolder.Cursor = [System.Windows.Forms.Cursors]::Hand # Curseur main au survol
    $buttonOpenFolder.Dock = "Fill" # Remplit l'espace de la cellule
    $buttonOpenFolder.Margin = New-Object System.Windows.Forms.Padding(5) # Ajoute des marges
    $buttonOpenFolder.Add_Click({
        # Action au clic : ouvrir le dossier de téléchargement actuel dans l'explorateur
        if (Test-Path -Path $script:currentDownloadFolder) {
            Invoke-Item $script:currentDownloadFolder
            $statusLabel.Text = "Dossier de téléchargement ouvert."
            $statusLabel.ForeColor = [System.Drawing.Color]::Gray
        } else {
            $statusLabel.Text = "Le dossier de téléchargement n'existe pas."
            $statusLabel.ForeColor = [System.Drawing.Color]::OrangeRed
        }
    })
    $innerTableActions.Controls.Add($buttonOpenFolder, 1, 1) # Col 1, Row 1

    # Bouton "Vider les liens"
    $buttonClear = New-Object System.Windows.Forms.Button
    $buttonClear.Text = "Vider liens"
    $buttonClear.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#666666") # Gris foncé
    $buttonClear.ForeColor = [System.Drawing.Color]::White
    $buttonClear.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Style plat
    $buttonClear.FlatAppearance.BorderSize = 0 # Pas de bordure
    $buttonClear.Cursor = [System.Windows.Forms.Cursors]::Hand # Curseur main au survol
    $buttonClear.Dock = "Fill" # Remplit l'espace de la cellule
    $buttonClear.Margin = New-Object System.Windows.Forms.Padding(5) # Ajoute des marges
    $buttonClear.Add_Click({
        # Action au clic : effacer le contenu de la zone de texte des liens
        $textBoxLinks.Clear()
        $statusLabel.Text = "Zone de liens vidée."
        $statusLabel.ForeColor = [System.Drawing.Color]::Gray
    })
    $innerTableActions.Controls.Add($buttonClear, 2, 1) # Col 2, Row 1

    # Ajoute le GroupBox "Actions" au TableLayoutPanel principal
    $tableLayoutPanel.Controls.Add($groupBoxActions, 0, 1)


    # Label de statut/feedback (placé directement sur le TableLayoutPanel principal)
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "Prêt." # Texte initial
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic) # Police italique
    $statusLabel.ForeColor = [System.Drawing.Color]::Gray # Couleur grise
    $statusLabel.Dock = "Fill" # Remplit l'espace
    $statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter # Centre le texte
    $tableLayoutPanel.Controls.Add($statusLabel, 0, 2) # Col 0, Row 2


    # Bouton de téléchargement principal (placé directement sur le TableLayoutPanel principal)
    $buttonDownload = New-Object System.Windows.Forms.Button
    $buttonDownload.Text = "Télécharger" # Texte du bouton
    $buttonDownload.Size = New-Object System.Drawing.Size(140, 35) # Taille suggérée
    $buttonDownload.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0078D4") # Bleu Windows
    $buttonDownload.ForeColor = [System.Drawing.Color]::White # Texte blanc
    $buttonDownload.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Style plat
    $buttonDownload.FlatAppearance.BorderSize = 0 # Pas de bordure
    $buttonDownload.Cursor = [System.Windows.Forms.Cursors]::Hand # Curseur main au survol
    $buttonDownload.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) # Police en gras
    $buttonDownload.Dock = "Fill" # Remplit l'espace de la cellule
    $buttonDownload.Margin = New-Object System.Windows.Forms.Padding(10, 5, 10, 5) # Marge autour du bouton
    $buttonDownload.Add_Click({
        # Action au clic : lancer le processus de téléchargement
        $links = $textBoxLinks.Text -split "`r`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } # Récupère les liens (un par ligne)

        if ($links.Count -eq 0) {
            $statusLabel.Text = "Veuillez entrer au moins un lien."
            $statusLabel.ForeColor = [System.Drawing.Color]::Red
            return # Sortie si aucun lien n'est entré
        }

        # --- Désactiver tous les contrôles interactifs pendant le téléchargement ---
        $textBoxLinks.Enabled = $false
        $textBoxCategory.Enabled = $false
        $buttonFolder.Enabled = $false
        $buttonOpenFolder.Enabled = $false
        $buttonClear.Enabled = $false
        $buttonPaste.Enabled = $false
        $buttonDownload.Enabled = $false
        $statusLabel.Text = "Téléchargement en cours... Veuillez patienter."
        $statusLabel.ForeColor = [System.Drawing.Color]::Blue

        # Important : Permettre à l'UI de se rafraîchir et d'afficher les changements d'état
        # avant de lancer la tâche potentiellement longue.
        [System.Windows.Forms.Application]::DoEvents()

        # Démarrer le téléchargement (cette fonction bloque l'UI si elle est longue)
        Start-AlldebridDownload -Links $links -Category $textBoxCategory.Text

        # --- Réactiver les contrôles après la fin du téléchargement ---
        $textBoxLinks.Enabled = $true
        $textBoxCategory.Enabled = $true
        $buttonFolder.Enabled = $true
        $buttonOpenFolder.Enabled = $true
        $buttonClear.Enabled = $true
        $buttonPaste.Enabled = $true
        $buttonDownload.Enabled = $true

        # Mettre à jour le statut final
        $statusLabel.Text = "Opération terminée. Consultez les logs pour plus de détails."
        $statusLabel.ForeColor = [System.Drawing.Color]::Green

        # Afficher un message de fin à l'utilisateur
        [System.Windows.Forms.MessageBox]::Show("Opération terminée. Consultez les logs pour plus de détails.", "Téléchargement terminé", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    })
    $tableLayoutPanel.Controls.Add($buttonDownload, 0, 3) # Col 0, Row 3

    # Définir le bouton de téléchargement comme bouton par défaut (press Enter to activate)
    $form.AcceptButton = $buttonDownload

    # Centrer la fenêtre lors de l'affichage et l'activer
    $form.Add_Shown({$form.Activate()})

    # Afficher la fenêtre et attendre qu'elle soit fermée
    $form.ShowDialog() | Out-Null
}



#  ██╗   ██╗██╗      ██████╗     ██████╗ ██████╗ ███╗   ██╗███████╗
#  ██║   ██║██║     ██╔════╝    ██╔════╝██╔═══██╗████╗  ██║██╔════╝
#  ██║   ██║██║     ██║         ██║     ██║   ██║██╔██╗ ██║█████╗
#  ╚██╗ ██╔╝██║     ██║         ██║     ██║   ██║██║╚██╗██║██╔══╝
#   ╚████╔╝ ███████╗╚██████╗    ╚██████╗╚██████╔╝██║ ╚████║██║
#    ╚═══╝  ╚══════╝ ╚═════╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝

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


#  ████████╗ ██████╗ ██████╗ ██████╗ ███████╗███╗   ██╗████████╗     ██████╗ ███████╗███████╗████████╗██╗ ██████╗ ███╗   ██╗
#  ╚══██╔══╝██╔═══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║╚══██╔══╝    ██╔════╝ ██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
#     ██║   ██║   ██║██████╔╝██████╔╝█████╗  ██╔██╗ ██║   ██║       ██║  ███╗█████╗  ███████╗   ██║   ██║██║   ██║██╔██╗ ██║
#     ██║   ██║   ██║██╔══██╗██╔══██╗██╔══╝  ██║╚██╗██║   ██║       ██║   ██║██╔══╝  ╚════██║   ██║   ██║██║   ██║██║╚██╗██║
#     ██║   ╚██████╔╝██║  ██║██║  ██║███████╗██║ ╚████║   ██║       ╚██████╔╝███████╗███████║   ██║   ██║╚██████╔╝██║ ╚████║
#     ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝        ╚═════╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝

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
        Write-Host "----|--------------+-------------+-------------------------"

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


#  ███████╗ █████╗ ███████╗████████╗███████╗██████╗     ███████╗ ██████╗  ██████╗ ███████╗
#  ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗    ██╔════╝██╔════╝ ██╔════╝ ██╔════╝
#  █████╗  ███████║███████╗   ██║   █████╗  ██████╔╝    █████╗  ██║  ███╗██║  ███╗███████╗
#  ██╔══╝  ██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗    ██╔══╝  ██║   ██║██║   ██║╚════██║
#  ███████╗██║  ██║███████║   ██║   ███████╗██║  ██║    ███████╗╚██████╔╝╚██████╔╝███████║
#  ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝

function Set-DesktopWallpaper {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ImagePath
    )

    # Vérifier si le fichier image existe
    if (-not (Test-Path -Path $ImagePath -PathType Leaf)) {
        Write-Log "Erreur: Le fichier image spécifié '$ImagePath' est introuvable." -NoConsole
        Write-Host "Erreur: Le fichier image spécifié est introuvable." -ForegroundColor Red
        return
    }

    # Chemin de la clé de registre pour le fond d'écran
    $regKey = "HKCU:\Control Panel\Desktop"

    try {
        # Définir la valeur du registre pour le fond d'écran
        Set-ItemProperty -Path $regKey -Name WallPaper -Value $ImagePath

        # Optionnel: Définir le style du fond d'écran (Tile, Center, Stretch, Fit, Fill)
        # 0: Tile, 1: Center, 2: Stretch, 6: Fit, 10: Fill
        # On règle sur 2 pour "Stretch" (Full) comme demandé
        Set-ItemProperty -Path $regKey -Name WallpaperStyle -Value 2 # Stretch
        Set-ItemProperty -Path $regKey -Name TileWallpaper -Value 0 # Ne pas mosaïquer

        # Rafraîchir le bureau pour appliquer le changement immédiatement
        # Correction : Changer le nom de la classe pour éviter le conflit
        $code = '[DllImport("user32.dll", SetLastError = true)] public static extern int SystemParametersInfo(int uiAction, int uiParam, string pvParam, int fWinIni);'
        $type = Add-Type -MemberDefinition $code -Name WinAPICalls -Namespace UIRefresh -PassThru # Changed Name to WinAPICalls

        $SPI_SETDESKWALLPAPER = 0x14
        $SPIF_UPDATEINIFILE = 0x01
        $SPIF_SENDCHANGE = 0x02

        # Appeler la méthode en utilisant le nouveau nom de classe
        $type::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $ImagePath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)

        Write-Log "Fond d'écran changé avec succès pour: $ImagePath" -NoConsole
    } catch {
        Write-Log "Erreur lors du changement du fond d'écran: $_" -NoConsole
        Write-Host "Une erreur est survenue lors du changement du fond d'écran." -ForegroundColor Red
    }
}

function Play-AsciiAnimation {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AnimationName, # Un nom pour identifier l'animation (ex: "fine", "kuru")

        [Parameter(Mandatory=$true)]
        [string]$JsonUri,       # L'URL du fichier JSON contenant les frames

        [int]$AnimationDelayMs = 100, # Délai entre chaque frame en millisecondes

        # Utilisez [object] pour permettre soit un nombre, soit $true pour une boucle infinie
        [object]$NumberOfLoops = 2    # Nombre de fois que l'animation sera jouée. $true pour une boucle infinie.
    )

    # Construire le chemin du fichier temporaire de manière robuste
    $jsonFilePath = Join-Path -Path $env:TEMP -ChildPath "$($AnimationName).json"

    Write-Host "Téléchargement de l'animation '$AnimationName' depuis '$JsonUri'..."

    # --- Téléchargement du fichier JSON ---
    try {
        Invoke-WebRequest -Uri $JsonUri -OutFile $jsonFilePath -ErrorAction Stop
    }
    catch {
        Write-Error "Échec du téléchargement de l'animation '$AnimationName' : $($_.Exception.Message)"
        return # Sortir de la fonction en cas d'erreur de téléchargement
    }

    if (-not (Test-Path $jsonFilePath)) {
        Write-Error "Le fichier d'animation '$jsonFilePath' n'a pas été trouvé après le téléchargement."
        return # Sortir si le fichier n'est pas là
    }

    # --- Lecture et lecture de l'animation ---
    try {
        # Lire le contenu du fichier JSON et le convertir
        $jsonContent = Get-Content $jsonFilePath | Out-String
        $frames = $jsonContent | ConvertFrom-Json

        $currentLoop = 0
        while ($true) {
            # Condition pour sortir de la boucle si ce n'est pas une boucle infinie
            if ($NumberOfLoops -is [int] -and $currentLoop -ge $NumberOfLoops) {
                break
            }

            foreach ($frame in $frames) {
                Clear-Host
                foreach ($line in $frame) {

                    Write-Centered -Message $line
                }

                Start-Sleep -Milliseconds $AnimationDelayMs
            }

            # Incrémenter le compteur de boucle si ce n'est pas une boucle infinie
            if ($NumberOfLoops -isnot [bool] -or $NumberOfLoops -ne $true) {
                $currentLoop++
            }
        }
    }
    catch {
        Write-Error "Erreur lors du traitement ou de l'affichage de l'animation '$AnimationName' : $($_.Exception.Message)"
    }
    finally {
    }
}


#  ███╗   ███╗ █████╗ ██╗███╗   ██╗    ███╗   ███╗███████╗███╗   ██╗██╗   ██╗
#  ████╗ ████║██╔══██╗██║████╗  ██║    ████╗ ████║██╔════╝████╗  ██║██║   ██║
#  ██╔████╔██║███████║██║██╔██╗ ██║    ██╔████╔██║█████╗  ██╔██╗ ██║██║   ██║
#  ██║╚██╔╝██║██╔══██║██║██║╚██╗██║    ██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║   ██║
#  ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║    ██║ ╚═╝ ██║███████╗██║ ╚████║╚██████╔╝
#  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝    ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝

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

    Write-Host "`n1. Mode rapide (interface graphique)"
    Write-Host "2. Télécharger un lien unique"
    Write-Host "3. Télécharger plusieurs liens"
    Write-Host "4. Télécharger depuis un fichier texte"
    Write-Host "5. Modifier le dossier de téléchargement"
    Write-Host "6. Lire directement avec VLC (streaming)"
    Write-Host "7. Gestionnaire de torrents"
    Write-Host "8. Afficher l'historique des liens débridés"
    Write-Host "9. Speedtest"
    Write-Host "Q. Quitter"
    Write-Host "========================================"
    Write-Host "Dossier de téléchargement actuel: $script:currentDownloadFolder" -ForegroundColor Yellow
    Write-Host "========================================"

    $choice = Read-Host "Choisissez une option (1-9 Or Q)"

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
        "8" {
            Get-AlldebridHistory
            Pause
            Show-Menu
        }
        "9" {
            Start-SpeedTest
            Pause
            Show-Menu

        }

        "blyat" {
        Write-Host "☭ Gloire à la mère patrie !" -ForegroundColor Red

        # List of possible anthems
        $anthems = @(
            "https://github.com/Pooueto/blyatAnthem/raw/main/National_Anthem_of_USSR.mp3",
            "https://github.com/Pooueto/blyatAnthem/raw/main/tachanka_kalinka.mp4"
        )

        # Select a random anthem URL
        $randomIndex = Get-Random -Maximum $anthems.Count
        $selectedAnthemUrl = $anthems[$randomIndex]

        Write-Host "Playing: $selectedAnthemUrl" -ForegroundColor Yellow

        # Determine file extension to choose appropriate player
        $fileExtension = [System.IO.Path]::GetExtension($selectedAnthemUrl)

        # Download the selected anthem
        $anthemPath = "$env:TEMP\blyat_anthem$fileExtension"
        try {
            Invoke-WebRequest -Uri $selectedAnthemUrl -OutFile $anthemPath -UseBasicParsing
        } catch {
            Write-Host "Error downloading anthem from $selectedAnthemUrl $($_.Exception.Message)" -ForegroundColor Red
            # Fallback or exit if download fails
            Pause
            Show-Menu
            return
        }


        # Mount volume (requires nircmd)
        $nircmdPath = "$env:TEMP\nircmd.exe"
        if (-not (Test-Path $nircmdPath)) {
            try {
                Invoke-WebRequest -Uri "https://www.nirsoft.net/utils/nircmd.zip" -OutFile "$env:TEMP\nircmd.zip"
                Expand-Archive "$env:TEMP\nircmd.zip" -DestinationPath "$env:TEMP" -Force
                 Write-Host "nircmd downloaded and extracted." -ForegroundColor Green
            } catch {
                Write-Host "Error downloading or extracting nircmd: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Volume may not be set." -ForegroundColor Yellow
            }
        }
         if (Test-Path $nircmdPath) {
             try {
                Start-Process -FilePath $nircmdPath -ArgumentList "setsysvolume 65535" -WindowStyle Hidden -ErrorAction Stop
                Write-Host "Volume set to maximum." -ForegroundColor Green
            } catch {
                Write-Host "Error setting volume with nircmd: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Volume may not be set." -ForegroundColor Yellow
            }
        } else {
             Write-Host "nircmd not found. Volume not set." -ForegroundColor Yellow
        }


        # Play the downloaded file
        try {
            if ($fileExtension -eq ".mp4") {
                # Use default video player for mp4
                Start-Process -FilePath $anthemPath
            } else {
                # Use wmplayer for other audio types (like mp3)
                Start-Process -FilePath $anthemPath
            }
        } catch {
             Write-Host "Error playing anthem file '$anthemPath': $($_.Exception.Message)" -ForegroundColor Red
        }


        $wallpaperUrl = "https://raw.githubusercontent.com/Pooueto/blyatAnthem/main/Flag_of_the_Soviet_Union.png"
            $wallpaperFileName = $wallpaperUrl.Split('/')[-1] # Extrait le nom de fichier de l'URL
            $wallpaperPath = Join-Path $env:TEMP $wallpaperFileName

            try {
                Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath -UseBasicParsing
                Set-DesktopWallpaper -ImagePath $wallpaperPath

            } catch {
                Write-Host "Erreur lors du téléchargement ou de la configuration du fond d'écran: $($_.Exception.Message)" -ForegroundColor Red
            }

            $Host.UI.RawUI.WindowTitle = "Слава Родине ! ☭"
            Write-Host "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                    ⢀⣀⣀⣀⣤⣤⣴⣶⣶⣶⣶⣶⣶⣶⣤⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣴⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⢠⣿⣿⣿⣿⣿⡏⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠉⣠⡿⢻⣿⡿⢿⣿⠟⠙⣿⣙⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⢸⡿⣿⢻⠏⠻⠁⢸⠛⣿⣿⣿⣿⣿⣿⣿⣿⡏⣴⣠⣾⣯⣽⡶⠀⣤⠘⢁⣀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀
                    ⠀⠀⠀⢸⣧⡀⠀⠀⠀⢠⣿⣦⣽⣻⢻⣿⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⡿⢣⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀
                    ⠀⠀⠀⣾⣟⠃⠀⠀⠘⣿⣟⣿⣿⣿⣾⣿⢸⣿⣿⣿⠛⠛⢿⣿⣿⡿⠿⠋⠀⢀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀
                    ⠀⠀⠀⣿⣿⣿⠆⠀⠀⠙⠙⠿⠟⠉⠟⠁⠙⠋⠈⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠈⠁⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
                    ⠀⠀⠀⢹⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
                    ⠀⠀⠀⠠⢯⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
                    ⠀⠀⠀⠀⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢬⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
                    ⠀⠀⠀⠘⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
                    ⠀⠀⢀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣬⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
                    ⠀⠀⢸⣿⣿⣷⣄⡀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣴⣶⣿⣿⣷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
                    ⠀⠀⠈⢇⣀⣙⣻⣿⣷⡆⠀⠀⠀⠚⠻⣿⣭⡀⠀⠀⠀⠈⠙⠿⣷⣤⠀⠀⠀⠀⠀⠀⠀⢲⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀⠀
                    ⠀⠀⠀⠸⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⣼⣿⣿⣿⣷⡶⢤⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⠿⠛⠉⠉⠉⠻⣿⣿⡿⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⠀⢸⣿⡿⠁⠀⠀⠀⠀⠀⠀⢹⣿⣿⠋⠁⠀⠀⠙⢦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢻⡿⠁⠀⠀⣴⡇⠙⣦⢸⣿⠇⠀⠀⠀⠀
                    ⠀⠀⠀⠀⢀⣠⣾⣿⠃⠀⠀⠀⠀⠀⠀⠀⠈⠉⠻⠷⠶⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⣼⣁⠀⠀⢸⢸⡏⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⢸⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠋⢻⣿⠀⠟⢸⠃⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⢉⡏⠀⠀⠀⠀⠀⠀⠀⠀⢠⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⣡⣿⠁⢀⡎⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⣾⡇⠀⠀⠀⠀⢀⣀⢀⣀⡀⢻⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠒⠒⠉⠁⠀⡼⠁⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⢸⣿⣿⣦⣶⣦⣀⡈⠉⠉⠉⠀⠀⠙⢿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡼⠁⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⢈⣿⣿⣿⣿⣿⣿⣿⣿⣶⣄⣀⡀⠀⠀⠙⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣇⠀⠀⣠⡞⠁⠀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠿⠖⠚⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠉⢻⣿⣿⡿⠿⠛⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⢻⣿⣤⣶⣾⣿⣿⣭⡙⠛⠛⠿⠿⣿⣿⣿⣿⣿⡿⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⠘⣿⡛⠛⠙⠛⠛⠛⠻⠷⠀⠀⠀⠀⠀⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⣴⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⠀⠹⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⠀⠀⠀⠑⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣶⣶⣤⣤⣤⣄⣀⣠⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀
                    ⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣟⣛⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⡄
                    ⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
                    ⠀⠀⣀⣤⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠛⢿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
                    ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⠙⠛⠻⢿⠟⠓⠀⠀⢀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
                    ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣀⠀⢀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡃
                    ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁
                    ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀
                    ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀
                    ⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡃
                    ⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
                    ⠀⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠇" -ForegroundColor Red


            [System.Windows.Forms.MessageBox]::Show("Camarade, your downloads will be glorious!, For the Motherland!")

            Pause
            Show-Menu

        }

        "nyancat" {
            $anthemPath = "$env:TEMP\nyancat.mp3"
            Invoke-WebRequest -Uri "https://github.com/Pooueto/Nyancat_sound/raw/main/Nyan_Cat.mp3" -OutFile $anthemPath
            Start-Process -FilePath $anthemPath
            Write-Host "Lancement de la musique Nyancat"

            Write-Host "Attempting to run Nyan Cat..." -ForegroundColor Magenta
            try {
                # Try to run nyancat directly
                & nyancat
            } catch {
                Write-Host "Nyan Cat tool not found or failed to run." -ForegroundColor Red
                Write-Host "Attempting to install Nyan Cat tool..." -ForegroundColor Yellow
                try {
                    # If running failed, try to install
                    & dotnet tool install --global nyancat --version 1.5.0
                    Write-Host "Nyan Cat tool installed successfully!" -ForegroundColor Green
                    Write-Host "Running Nyan Cat..." -ForegroundColor Magenta
                    # Try to run again after installation
                    & nyancat
                } catch {
                    Write-Host "Error installing Nyan Cat: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Please ensure you have the .NET SDK installed and configured correctly." -ForegroundColor Yellow
                }
            }
            Write-Host "`nPress Enter to return to the menu."
        }

        "parrot" {
            curl parrot.live
        }

        "fine" {
            Play-AsciiAnimation `
                -AnimationName "ascciFine" `
                -JsonUri "https://raw.githubusercontent.com/Pooueto/ascci-art/refs/heads/main/ascii-frames.json" `
                -NumberOfLoops 2 `
                -AnimationDelayMs 100

            Show-Menu
        }

        "kuru" {
            Play-AsciiAnimation `
                -AnimationName "kuru" `
                -JsonUri "https://raw.githubusercontent.com/Pooueto/ascci-art/refs/heads/main/kuru.json" `
                -NumberOfLoops 2 `
                -AnimationDelayMs 100

            Show-Menu
        }

        "hitler" {
            Play-AsciiAnimation `
                -AnimationName "hitler" `
                -JsonUri "https://raw.githubusercontent.com/Pooueto/ascci-art/refs/heads/main/hitler.json" `
                -NumberOfLoops 2 `
                -AnimationDelayMs 100

            Show-Menu
        }

        "V" {
        Write-Host $LocalVersion
        }
        "Version" {
            Write-Host $LocalVersion
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


#  ██╗      █████╗ ██╗   ██╗ ██████╗██╗  ██╗
#  ██║     ██╔══██╗██║   ██║██╔════╝██║  ██║
#  ██║     ███████║██║   ██║██║     ███████║
#  ██║     ██╔══██║██║   ██║██║     ██╔══██║
#  ███████╗██║  ██║╚██████╔╝╚██████╗██║  ██║
#  ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝

# Initialisation de la configuration
Initialize-Config

# Lancement du menu principal
Show-Menu