#!/usr/bin/env bash
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
venv_path="${script_dir}/venv"

if [[ -f "${venv_path}/bin/activate" ]]; then
  source "${venv_path}/bin/activate"
else
  echo "Error: Virtual environment not found at ${venv_path}"
  exit 1
fi

trap "kill -- -$$; deactivate" exit # killing all process on current group on exit
trap "exit; deactivate" SIGINT SIGTERM # on ctrl-c, exit script.

input="$1"

if [[ "$input" =~ ^https?://(www\.)?youtube\.com/watch\?v=([^&]+) ]]; then
  id="${BASH_REMATCH[2]}"
else
  id="$input"
fi


# 如果 ID 為空，終止程式並顯示錯誤訊息
if [[ -z "$id" ]]; then
  echo "Error: YouTube ID is empty. Please provide a valid URL or ID."
  deactivate
  exit 1
fi

outdir="/tmp/.summarize-youtube-out/$id"

if ! command -v ollama &>/dev/null; then
  echo "Error: ollama command not found."
  deactivate
  exit 1
fi

mkdir -p "${outdir}/mp3"
yt-dlp -f bestaudio --extract-audio --audio-format mp3 -o "${outdir}/mp3/%(id)s.mp3" \
  "https://www.youtube.com/watch?v=${id}" || ( echo "Error: failed to download audio." && deactivate && exit 1 )

whisper "${outdir}/mp3/${id}.mp3" --model base \
  --output_dir "${outdir}/transcript" || ( echo "Error: whisper transacription failed." && deactivate && exit 1 )

transcript_path="${outdir}/transcript/${id}.txt"

if [[ -f "$transcript_path" ]]; then
  (echo "以下是某影片音訊轉譯出來的逐字稿內容，請用正體中文，以三個段落、約 300 字的規模做內容的摘要簡介。"; echo ""; cat "${outdir}/transcript/${id}.txt") | ollama run gemma2:9b
else
  echo "Error: Transcription file not found: $transcript_path"
  exit 1
fi

deactivate
