param(
    [string]$repertoire = (Split-Path $MyInvocation.MyCommand.Path -Parent)  # Récupère le répertoire courant si aucun n'est spécifié
)

# Banner ASCII personnalisable
Write-Host "`n"
Write-Host "
            ██████╗ ███████╗████████╗████████╗███████╗██████╗     ██╗   ██╗██╗      ██████╗
            ██╔══██╗██╔════╝╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗    ██║   ██║██║     ██╔════╝
            ██████╔╝█████╗     ██║      ██║   █████╗  ██████╔╝    ██║   ██║██║     ██║     
            ██╔══██╗██╔══╝     ██║      ██║   ██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██║     ██║     
            ██████╔╝███████╗   ██║      ██║   ███████╗██║  ██║     ╚████╔╝ ███████╗╚██████╗
            ╚═════╝ ╚══════╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚══════╝ ╚═════╝"
            Write-Host "A VLC interpreter for windows terminal, by Pooueto"
Write-Host "`n"

# Get all file in the directory
$fichiersVideo = Get-ChildItem $repertoire 
# Check if any video files were found
if ($fichiersVideo.Count -gt 0) {
    # Display video files with indices
    for ($i=0; $i -lt $fichiersVideo.Count; $i++) {
        Write-Host "$($i+1) - $($fichiersVideo[$i].Name)"
    }

    # Get user input
    $choix = Read-Host "Entrez le numéro du fichier à lire (ou laissez vide pour lire tous les fichiers):"

    # Si l'utilisateur laisse vide, lire tous les fichiers
    if ($choix -eq "") {
        foreach ($fichier in $fichiersVideo) {
            Start-Process "C:\Program Files\VideoLAN\VLC\vlc.exe" -ArgumentList "--fullscreen `"$($fichier.FullName)`""
        }
    } else {
        # Validate user input
        if ($choix -as [int] -gt 0 -and $choix -le $fichiersVideo.Count) {
            $fichierSelectionne = $fichiersVideo[$choix - 1]
            Start-Process "C:\Program Files\VideoLAN\VLC\vlc.exe" -ArgumentList "--fullscreen `"$($fichierSelectionne.FullName)`""
        } else {
            Write-Host "Choix invalide."
        }
    }
} else {
    Write-Host "Aucun fichier vidéo trouvé dans le répertoire spécifié."
}
