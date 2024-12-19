#!/usr/bin/env bash
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
venv_path="${script_dir}/venv"
whisper_model="base"
ollama_model="gemma2:9b"
show_help=0
# whisper command to use. here we use 'whisper-ctranslate2',
# because it's much faster than original whisper.
# set WHISPER to 'whisper' if you want to use original whisper.
WHISPER=whisper-ctranslate2

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l)
      ollama_model="$2"
      shift 2
      ;;
    -m)
      whisper_model="$2"
      shift 2
      ;;
    -h)
      show_help=1
      shift 1
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      # first non-opt arg as url
      if [[ -z "$URL" ]]; then
        url="$1"
      else
        OTHER_ARGS+=("$1")
      fi
      shift
      ;;
  esac
done

if [[ $show_help -eq 1 ]]; then
  echo "Usage: summarize-youtube -m <whisper_model> -l <ollama_model> [-h] URL"
  echo "Options:"
  echo "  -m <model>   Specify the whisper model name. Available modes: tiny, base, small, medium, large, turbo"
  echo "               default to 'base' if omitted."
  echo "  -l <model>   Specify the ollama model name. check ollama.com for all possible models."
  echo "               default to 'gemma2:9b' if omitted."
  echo "  -h           Show this help message."
  exit 0
fi

if [[ -f "${venv_path}/bin/activate" ]]; then
  source "${venv_path}/bin/activate"
else
  echo "Error: Virtual environment not found at ${venv_path}"
  exit 1
fi

trap "kill -- -$$; deactivate" exit # killing all process on current group on exit
trap "exit; deactivate" SIGINT SIGTERM # on ctrl-c, exit script.

echo "[summarize-youtube] STT Module : $WHISPER"
echo "[summarize-youtube] Using Model: $whisper_model"
echo "[summarize-youtube] Target URL : $url"
echo

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

$WHISPER "${outdir}/mp3/${id}.mp3" --model $whisper_model \
  --output_dir "${outdir}/transcript" || ( echo "Error: whisper transacription failed." && deactivate && exit 1 )

transcript_path="${outdir}/transcript/${id}.txt"

if [[ -f "$transcript_path" ]]; then
  (echo "以下是某影片音訊轉譯出來的逐字稿內容，請用正體中文，以三個段落以上、至少超過 300 字的規模做內容的摘要簡介。"; echo ""; cat "${outdir}/transcript/${id}.txt") | ollama run $ollama_model
else
  echo "Error: Transcription file not found: $transcript_path"
  exit 1
fi

deactivate
