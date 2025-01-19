$ffmpegPath = "C:\Users\Pooueto\scoop\apps\ffmpeg\7.1\bin\ffmpeg.exe"

if (-not (Test-Path $ffmpegPath)) {
    Write-Error "FFmpeg n'est pas trouvé à l'emplacement spécifié."
    exit 1
}

Write-Host "

██╗   ██╗██╗██████╗ ███████╗ ██████╗  ██████╗ ██████╗ ███╗   ███╗██████╗ ██████╗ ███████╗███████╗███████╗
██║   ██║██║██╔══██╗██╔════╝██╔═══██╗██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝
██║   ██║██║██║  ██║█████╗  ██║   ██║██║     ██║   ██║██╔████╔██║██████╔╝██████╔╝█████╗  ███████╗███████╗
╚██╗ ██╔╝██║██║  ██║██╔══╝  ██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██╔══██╗██╔══╝  ╚════██║╚════██║
 ╚████╔╝ ██║██████╔╝███████╗╚██████╔╝╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ██║  ██║███████╗███████║███████║
  ╚═══╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝                                                                                                         
"
            Write-Host "A Video Compressor, by Pooueto"
Write-Host "`n"

# Demander au utilisateur le chemin d'accès d'entrée
$InputPath = Read-Host "S'il vous plaît entrez le chemin d'accès d'entrée"

# Demander au utilisateur le chemin d'accès de sortie
$OutputPath = Read-Host "S'il vous plaît entrez le chemin d'accès de sortie"

$command = "$ffmpegPath -i `$InputPath -vcodec libx265 -crf 28 `$OutputPath"

Write-Host "Exécution de la commande FFmpeg : $command"
Invoke-Expression $command
