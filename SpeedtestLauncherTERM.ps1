# Banner ASCII personnalisable
Write-Host "`n"
Write-Host "
███████╗██████╗ ███████╗███████╗██████╗ ████████╗███████╗███████╗████████╗
██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
███████╗██████╔╝█████╗  █████╗  ██║  ██║   ██║   █████╗  ███████╗   ██║   
╚════██║██╔═══╝ ██╔══╝  ██╔══╝  ██║  ██║   ██║   ██╔══╝  ╚════██║   ██║   
███████║██║     ███████╗███████╗██████╔╝   ██║   ███████╗███████║   ██║   
╚══════╝╚═╝     ╚══════╝╚══════╝╚═════╝    ╚═╝   ╚══════╝╚══════╝   ╚═╝   "
            Write-Host "A speedtest launcher, by Pooueto"
Write-Host "`n"

$speedtestPath = "C:\Users\Pooueto\Documents\speedtest\speedtest.exe"

try {
    Start-Process -FilePath $speedtestPath
}
catch {
    Write-Host "Une erreur s'est produite lors de l'exécution du test :" $_.Exception.Message
}