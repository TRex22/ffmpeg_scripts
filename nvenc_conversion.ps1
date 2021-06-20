function Get-FileBitrate( $file ) {
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

function Get-FileDataRate( $file ) {
  $shellObject = New-Object -ComObject Shell.Application
  $bitrateAttribute = 0

  # Get a shell object to retrieve file metadata.
  $directoryObject = $shellObject.NameSpace( $file.Directory.FullName )
  $fileObject = $directoryObject.ParseName( $file.Name )

  # Find the index of the bit rate attribute, if necessary.
  for( $index = 5; -not $bitrateAttribute; ++$index ) {
    $name = $directoryObject.GetDetailsOf( $directoryObject.Items, $index )
    if( $name -eq 'Data rate' ) { $bitrateAttribute = $index }
  }

  # Get the bit rate of the file.
  $bitrateString = $directoryObject.GetDetailsOf( $fileObject, $bitrateAttribute )
  if( $bitrateString -match '\d+' ) { [int]$bitrate = $matches[0] }
  else { $bitrate = -1 }

  # If the file has the desired bit rate, include it in the results.
  return $bitrate
}

function Get-FFMpeg_Video_Bitrate_Str($totalBitrate) {
  if ($totalBitrate -gt 1000 -And $totalBitrate -lt 2000) {
    return "1M"
  }

  # Limit max bit-rate. Will have noticeable quality dip for super hi-res
  return "2M"
}

function Get-VideoEncoding($filePath) {
  $encoding = ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 $filePath
  return $encoding
}

function Get-VideoBitrate($filePath) {
  # N/A or 1012685 1012_685
  $bitrate = ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=nokey=1:noprint_wrappers=1 $filePath

  if ($bitrate -eq "N/A") {
    return -1
  }

  return [int]$bitrate/1000
}

function Get-VideoDuration($filePath) {
  $duration = ffprobe -v error -select_streams v:0 -show_entries format=duration -of default=nokey=1:noprint_wrappers=1 $filePath
  return $duration
}

function Get-ApproxBitrate($filePath) {
  $duration = Get-VideoDuration($filePath)
  $fileChild = Get-ChildItem -LiteralPath $filePath
  $approxBitrate = (($fileChild.length * 8)/1KB) / [double]$duration
  return $approxBitrate
}

function Get-Bitrate($filePath) {
  $videoBitrate = Get-VideoBitrate($filePath)
  $fileChild = Get-ChildItem -LiteralPath $filePath
  $bitrate = Get-FileBitrate($fileChild)
  $datarate = Get-FileDataRate($fileChild)
  $approxBitrate = Get-ApproxBitrate($filePath)

  if ($videoBitrate -ne 'N/A' -and $videoBitrate -gt 1000) {
    echo 'Using video bitrate'
    return [int]$videoBitrate
  }

  if ($bitrate -ne "" -and $bitrate -gt 1000) {
    echo 'Using file bitrate'
    return [int]$bitrate
  }

  if ($datarate -ne "" -and $datarate -gt 1000) {
    echo 'Using video data bitrate'
    return [int]$datarate
  }

  echo 'Using approximate bitrate'
  return [int]$approxBitrate
}

function Compress-Video($directory, $output_directory) {
  # Param ($directory, $output_directory)

  $fileSizeLimit = 250MB
  $bitrateLimit = 1000 # 1012685

  $files = Get-ChildItem -Include @("*.mp4", "*.avi", "*.divx", "*.mov", "*.mpg", "*.wmv", "*.mkv", "*.flv", "*.m3u8") -Path $directory -Recurse; # -Recurse

  foreach ($f in $files){
    $outfile = 'G:\tmp\win8\converted' + '\' + $f.Name #$output_directory + '\' + $f.Name

    $bitrate = Get-Bitrate($f)
    $bitrateStr = Get-FFMpeg_Video_Bitrate_Str($bitrate, $datarate)

    echo $bitrate

    if ($bitrateStr -ne "NULL" -And $bitrate -gt $bitrateLimit -And $f.length -gt $fileSizeLimit) {
      ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i $f -c:v hevc_nvenc -crf 15 -b:v $bitrateStr -c:a copy -map 0 $outfile

      $finalfile = Get-ChildItem -LiteralPath $outfile
      $finalfile.CreationTime = $f.CreationTime
      $finalfile.LastWriteTime = $f.LastWriteTime
      $finalfile.LastAccessTime = $f.LastAccessTime

      if ($finalfile.Length -gt $f.Length) {
        echo 'Too Big!'
        # rm $outfile
        Remove-Item -LiteralPath $outfile
      }
    }
  }
}

$directory = "$pwd"
$output_directory = "$pwd"
Compress-Video($directory, $output_directory)


$directory = "Z:\server_share\tmp\New folder\win8prev\Best"
