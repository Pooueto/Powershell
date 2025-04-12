# Script PowerShell pour ajouter une pochette, l'artiste et le titre à un fichier MP3 en utilisant FFmpeg
# Avec une interface utilisateur Windows Forms pour la sélection et édition des métadonnées
# Suppose que FFmpeg est déjà installé et disponible dans le PATH

# Charger les assemblies Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Selectionner-Fichier {
    param (
        [string]$Titre,
        [string]$Filtre,
        [string]$CheminInitial = [Environment]::GetFolderPath('MyMusic')
    )
    
    $dialogue = New-Object System.Windows.Forms.OpenFileDialog
    $dialogue.Title = $Titre
    $dialogue.Filter = $Filtre
    $dialogue.InitialDirectory = $CheminInitial
    $dialogue.Multiselect = $false
    
    if ($dialogue.ShowDialog() -eq 'OK') {
        return $dialogue.FileName
    }
    
    return $null
}

function Selectionner-DossierSortie {
    param (
        [string]$Description = "Sélectionnez le dossier de destination",
        [string]$CheminInitial = [Environment]::GetFolderPath('MyMusic')
    )
    
    $dialogue = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialogue.Description = $Description
    $dialogue.SelectedPath = $CheminInitial
    
    if ($dialogue.ShowDialog() -eq 'OK') {
        return $dialogue.SelectedPath
    }
    
    return $null
}

function Afficher-MessageBox {
    param (
        [string]$Message,
        [string]$Titre,
        [System.Windows.Forms.MessageBoxButtons]$Boutons = [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]$Icone = [System.Windows.Forms.MessageBoxIcon]::Information
    )
    
    return [System.Windows.Forms.MessageBox]::Show($Message, $Titre, $Boutons, $Icone)
}

function Extraire-InfoMusique {
    param (
        [string]$NomFichier
    )
    
    # Supprimer l'extension
    $nomSansExtension = [System.IO.Path]::GetFileNameWithoutExtension($NomFichier)
    
    $artiste = ""
    $titre = ""
    
    # Vérifier si le nom contient un séparateur (comme " - ")
    if ($nomSansExtension -match "(.+?)\s*-\s*(.+)") {
        $artiste = $matches[1].Trim()
        $titre = $matches[2].Trim()
    } else {
        # Si pas de séparateur trouvé, utiliser le nom complet comme titre
        $titre = $nomSansExtension
    }
    
    return @{
        Artiste = $artiste
        Titre = $titre
    }
}

function Nettoyer-NomFichier {
    param(
        [string]$Nom
    )
    
    # Remplacer les caractères invalides pour les noms de fichiers
    $nomNettoye = $Nom -replace '[\\/:*?"<>|]', '_'
    return $nomNettoye
}

function Ajouter-Metadata-FFmpeg {
    param(
        [string]$CheminMP3,
        [string]$CheminImage,
        [string]$DossierSortie = "",
        [bool]$RemplacerOriginal = $false,
        [string]$NomArtiste = "",
        [string]$TitreChanson = "",
        [bool]$SupprimerImage = $false  # Nouveau paramètre pour supprimer l'image
    )
    
    # Vérifier si les fichiers existent
    if (-not (Test-Path $CheminMP3)) {
        Afficher-MessageBox "Le fichier MP3 n'existe pas: $CheminMP3" "Erreur" ([System.Windows.Forms.MessageBoxButtons]::OK) ([System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    
    if (-not (Test-Path $CheminImage)) {
        Afficher-MessageBox "Le fichier image n'existe pas: $CheminImage" "Erreur" ([System.Windows.Forms.MessageBoxButtons]::OK) ([System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    
    # Vérifier si FFmpeg est disponible
    try {
        $ffmpegVersion = & ffmpeg -version
        if (-not $?) {
            Afficher-MessageBox "FFmpeg n'est pas disponible dans le PATH" "Erreur" ([System.Windows.Forms.MessageBoxButtons]::OK) ([System.Windows.Forms.MessageBoxIcon]::Error)
            return $false
        }
    }
    catch {
        Afficher-MessageBox "Erreur lors de la vérification de FFmpeg: $_" "Erreur" ([System.Windows.Forms.MessageBoxButtons]::OK) ([System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    
    # Déterminer le fichier de sortie
    $extension = [System.IO.Path]::GetExtension($CheminMP3)
    
    if ([string]::IsNullOrEmpty($DossierSortie)) {
        $DossierSortie = [System.IO.Path]::GetDirectoryName($CheminMP3)
    }
    
    # Nettoyer le nom de fichier pour qu'il soit valide
    $nomFichierNettoye = ""
    if (-not [string]::IsNullOrEmpty($NomArtiste) -and -not [string]::IsNullOrEmpty($TitreChanson)) {
        $nomFichierNettoye = Nettoyer-NomFichier -Nom "$NomArtiste - $TitreChanson"
    } else {
        $nomFichierNettoye = [System.IO.Path]::GetFileNameWithoutExtension($CheminMP3)
    }
    
    $fichierSortie = ""
    if ($RemplacerOriginal) {
        $fichierSortie = Join-Path -Path $env:TEMP -ChildPath ($nomFichierNettoye + "_temp" + $extension)
    } else {
        $fichierSortie = Join-Path -Path $DossierSortie -ChildPath ($nomFichierNettoye + $extension)
        
        # S'assurer que le nom de fichier est unique
        $compteur = 1
        while (Test-Path $fichierSortie) {
            $fichierSortie = Join-Path -Path $DossierSortie -ChildPath ($nomFichierNettoye + "_" + $compteur + $extension)
            $compteur++
        }
    }
    
    # Commande FFmpeg pour ajouter la pochette et les métadonnées
    $arguments = @(
        '-i', "`"$CheminMP3`"",             # Fichier audio d'entrée
        '-i', "`"$CheminImage`"",           # Image de pochette
        '-map', '0:0',                      # Mapper le flux audio du premier fichier
        '-map', '1:0',                      # Mapper l'image du deuxième fichier
        '-c', 'copy'                        # Copier l'audio sans réencodage
    )
    
    # Ajouter la métadonnée de l'artiste si elle est disponible
    if (-not [string]::IsNullOrEmpty($NomArtiste)) {
        $arguments += '-metadata'
        $arguments += "artist=`"$NomArtiste`""
    }
    
    # Ajouter la métadonnée du titre si elle est disponible
    if (-not [string]::IsNullOrEmpty($TitreChanson)) {
        $arguments += '-metadata'
        $arguments += "title=`"$TitreChanson`""
    }
    
    # Ajouter le reste des arguments
    $arguments += @(
        '-metadata:s:v', 'title="Album cover"',
        '-metadata:s:v', 'comment="Cover (front)"',
        '-id3v2_version', '3',              # Version ID3v2.3
        '-write_id3v1', '1',                # Écrire également les tags ID3v1
        "`"$fichierSortie`""                # Fichier de sortie
    )
    
    # Créer une fenêtre de progression
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Ajout des métadonnées en cours..."
    $form.Size = New-Object System.Drawing.Size(400, 150)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(380, 40)
    $label.Text = "Ajout de la pochette et des métadonnées au fichier MP3...`nVeuillez patienter."
    $form.Controls.Add($label)
    
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10, 70)
    $progressBar.Size = New-Object System.Drawing.Size(360, 23)
    $progressBar.Style = "Marquee"
    $form.Controls.Add($progressBar)
    
    # Afficher la forme dans un nouveau thread
    $formClosed = $false
    $thread = [System.Threading.Thread]::CurrentThread
    $form.Add_FormClosed({ $formClosed = $true })
    $form.Show()
    $form.Refresh()
    
    try {
        # Exécuter FFmpeg
        $process = Start-Process -FilePath "ffmpeg" -ArgumentList $arguments -NoNewWindow -Wait -PassThru
        
        # Fermer la fenêtre de progression
        $form.Close()
        
        if ($process.ExitCode -eq 0) {
            # Si l'option de remplacement est activée, remplacer le fichier original
            if ($RemplacerOriginal) {
                Move-Item -Path $fichierSortie -Destination $CheminMP3 -Force
                $messageSucces = "La pochette et les métadonnées ont été ajoutées avec succès et le fichier original a été remplacé."
            } else {
                $messageSucces = "La pochette et les métadonnées ont été ajoutées avec succès.`nFichier de sortie: $fichierSortie"
            }
            
            # Supprimer l'image si demandé
            if ($SupprimerImage) {
                Remove-Item -Path $CheminImage -Force
                $messageSucces += "`nL'image de pochette a été supprimée."
            }
            
            Afficher-MessageBox $messageSucces "Opération réussie" ([System.Windows.Forms.MessageBoxButtons]::OK) ([System.Windows.Forms.MessageBoxIcon]::Information)
            return $true
        } else {
            Afficher-MessageBox "FFmpeg a retourné une erreur (code: $($process.ExitCode))" "Erreur" ([System.Windows.Forms.MessageBoxButtons]::OK) ([System.Windows.Forms.MessageBoxIcon]::Error)
            return $false
        }
    }
    catch {
        # S'assurer que la fenêtre de progression est fermée en cas d'erreur
        if (-not $formClosed) {
            $form.Close()
        }
        Afficher-MessageBox "Erreur lors de l'exécution de FFmpeg: $_" "Erreur" ([System.Windows.Forms.MessageBoxButtons]::OK) ([System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
}

# Fonction principale avec interface graphique
function Main {
    # Sélectionner le fichier MP3
    $cheminMP3 = Selectionner-Fichier "Sélectionnez le fichier MP3" "Fichiers MP3 (*.mp3)|*.mp3|Tous les fichiers (*.*)|*.*"
    if ([string]::IsNullOrEmpty($cheminMP3)) {
        return
    }
    
    # Sélectionner l'image de pochette
    $cheminImage = Selectionner-Fichier "Sélectionnez l'image de pochette" "Images (*.jpg;*.jpeg;*.png;*.bmp)|*.jpg;*.jpeg;*.png;*.bmp|Tous les fichiers (*.*)|*.*" ([System.IO.Path]::GetDirectoryName($cheminMP3))
    if ([string]::IsNullOrEmpty($cheminImage)) {
        return
    }
    
    # Extraire les informations de la musique
    $nomFichier = [System.IO.Path]::GetFileName($cheminMP3)
    $infoMusique = Extraire-InfoMusique -NomFichier $nomFichier
    $nomArtiste = $infoMusique.Artiste
    $titreChanson = $infoMusique.Titre
    
    # Créer un formulaire pour éditer les métadonnées
    $formMetadata = New-Object System.Windows.Forms.Form
    $formMetadata.Text = "Métadonnées de la musique"
    $formMetadata.Size = New-Object System.Drawing.Size(400, 240)  # Taille augmentée pour la nouvelle option
    $formMetadata.StartPosition = "CenterScreen"
    $formMetadata.FormBorderStyle = "FixedDialog"
    $formMetadata.MaximizeBox = $false
    
    # Label et TextBox pour l'artiste
    $labelArtiste = New-Object System.Windows.Forms.Label
    $labelArtiste.Location = New-Object System.Drawing.Point(10, 20)
    $labelArtiste.Size = New-Object System.Drawing.Size(380, 20)
    $labelArtiste.Text = "Nom de l'artiste:"
    $formMetadata.Controls.Add($labelArtiste)
    
    $textBoxArtiste = New-Object System.Windows.Forms.TextBox
    $textBoxArtiste.Location = New-Object System.Drawing.Point(10, 40)
    $textBoxArtiste.Size = New-Object System.Drawing.Size(360, 20)
    $textBoxArtiste.Text = $nomArtiste
    $formMetadata.Controls.Add($textBoxArtiste)
    
    # Label et TextBox pour le titre
    $labelTitre = New-Object System.Windows.Forms.Label
    $labelTitre.Location = New-Object System.Drawing.Point(10, 70)
    $labelTitre.Size = New-Object System.Drawing.Size(380, 20)
    $labelTitre.Text = "Titre de la chanson:"
    $formMetadata.Controls.Add($labelTitre)
    
    $textBoxTitre = New-Object System.Windows.Forms.TextBox
    $textBoxTitre.Location = New-Object System.Drawing.Point(10, 90)
    $textBoxTitre.Size = New-Object System.Drawing.Size(360, 20)
    $textBoxTitre.Text = $titreChanson
    $formMetadata.Controls.Add($textBoxTitre)
    
    # CheckBox pour supprimer l'image après utilisation
    $checkBoxSupprimerImage = New-Object System.Windows.Forms.CheckBox
    $checkBoxSupprimerImage.Location = New-Object System.Drawing.Point(10, 120)
    $checkBoxSupprimerImage.Size = New-Object System.Drawing.Size(360, 20)
    $checkBoxSupprimerImage.Text = "Supprimer l'image après avoir ajouté la pochette"
    $formMetadata.Controls.Add($checkBoxSupprimerImage)
    
    # Boutons OK et Annuler (positions ajustées)
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Location = New-Object System.Drawing.Point(100, 150)
    $btnOK.Size = New-Object System.Drawing.Size(80, 30)
    $btnOK.Text = "OK"
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $formMetadata.Controls.Add($btnOK)
    $formMetadata.AcceptButton = $btnOK
    
    $btnAnnuler = New-Object System.Windows.Forms.Button
    $btnAnnuler.Location = New-Object System.Drawing.Point(200, 150)
    $btnAnnuler.Size = New-Object System.Drawing.Size(80, 30)
    $btnAnnuler.Text = "Annuler"
    $btnAnnuler.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $formMetadata.Controls.Add($btnAnnuler)
    $formMetadata.CancelButton = $btnAnnuler
    
    # Afficher le formulaire
    $resultat = $formMetadata.ShowDialog()
    
    if ($resultat -eq [System.Windows.Forms.DialogResult]::OK) {
        $nomArtiste = $textBoxArtiste.Text
        $titreChanson = $textBoxTitre.Text
        $supprimerImage = $checkBoxSupprimerImage.Checked  # Récupérer l'état de la case à cocher
        
        # Demander si l'utilisateur veut remplacer le fichier original
        $reponse = Afficher-MessageBox "Voulez-vous remplacer le fichier MP3 original?`n(Si Non, un nouveau fichier sera créé avec le titre comme nom)" "Options" ([System.Windows.Forms.MessageBoxButtons]::YesNo) ([System.Windows.Forms.MessageBoxIcon]::Question)
        $remplacerOriginal = ($reponse -eq "Yes")
        
        $dossierSortie = ""
        if (-not $remplacerOriginal) {
            # Sélectionner le dossier de destination
            $dossierSortie = Selectionner-DossierSortie "Sélectionnez le dossier de destination" ([System.IO.Path]::GetDirectoryName($cheminMP3))
            if ([string]::IsNullOrEmpty($dossierSortie)) {
                return
            }
        }
        
        # Exécuter la fonction principale avec les métadonnées et l'option de suppression d'image
        Ajouter-Metadata-FFmpeg -CheminMP3 $cheminMP3 -CheminImage $cheminImage -DossierSortie $dossierSortie -RemplacerOriginal $remplacerOriginal -NomArtiste $nomArtiste -TitreChanson $titreChanson -SupprimerImage $supprimerImage
    }
}

# Exécuter la fonction principale
Main