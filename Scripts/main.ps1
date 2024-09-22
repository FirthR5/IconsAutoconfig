<#
.SYNOPSIS
Used to Demostrate Creating a GUI for PowerShell
.DESCRIPTION
Be sure to have the three files, your XAML Form, the loadDialog.ps1 helper cmdLet, and this file.  For clean separation
Store your .ps1 files in a Scripts Folder and the XAML forms in a Forms folder
#
# References
# https://gist.github.com/norbertvajda/b599fcd3a3faaf8532da6aab09965d06
# https://mcpmag.com/articles/2016/04/28/building-ui-using-powershell.aspx
# https://woshub.com/powershell-read-modify-json-object/
#>

# Imports
# ────────────────────────────────────────────────────────────────────────────────────
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentDir = (Get-Item $scriptDir).Parent.FullName
& "$scriptDir\loadDialog.ps1" -XamlPath "$parentDir\Forms\MyForm.xaml"
# ────────────────────────────────────────────────────────────────────────────────────
$jsonfile = Join-Path -Path $PSScriptRoot -ChildPath "my_data.json"
$json=Get-Content -Path $jsonfile -Raw |Out-String | ConvertFrom-Json 
# ────────────────────────────────────────────────────────────────────────────────────

# Bindings
# ────────────────────────────────────────────────────────────────────────────────────
# Grids
$datagridIcons = $xamGUI.FindName("DataGridIcons")
$datagridFolders = $xamGUI.FindName("DataGridFolders")
# Buttons
$Btn_RefreshIcons = $xamGUI.FindName("Btn_RefreshIcons")
$Btn_RefreshFolder = $xamGUI.FindName("Btn_RefreshFolder")
# $btnGetSelection = $window.FindName("btnGetSelection")
$Btn_EditIcon = $xamGUI.FindName("Btn_EditIcon")
# Combo box
$cbox = $xamGUI.FindName("cbox")
# ────────────────────────────────────────────────────────────────────────────────────

# Functions
# ────────────────────────────────────────────────────────────────────────────────────
# Concat and Get Paths
# Left panel
function ConcatenationFolder{
  param($FolderName)
  $FullPath=$json.root_directory+"\\"+$FolderName
  return $FullPath
}
# Left & Right Panel
function GetPathByName{
  param($ID_Name)
  # Write-Host "$ID_Name"
  $FolderName=$json.predefined_logos.psobject.properties.Where({$_.name -eq "$ID_Name"}).Value
  # Write-Host "$FolderName"
  $FullPath=ConcatenationFolder($FolderName);
  return $FullPath
}

# Get Data from JSON
function LoadDataGridIcons {
  $items = @()
  foreach ($prop in $json.predefined_logos.PSObject.Properties) {
    $items += [PSCustomObject]@{Nombre = $prop.Name; Ruta = $prop.Value}
  }
  $datagridIcons.ItemsSource = $items
}

function LoadDataGridFolders{
   $datagridFolders.ItemsSource = @($json.data)
  $items2 = @()
  foreach ($prop in $json.data.PSObject.Properties) {
    $items2 += [PSCustomObject]@{Nombre = $prop.Name; Ruta = $prop.Value}
  }
  $datagridFolders.ItemsSource = $items2
}

function LoadData {
  param ($Type)
  $json = Get-Content -Path $jsonfile -Raw | Out-String | ConvertFrom-Json
  Write-Host "$Type"

  switch ($Type) {
    "Icons" { LoadDataGridIcons }
    "Folders" { LoadDataGridFolders }
  }
}

function LoadCbox{
  $cbox.Items.Clear()
  foreach ($item in $json.predefined_logos.PSObject.Properties) {
      [void]$cbox.Items.Add($item.Name) #| Out-Null
  }
}


function DeleteItem {
  param ($Type)

  $selectedItem = switch ($Type) {
    "Icon" { $datagridIcons.SelectedItem.Nombre }
    "Folder" { $datagridFolders.SelectedItem.Nombre }
  }

  if ($selectedItem) {
    $jsonPath = switch ($Type) {
      "Icon" { "predefined_logos" }
      "Folder" { "data" }
    }
    $json.$jsonPath.PSObject.Properties.Remove("$selectedItem")
    $json | ConvertTo-Json | Out-File -FilePath $jsonfile -Encoding utf8
    LoadData($Type)
    LoadCbox;
    [System.Windows.MessageBox]::Show("Valor Eliminado: $selectedItem")
  } 
  else { [System.Windows.MessageBox]::Show("Por favor, seleccione un registro para eliminar.") }
}

function UpdateIcon {
  param ($Type, $Grid, $Image, $Property)

  $selectedItem = $Grid.SelectedItem
  try {
    if ($selectedItem -ne $null) {
      $icono = GetPathByName("$($selectedItem.$Property)")
      $Image.Source = New-Object System.Windows.Media.Imaging.BitmapImage($icono)
    }
  }
  catch {
    ErrorMessage($_)
    $icono = GetPathByName("Error")
    $Image.Source = New-Object System.Windows.Media.Imaging.BitmapImage($icono)
  }
}
function LoadIconOnViewer {
  param ( $selectedItem, $Image)
  try {
    if ($selectedItem -ne $null) {
      $icono = GetPathByName("$($selectedItem)")
      $Image.Source = New-Object System.Windows.Media.Imaging.BitmapImage($icono)
    }
  }
  catch {
    $icono = GetPathByName("Error")
    $Image.Source = New-Object System.Windows.Media.Imaging.BitmapImage($icono)
  }
}

function CboxViewer{
    try{
      $selectedItem = $cbox.SelectedItem
      if ($selectedItem) {
          $icono = GetPathByName("$($selectedItem)")
          $bitmap3.Source = New-Object System.Windows.Media.Imaging.BitmapImage($icono)
      }
      else { [System.Windows.MessageBox]::Show("No has seleccionado ninguna opción.") }
    }
    catch{
      $bitmap3.Source = $null
      ErrorMessage($_)
    }
    
}

function BrowseExplorerIcon{
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Filter = "Archivos de imagen (*.ico)|*.ico"
  $ofd.Title = "Seleccionar archivo de icono"
  $ofd.ShowDialog() | Out-Null
  $bitmap.Source = New-Object System.Windows.Media.Imaging.BitmapImage($ofd.FileName)
  $Lbl_RutaIconoNuevo.Content = $ofd.FileName
}

function SaveNewIcon{
  try{
    $nombre=$input_name.Text
    $ruta=$Lbl_RutaIconoNuevo.Content.Substring($json.root_directory.Length+1) 
    if ($nombre -ne $null -and $ruta -ne $null) {
      if($json.predefined_logos.psobject.properties.Where({$_.name -eq "$nombre"}).Value) {
        [System.Windows.MessageBox]::show("The Icon's name already exists")
        return;
      }
      $json.predefined_logos | Add-Member -MemberType NoteProperty -Name "$nombre" -Value "$ruta"
      $json | ConvertTo-Json | Out-File -FilePath $jsonfile  -Encoding utf8
      ## Add the new element after the loop
      $items = @()
      foreach ($prop in $json.predefined_logos.PSObject.Properties) {
        $items += [PSCustomObject]@{Nombre = $prop.Name; Ruta = $prop.Value}
      }
      $datagridIcons.ItemsSource = $items
      ClearNewIconsTexts;
      # UpdateCbox;
      $cbox.Items.Add($nombre)

      [System.Windows.MessageBox]::show("Se guardo correctamente")
      #TODO: Clean TxtBox & View & Label
    }
    else{ return }
  }
  catch{ ErrorMessage($_) }
}

function cbox_save{
  # cbox, input_name1
  $ruta = $cbox.SelectedItem
  $nombre = $input_name1.Text
  $json.data | Add-Member -MemberType NoteProperty -Name "$nombre" -Value "$ruta"
  $json | ConvertTo-Json | Out-File -FilePath $jsonfile  -Encoding utf8

  $items = @()
  foreach ($prop in $json.data.PSObject.Properties) {
    $items += [PSCustomObject]@{Nombre = $prop.Name; Ruta = $prop.Value}
  }
  $datagridFolders.ItemsSource = $items

  $input_name1.Text="";
  [System.Windows.MessageBox]::show("Se guardo correctamente")

}

function ClearNewIconsTexts{
    $input_name.Text="";
    $Lbl_RutaIconoNuevo.Content=""
    $bitmap.Source = $null
}

function ClearViewers{
  $bitmap.Source = $null
  $bitmap2.Source = $null
  $bitmap3.Source = $null
  $IconoFolder.Source = $null
}

function ErrorMessage($Error){
    Write-Warning  "Error: $Error"
    Write-Warning "Exception Type: $($Error.GetType().Name)"
    Write-Warning "Message: $($Error.Exception.Message)"
}

$handlerEditGridCell = {
    param ($sender, $eventArgs)
    # Obtener el valor antiguo y el nuevo valor
    $row = $eventArgs.Row.Item
    $column = $eventArgs.Column.Header
    $oldValue = $row.($column)
    $newValue = $eventArgs.EditingElement.Text

    Write-Host "$row | $column"
    # Mostrar mensaje si el valor cambió
    if ($oldValue -ne $newValue) {
        [System.Windows.MessageBox]::Show("La celda de la columna '$column' fue modificada. Nuevo valor: $newValue")
    }
}
# ────────────────────────────────────────────────────────────────────────────────────

# Load Data
# ────────────────────────────────────────────────────────────────────────────────────
LoadDataGridIcons; LoadDataGridFolders; LoadCbox;

# Selections
# ────────────────────────────────────────────────────────────────────────────────────
# Datagrid Selections
$datagridIcons.add_SelectionChanged({ UpdateIcon -Type "Icon" -Grid $datagridIcons -Image $bitmap2 -Property "Nombre" })
$datagridFolders.add_SelectionChanged({ UpdateIcon -Type "Folder" -Grid $datagridFolders -Image $IconoFolder -Property "Ruta" })
$dataGridIcons.add_CellEditEnding($handlerEditGridCell)
$dataGridFolders.add_CellEditEnding($handlerEditGridCell)
# $json

#EVENT Handler 
$Btn_DeleteIcon.add_Click({ DeleteItem -Type "Icon";LoadData -Type "Icons" })
$Btn_DeleteFolder.add_Click({ DeleteItem -Type "Folder";LoadData -Type "Folders" })

# Buttons
$Btn_IconoNuevo.add_Click({BrowseExplorerIcon; })
$Btn_IconoNuevoSave.add_Click({ SaveNewIcon; })

$Btn_IconoNuevoSave1.add_Click({cbox_save})


$Btn_EditIcon.add_Click({
  [System.Windows.MessageBox]::show( $datagridIcons.SelectedItem.Nombre)
  ClearViewers
})

$Btn_RefreshIcons.add_Click({ LoadData -Type "Icons" })
$Btn_RefreshFolder.add_Click({ LoadData -Type "Folders" })
$cbox.add_SelectionChanged({ CboxViewer; })

#launch the window
# ────────────────────────────────────────────────────────────────────────────────────
$xamGUI.ShowDialog() | out-null

