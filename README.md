# summarize-youtube

yt-dlp > whisper > ollama = summarized transcript.


## Prerequisite

 - This script is written in bash script and is expected to be run under MacOS or linux.
 - Ollama is a prerequisite so you have to install it manually. The model `gemma2:9b` is used in `index.sh`.


## Installation

Install by cloning this repo, `pip install` and link `index.sh` to your local `bin` folder, e.g.,

    cd repo # assume you cloned it to ~/repo
    pyenv global 3.12.7 # make sure python version
    python -m virtualenv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cd ..
    ln -s repo/index.sh bin/summarize-youtube # assume you have a bin folder in your home directory


usage (say you named it `summarize-youtube`):
    
    summarize-youtube <Youtube-URL>

Intermediate files are stored under `/tmp/.summarize-youtube-out/`.


## Dev Memo

whisper requires python < 3.13.0. We use 3.12.7 here, and use pyenv to manage version:

    pyenv global 3.12.7
    pip install virtualenv # if it's your first time using virtualenv in this version.
    . venv/bin/activate


install whisper and yt-dlp:

    pip install git+https://github.com/openai/whisper.git
    pip install -U yt-dlp


## License

MIT
