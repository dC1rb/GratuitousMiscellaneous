$folder      = "YourFolder"
$RESPROP     = 31 # Which property contains the resolution
$override_ratio = 3.55555555555556

# Find the aspect ratio of the current screen
try { 
    $bounds = [System.Windows.Forms.Screen]::AllScreens.Bounds
    $screen_height = [int]$bounds.Height
    $screen_width  = [int]$bounds.Width
    $target_ratio  = $screen_width / $screen_height
} catch {
    Write-Output "[WARN]: No Winforms installed, assuming you're at maximum resolution for your screen"
}

if( -not $target_ratio ){
    $vcr = (gwmi CIM_VideoControllerResolution)[-1]
    $screen_height = [int]$vcr.VerticalResolution
    $screen_width  = [int]$vcr.HorizontalResolution
    $target_ratio  = $screen_width / $screen_height
}

if( $override_ratio ){
    $target_ratio = $override_ratio
}

$shell = New-Object -ComObject "Shell.Application"
$shell_folder = $shell.NameSpace($folder)

[System.Collections.ArrayList]$pics = @()

foreach ($item in $shell_folder.Items()) {
    # skip over files that aren't the kind we want
    if ($item.Name -notmatch ".+?\.(png|jpeg|jpg)$") {continue}

    # Properties from the COM object come with unicode U+202A (LtR) markers
    # we strip them off with substring before we can parse the text to numbers
    $raw = $shell_folder.GetDetailsOf($item,$RESPROP)
    ([int]$width,$null,[int]$height) = $raw.Substring(1,$raw.Length-2).split()

    $ratio = $width/$height
    $difference = $ratio - $target_ratio

    $picture = New-Object -TypeName psobject
    $picture | Add-Member -MemberType NoteProperty -Name "Name"   -Value $item.Name
    $picture | Add-Member -MemberType NoteProperty -Name "Height" -Value $height
    $picture | Add-Member -MemberType NoteProperty -Name "Width"  -Value $width
    $picture | Add-Member -MemberType NoteProperty -Name "Ratio"  -Value ([math]::Round($ratio,3))
    $picture | Add-Member -MemberType NoteProperty -Name "Ratio_difference" -Value ([math]::abs([math]::Round($difference,3)))
    $pics.Add($picture) | Out-Null
}
