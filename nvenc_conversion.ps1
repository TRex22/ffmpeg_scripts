function Get-TotalBitrate( $file ) {
  $shellObject = New-Object -ComObject Shell.Application
  $bitrateAttribute = 0

  # Get a shell object to retrieve file metadata.
  $directoryObject = $shellObject.NameSpace( $file.Directory.FullName )
  $fileObject = $directoryObject.ParseName( $file.Name )

  # Find the index of the bit rate attribute, if necessary.
  for( $index = 5; -not $bitrateAttribute; ++$index ) {
    $name = $directoryObject.GetDetailsOf( $directoryObject.Items, $index )
    if( $name -eq 'Total bitrate' ) { $bitrateAttribute = $index }
  }

  # Get the bit rate of the file.
  $bitrateString = $directoryObject.GetDetailsOf( $fileObject, $bitrateAttribute )
  if( $bitrateString -match '\d+' ) { [int]$bitrate = $matches[0] }
  else { $bitrate = -1 }

  # If the file has the desired bit rate, include it in the results.
  return $bitrate
}

function Get-FFMpeg_Video_Bitrate($totalBitrate) {
  if ($totalBitrate -gt 3000) {
    return "2M" # Limit max bit-rate. Will have noticeable quality dip for super hi-res
  }

  if ($totalBitrate -gt 2000) {
    return "2M"
  }

  if ($totalBitrate -gt 1000) {
    return "1M"
  }

  return 0
}

function Compress-Video($directory, $output_directory) {
  Param ($directory, $output_directory)

  $files = Get-ChildItem -Include @("*.mp4", "*.avi", "*.divx", "*.mov", "*.mpg", "*.wmv", "*.mkv", "*.flv", "*.m3u8") -Path $directory -Recurse; # -Recurse

  foreach ($f in $files){
    $outfile = $output_directory + '\' + $f.Name
    $bitrate = Get-TotalBitrate($f)
    $bitrateStr = Get-FFMpeg_Video_Bitrate($bitrate)

    if ($bitrateString -ne 0) {
      ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i $f -c:v hevc_nvenc -crf 15 -b:v $bitrateStr $outfile

      $finalfile = Get-ChildItem -LiteralPath $outfile
      $finalfile.CreationTime = $f.CreationTime
      $finalfile.LastWriteTime = $f.LastWriteTime
      $finalfile.LastAccessTime = $f.LastAccessTime

      if ($finalfile.Length -gt $f.Length) {
        echo 'Too Big!'
        rm $outfile
      }
    }
  }
}

$directory = "$pwd"
$output_directory = "$pwd"
Compress-Video($directory, $output_directory)
