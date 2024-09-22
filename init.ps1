# Init
# ────────────────────────────────────────────────────────────────────────────────────
Write-Host "Auto Set Icon's Folders"
$select_app = read-host "Do you want to configure the Icons(y/n)? (GUI will be open)"
if ($select_app -eq "y") {
  try {
    Remove-Module -Name main -Force
    Import-Module -Name .\Scripts\main.ps1
  }
  catch {
    return;
  }
}
Write-Host "`nAuto Set Icon's Folders"
Write-Host "Running ...`n"

# Imports
# ────────────────────────────────────────────────────────────────────────────────────
$jsonfile=".\Scripts\my_data.json" 
$json=Get-Content -Path $jsonfile -Raw |Out-String | ConvertFrom-Json 

if(Test-Path $json.root_directory){
  $iconrootpath = $json.root_directory
}
else{
  Write-Host "Ico's Folder not found"
  $json.root_directory = read-host "Write your Icon's Folder"
  $json | ConvertTo-Json | Out-File -FilePath $jsonfile -Encoding utf8
}

function ConcatenationFolder{
  param($FolderName)
  $FullPath=$json.root_directory+"\"+$FolderName
  return $FullPath
}
# Left & Right Panel
function GetPathByName{
  param($ID_Name)
  $FolderName=$json.predefined_logos.psobject.properties.Where({$_.name -eq "$ID_Name"}).Value
  $FullPath=ConcatenationFolder($FolderName);
  return $FullPath
}

function set-foldericon {
    param (
        [string]$folderpath,
        [string]$iconrelativepath
    )
    # $iconfullpath = join-path $iconrootpath $iconrelativepath
    $iconfullpath = $iconrelativepath

    if(!(Test-Path $iconfullpath)){
      write-host "Icono no existe: $iconfullpath"
      return
    }
    $desktopinipath = join-path $folderpath "desktop.ini"
    $inicontent = @"
[.shellclassinfo]
iconresource=$iconfullpath,0
"@
    if (Test-Path $desktopinipath) {
        $existingicontent = Get-Content -Path $desktopinipath -Raw | ForEach-Object { $_.Trim() }
        if ($existingicontent -eq $inicontent.Trim()) {
            # write-host "El archivo desktop.ini ya existe y tiene el mismo contenido. No se sobreescribirá."
            return
        }
    }
    write-host "New: $desktopinipath"

    set-content -path $desktopinipath -value $inicontent -force
    # hacer que el archivo desktop.ini sea oculto y de sistema
    set-itemproperty -path $desktopinipath -name attributes -value ([system.io.fileattributes]::system + [system.io.fileattributes]::hidden)
    # establecer que la carpeta es de sistema para que windows use el archivo desktop.ini
    set-itemproperty -path $folderpath -name attributes -value ([system.io.fileattributes]::system)
}

# función para buscar subcarpetas y asignarles íconos si coinciden con la clave
function assigniconstosubfolders {
    param (
        [string]$rootfolderpath
    )

    Write-Host "Checking all subfolders"
    # obtener todas las subcarpetas en la carpeta raíz
    $subfolders = get-childitem -path $rootfolderpath -directory -recurse -Depth 3
    # iterar por cada subcarpeta
    foreach ($subfolder in $subfolders) {
      $foldername = $subfolder.name

      # si la subcarpeta tiene un ícono asignado en la lista
      # TODO: Hastable compare with Key
      if ($dataHashtable.contains($foldername)) {
        $iconfullpath = GetPathByName($dataHashtable[$foldername])
        Write-Host "$iconrelativepath"
        set-foldericon -folderpath $subfolder.fullname -iconrelativepath $iconfullpath
        # Start-Sleep -m 1000
      }
      # $json.predefined_logos.psobject.properties.Where({$_.name -eq "$nombre"}).Value
    }
}


$dataHashtable = [ordered]@{}
$json.Data | ForEach-Object { 
    foreach ($key in $_.PSObject.Properties.Name) {
        $dataHashtable[$key] = $_.$key
    }
}

# $json.Data | ForEach-Object { $dataHashtable.Add($_.PSObject.Properties.Name, $_.PSObject.Properties.Value) }

$rootfolderpath = $json.rootfolderpath

$customroot = read-host "The changes will be made in the path `"$rootfolderpath`"`nDo you want to enter a different root folder (y/n)?"
if ($customroot -eq "y") {
    $rootfolderpath = read-host "Now write (or paste) your root path"
}

# Running the Logic
assigniconstosubfolders -rootfolderpath $rootfolderpath

Write-Host "End Of Line"
