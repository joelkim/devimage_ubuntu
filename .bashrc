# ~/.bashrc

# miniforge PATH (인터랙티브 체크 전에 설정해야 비대화형 셸에서도 적용됨)
export PATH="$HOME/miniforge3/bin:$PATH"

# interactive shell이 아니면 종료
case $- in
    *i*) ;;
      *) return;;
esac

# 히스토리 설정
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# 윈도우 크기 자동 조절
shopt -s checkwinsize

# 프롬프트 설정
PS1='$ '

# 디렉토리별 색상 설정
export LS_COLORS="$LS_COLORS:ow=1;34:tw=1;34"

# ls 색상
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# grep 색상
alias grep='grep --color=auto'

# Miniforge 설정
if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniforge3/etc/profile.d/conda.sh"
fi

# nvm 설정
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Quarto PATH
export PATH="/opt/quarto/current/bin:$PATH"

# C/C++ 컴파일러 플래그 설정
export CFLAGS="-Wall -g"
export CXXFLAGS="-Wall -g -std=c++17"

# 로컬 저장소가 아닌 global 설정으로 저장
git config --global core.checkStat minimal
git config --global core.fileMode false
git config --global core.ignoreCase true
git config --global core.autocrlf input
