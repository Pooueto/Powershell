param(
    [string]$ImagePath
)

if (-not $ImagePath){
    Write-Warning "Pas de chemin spécifié dans l'appel de la commande..."
    return
}


if (-not (Test-Path $ImagePath)) {
    Write-Warning "Le chemin d'image spécifié n'existe pas : $($ImagePath)"
    return
}



$newPath = [System.IO.Path]::ChangeExtension($ImagePath, ".png")

try {
    # Install ImageMagick and add its bin directory to the PATH environment variable
    magick "$ImagePath" "$newPath"
Write-Host "
██╗███╗   ███╗ ██████╗     ████████╗ ██████╗     ██████╗ ███╗   ██╗ ██████╗ 
██║████╗ ████║██╔════╝     ╚══██╔══╝██╔═══██╗    ██╔══██╗████╗  ██║██╔════╝ 
██║██╔████╔██║██║  ███╗       ██║   ██║   ██║    ██████╔╝██╔██╗ ██║██║  ███╗
██║██║╚██╔╝██║██║   ██║       ██║   ██║   ██║    ██╔═══╝ ██║╚██╗██║██║   ██║
██║██║ ╚═╝ ██║╚██████╔╝       ██║   ╚██████╔╝    ██║     ██║ ╚████║╚██████╔╝
╚═╝╚═╝     ╚═╝ ╚═════╝        ╚═╝    ╚═════╝     ╚═╝     ╚═╝  ╚═══╝ ╚═════╝ "
            Write-Host "A IMG to PNG converter, by Pooueto"
Write-Host "`n"
    Write-Host "Conversion réussie : $($ImagePath) -> $($newPath)"
}
catch {
    Write-Warning "Erreur lors de la conversion : $($_.Exception.Message)"
}