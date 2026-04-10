FROM ubuntu:24.04

ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETOS

RUN echo "Target platform: ${TARGETPLATFORM}, arch: ${TARGETARCH}, os: ${TARGETOS}"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get \
  -o Acquire::Check-Valid-Until=false \
  -o Acquire::Check-Date=false \
  update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  apache2-dev \
  atop \
  basez \
  bat \
  bc \
  binutils\
  bison \
  bsdmainutils \
  btop \
  build-essential \
  bzip2 \
  clang \
  cmake \
  curl \
  dnsutils \
  dos2unix \
  fdisk \
  file \
  flex \
  gdb \
  git \
  git-lfs \
  htop \
  info \
  iproute2 \
  iptables \
  iptraf-ng \
  iputils-ping \
  kmod \
  language-pack-ko \
  less \
  libapr1-dev \
  libaprutil1-dev \
  libfl-dev \
  libicu-dev \
  libreadline-dev \
  libssl-dev \
  locales \
  locate \
  lsof \
  lvm2 \
  m4 \
  man-db \
  manpages \
  manpages-dev \
  manpages-posix \
  manpages-posix-dev \
  mtr \
  nasm \
  net-tools \
  netcat-openbsd \
  network-manager \
  openjdk-17-jdk \
  openssl \
  openssh-server \
  pkgconf \
  psmisc \
  python3 \
  python3-pip \
  strace \
  sudo \
  sysstat \
  tini \
  traceroute \
  tzdata \
  util-linux \
  valgrind \
  vim \
  wget \
  whois \
  yasm \
  zip \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

RUN \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid && \
    echo 'Acquire::Check-Date "false";' >> /etc/apt/apt.conf.d/99no-check-valid && \
    yes | unminimize && \
    rm /etc/apt/apt.conf.d/99no-check-valid

# git-secrets install
RUN \
  cd /tmp && \
  git clone https://github.com/awslabs/git-secrets && \
  cd git-secrets && \
  make install && \
  rm -rf /tmp/git-secrets

# 한국 시간 설정
RUN \
  ln -fs /usr/share/zoneinfo/Asia/Seoul /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata

# 한글 로케일 설정
RUN \
  dpkg-reconfigure locales && \
  locale-gen ko_KR.UTF-8 && \
  /usr/sbin/update-locale LANG=ko_KR.UTF-8 && \
  export LC_ALL=C.UTF-8 && \
  export LANGUAGE=ko_KR.UTF-8 && \
  export LANG=ko_KR.UTF-8 && \
  echo $LANG

ENV LC_ALL=C.UTF-8
ENV LANGUAGE=ko_KR.UTF-8
ENV LANG=ko_KR.UTF-8

# quarto 설치
ENV QUARTO_VERSION="1.9.36"
RUN \
  if [ "$TARGETARCH" = "amd64" ]; then \
    QUARTO_ARCH="amd64"; \
  elif [ "$TARGETARCH" = "arm64" ]; then \
    QUARTO_ARCH="arm64"; \
  else \
    echo "Not supported architecture: $TARGETARCH"; \
    exit 1; \
  fi && \
  mkdir -p /opt/quarto/${QUARTO_VERSION} && \
  curl -o quarto.tar.gz -L "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-${QUARTO_ARCH}.tar.gz" && \
  tar -zxvf quarto.tar.gz -C "/opt/quarto/${QUARTO_VERSION}" --strip-components=1 && \
  rm quarto.tar.gz && \
  ln -s /opt/quarto/${QUARTO_VERSION} /opt/quarto/current

# uv 설치
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 사용자 추가 및 설정
ARG USER=user
ARG HOME=/home/${USER}

RUN adduser --disabled-password --gecos '' ${USER}
RUN usermod -aG sudo ${USER}
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN updatedb

# SSH 서버 설정
RUN mkdir -p /run/sshd && \
    ssh-keygen -A && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SSH 키 생성 및 authorized_keys 등록
RUN mkdir -p /home/${USER}/.ssh && \
    ssh-keygen -t ed25519 -f /home/${USER}/.ssh/id_ed25519 -N "" -C "${USER}@ubuntu" && \
    cp /home/${USER}/.ssh/id_ed25519.pub /home/${USER}/.ssh/authorized_keys && \
    chmod 700 /home/${USER}/.ssh && \
    chmod 600 /home/${USER}/.ssh/authorized_keys /home/${USER}/.ssh/id_ed25519 && \
    chown -R ${USER}:${USER} /home/${USER}/.ssh && \
    cp /home/${USER}/.ssh/id_ed25519 /etc/ssh/container_id_ed25519

EXPOSE 22

WORKDIR ${HOME}
USER ${USER}

# Miniforge 설치
ENV MINIFORGE_VERSION="26.1.1-3"
ENV MINIFORGE_INSTALL_DIR="${HOME}/miniforge3"
RUN \
  if [ "$TARGETARCH" = "amd64" ]; then \
    echo "Installing x86_64 specific package..."; \
    MINIFORGE_ARCH="x86_64"; \
  elif [ "$TARGETARCH" = "arm64" ]; then \
    echo "Installing arm64 specific package..."; \
    MINIFORGE_ARCH="aarch64"; \
  else \
    echo "Not supported archtecture"; \
    exit 1; \
  fi && \
  curl -L "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-Linux-${MINIFORGE_ARCH}.sh" -o /tmp/miniforge.sh && \
  bash /tmp/miniforge.sh -b -p ${MINIFORGE_INSTALL_DIR} && \
  rm /tmp/miniforge.sh && \
  ${MINIFORGE_INSTALL_DIR}/bin/conda clean -afy

# miniforge를 모든 사용자가 사용할 수 있도록 권한 설정
RUN chmod -R 755 ${MINIFORGE_INSTALL_DIR}

# Miniforge PATH 설정
ENV PATH="${MINIFORGE_INSTALL_DIR}/bin:${PATH}"

# uv를 이용해 miniforge 환경에 패키지 설치
RUN uv pip install --python ${MINIFORGE_INSTALL_DIR}/bin/python --no-cache-dir \
  aiohttp \
  bash_kernel \
  duckdb-engine \
  fastapi \
  fastmcp \
  ipykernel \
  jsonschema \
  jupysql \
  jupyterlab \
  langchain \
  langgraph \
  mypy \
  pandas \
  poetry \
  polars \
  pre-commit \
  pydantic \
  psycopg2-binary \
  pytest \
  pyyaml \
  requests \
  ruff \
  sqlalchemy \
  websockets \
  && echo done

RUN python -m bash_kernel.install

# nvm 및 Node.js LTS 설치
ENV NVM_DIR="${HOME}/.nvm"
ENV NVM_VERSION="v0.40.4"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash && \
  . "${NVM_DIR}/nvm.sh" && \
  nvm install --lts && \
  nvm alias default lts/* && \
  nvm cache clear

# 사용자 설정 파일 복사
COPY .bashrc ${HOME}/.bashrc
COPY .gdbinit ${HOME}/.gdbinit
COPY settings.json ${HOME}/.vscode/settings.json
COPY launch.json ${HOME}/.vscode/launch.json
COPY tasks.json ${HOME}/.vscode/tasks.json

# 설정파일 권한 수정
RUN sudo chown -R ${USER}:${USER} ${HOME}/.bashrc
RUN sudo chown -R ${USER}:${USER} ${HOME}/.gdbinit
RUN sudo chown -R ${USER}:${USER} ${HOME}/.vscode

# VS Code Server 사전 설치 (SSH Remote 오프라인 사용)
# 빌드 시 --build-arg VSCODE_COMMIT=$(code --version | sed -n '2p') 로 지정 권장
# 미지정 시 최신 stable 버전 자동 다운로드
ARG VSCODE_COMMIT
RUN \
  if [ "$TARGETARCH" = "amd64" ]; then \
    VSCODE_ARCH="x64"; \
  elif [ "$TARGETARCH" = "arm64" ]; then \
    VSCODE_ARCH="arm64"; \
  else \
    echo "Not supported architecture: $TARGETARCH"; exit 1; \
  fi && \
  COMMIT="${VSCODE_COMMIT}" && \
  if [ -z "$COMMIT" ]; then \
    COMMIT=$(curl -fsSL "https://update.code.visualstudio.com/api/update/server-linux-${VSCODE_ARCH}/stable/latest" \
      | python3 -c "import sys,json; print(json.load(sys.stdin)['version'])"); \
  fi && \
  echo "Installing VS Code Server commit: $COMMIT (arch: $VSCODE_ARCH)" && \
  mkdir -p ${HOME}/.vscode-server/bin/$COMMIT && \
  curl -fsSL "https://update.code.visualstudio.com/commit:$COMMIT/server-linux-$VSCODE_ARCH/stable" \
    -o /tmp/vscode-server.tar.gz && \
  tar -xzf /tmp/vscode-server.tar.gz -C ${HOME}/.vscode-server/bin/$COMMIT --strip-components=1 && \
  rm /tmp/vscode-server.tar.gz && \
  echo "$COMMIT" > ${HOME}/.vscode-server/.version

# VS Code Remote 확장 사전 설치 (한 줄에 하나씩)
ARG VSCODE_EXTENSIONS="\
13xforever.language-x86-64-assembly \
dbaeumer.vscode-eslint \
DotJoshJohnson.xml \
janisdd.vscode-edit-csv \
mcu-debug.memory-view \
mhutchie.git-graph \
moshfeu.compare-folders \
ms-azuretools.vscode-containers \
ms-kubernetes-tools.vscode-kubernetes-tools \
ms-python.black-formatter \
ms-python.python \
ms-python.vscode-pylance \
ms-toolsai.jupyter \
ms-toolsai.vscode-jupyter-cell-tags \
ms-vscode-remote.remote-containers \
ms-vscode.cpp-devtools \
ms-vscode.cpptools \
ms-vscode.cpptools-extension-pack \
ms-vscode.cpptools-themes \
ms-vscode.hexeditor \
redhat.java \
redhat.vscode-xml \
redhat.vscode-yaml \
rust-lang.rust-analyzer \
samuel-weinhardt.vscode-jsp-lang \
vadimcn.vscode-lldb \
vscjava.vscode-java-debug \
vscjava.vscode-java-dependency \
vscjava.vscode-java-pack \
vscjava.vscode-maven \
"
RUN \
  COMMIT=$(cat ${HOME}/.vscode-server/.version) && \
  if [ -n "${VSCODE_EXTENSIONS}" ]; then \
    echo "Installing VS Code extensions: ${VSCODE_EXTENSIONS}"; \
    mkdir -p ${HOME}/.vscode-server/extensions && \
    for ext in ${VSCODE_EXTENSIONS}; do \
      [ -z "$ext" ] && continue; \
      ${HOME}/.vscode-server/bin/$COMMIT/bin/code-server \
        --extensions-dir ${HOME}/.vscode-server/extensions \
        --install-extension "$ext" \
        --force; \
    done; \
  else \
    echo "No VS Code extensions specified. Skip preinstall."; \
  fi

# CodeLLDB 플랫폼 패키지 사전 설치
# bootstrap 확장(vadimcn.vscode-lldb)은 첫 실행 시 GitHub에서 플랫폼 패키지를 내려받는데,
# 온프라미스/오프라인 환경에서 타임아웃이 나지 않도록 동일 버전의 platform VSIX를 미리 설치한다.
RUN \
  COMMIT=$(cat ${HOME}/.vscode-server/.version) && \
  LLDB_EXT_DIR=$(ls -d ${HOME}/.vscode-server/extensions/vadimcn.vscode-lldb-* 2>/dev/null | head -n 1 || true) && \
  if [ -n "$LLDB_EXT_DIR" ]; then \
    LLDB_VERSION=$(basename "$LLDB_EXT_DIR" | sed 's/^vadimcn\.vscode-lldb-//') && \
    if [ "$TARGETARCH" = "amd64" ]; then \
      LLDB_ARCH="x64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      LLDB_ARCH="arm64"; \
    else \
      echo "Skipping CodeLLDB platform preinstall: unsupported arch $TARGETARCH"; \
      exit 0; \
    fi && \
    LLDB_VSIX_URL="https://github.com/vadimcn/codelldb/releases/download/v${LLDB_VERSION}/codelldb-linux-${LLDB_ARCH}.vsix" && \
    echo "Installing CodeLLDB platform package from ${LLDB_VSIX_URL}" && \
    curl -fsSL "${LLDB_VSIX_URL}" -o /tmp/codelldb-platform.vsix && \
    ${HOME}/.vscode-server/bin/$COMMIT/bin/code-server \
      --extensions-dir ${HOME}/.vscode-server/extensions \
      --install-extension /tmp/codelldb-platform.vsix \
      --force && \
    rm -f /tmp/codelldb-platform.vsix; \
  else \
    echo "CodeLLDB extension not present in VSCODE_EXTENSIONS. Skip platform preinstall."; \
  fi

ENTRYPOINT ["tini", "--"]
USER root
CMD ["/usr/sbin/sshd", "-D"]
