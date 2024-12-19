#!/usr/bin/env bash
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
venv_path="${script_dir}/venv"
model="base"
show_help=0

while getopts "m:h" opt; do
  case "$opt" in
    m)
      model="$OPTARG"
      ;;
    h)
      show_help=1
      ;;
    *)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

if [[ $show_help -eq 1 ]]; then
  echo "Usage: $0 -m <model> [-h]"
  echo "Options:"
  echo "  -m <model>   Specify the model name. Available modes: tiny, base, small, medium, large, turbo"
  echo "  -h           Show this help message."
  exit 0
fi

shift $((OPTIND - 1))
for arg in "$@"; do
  OTHER_ARGS+=("$arg")
done
url=$OTHER_ARGS

if [[ -f "${venv_path}/bin/activate" ]]; then
  source "${venv_path}/bin/activate"
else
  echo "Error: Virtual environment not found at ${venv_path}"
  exit 1
fi

trap "kill -- -$$; deactivate" exit # killing all process on current group on exit
trap "exit; deactivate" SIGINT SIGTERM # on ctrl-c, exit script.

echo "[summarize-youtube] Using Model: $model"
echo "[summarize-youtube] Target URL : $url"

if [[ "$url" =~ ^https?://(www\.)?youtube\.com/watch\?v=([^&]+) ]]; then
  id="${BASH_REMATCH[2]}"
else
  id="$url"
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

whisper "${outdir}/mp3/${id}.mp3" --model $model \
  --output_dir "${outdir}/transcript" || ( echo "Error: whisper transacription failed." && deactivate && exit 1 )

transcript_path="${outdir}/transcript/${id}.txt"

if [[ -f "$transcript_path" ]]; then
  (echo "以下是某影片音訊轉譯出來的逐字稿內容，請用正體中文，以三個段落、約 300 字的規模做內容的摘要簡介。"; echo ""; cat "${outdir}/transcript/${id}.txt") | ollama run gemma2:9b
else
  echo "Error: Transcription file not found: $transcript_path"
  exit 1
fi

deactivate
