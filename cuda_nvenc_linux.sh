#!/bin/bash

# ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i $f
#   -c:v hevc_nvenc -crf 15 -b:v 2M -c:a copy -map 0 $outfile


# ffmpeg -hwaccel cuda -i $f
  # -c:v hevc_nvenc -crf 15 -b:v 2M -c:a copy -map 0 $outfile

ffmpeg -hwaccel cuda -i $f -c:v hevc_nvenc -crf 15 -b:v 2M -c:a copy -map 0 $outfile
ffmpeg -hwaccel cuda -i $f -c:v hevc_nvenc -crf 15 -b:v 1M -c:a copy -map 0 $outfile


ffmpeg -hwaccel cuda -i orig.mp4 -c:v hevc_nvenc -crf 15 -b:v 2M -c:a copy -vf scale=720x406 -map 0 ./conv/nvenc.mp4
ffmpeg -hwaccel cuda -i orig.mp4 -c:v hevc_nvenc -crf 15 -b:v 1M -c:a copy -vf scale=720x480 -map 0 ./conv/nvenc.mp4
