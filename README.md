# summarize-youtube

yt-dlp > whisper > ollama = summarized transcript.


install by clone it, pip install and link index.sh to your local bin folder, e.g.,

    cd repo # assume you cloned it to ~/repo
    pyenv global 3.12.7 # make sure python version
    python -m virtualenv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cd ..
    ln -s repo/index.sh bin/summarize-youtube # assume you have a bin folder in your home directory


usage (say you named it `summarize-youtube`):
    
    summarize-youtube <Youtube-URL>


## Dev Memo

whisper requires python < 3.13.0. We use 3.12.7 here, and use pyenv to manage version:

    pyenv global 3.12.7
    pip install virtualenv # if it's your first time using virtualenv in this version.
    . venv/bin/activate


install whisper and yt-dlp:

    pip install git+https://github.com/openai/whisper.git
    pip install -U yt-dlp
