#!/bin/bash
# Ubuntu 커스텀 이미지를 amd64/arm64 멀티 플랫폼으로 빌드하고
# Docker Hub에 날짜 태그 및 latest 태그로 푸시하는 스크립트
set -e

# 빌드 로그를 파일에도 기록 (stdout/stderr 동시 출력)
LOG_FILE="build.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "===== 빌드 시작: $(date '+%Y-%m-%d %H:%M:%S') ====="

# podman machine의 시스템 시간이 틀리면 apt 패키지 서명 검증 실패 등의 오류가 발생함
echo 실행전 podman machine의 시간 동기화 필요
echo podman machine stop
echo podman machine start
echo podman machine ssh date


# 이미지 태그: 빌드 날짜 (예: 20260409)
TAG=$(date +%Y%m%d)
IMAGE="docker.io/joelkim/ubuntu"

# VS Code Remote SSH 오프라인 사용을 위해 로컬 VS Code 커밋 해시를 빌드 인수로 전달
# 로컬 VS Code 버전과 이미지 내 서버 버전이 일치해야 재다운로드 없이 바로 연결됨
VSCODE_COMMIT=$(code --version 2>/dev/null | sed -n '2p')
if [ -z "$VSCODE_COMMIT" ]; then
  echo "경고: VS Code 커밋 해시를 가져올 수 없습니다. 최신 stable 버전으로 설치됩니다."
  BUILD_ARG=""
else
  echo "VS Code 커밋 해시: $VSCODE_COMMIT"
  BUILD_ARG="--build-arg VSCODE_COMMIT=${VSCODE_COMMIT}"
fi

# amd64/arm64 각각 빌드
podman build --os linux --arch amd64 ${BUILD_ARG} -t ${IMAGE}:${TAG}-amd64 .
podman build --os linux --arch arm64 ${BUILD_ARG} -t ${IMAGE}:${TAG}-arm64 .

# 각 아키텍처 이미지 푸시
podman push ${IMAGE}:${TAG}-amd64
podman push ${IMAGE}:${TAG}-arm64

# 날짜 태그 멀티 플랫폼 매니페스트 생성 및 푸시
podman manifest rm ${IMAGE}:${TAG} 2>/dev/null || true
podman manifest create ${IMAGE}:${TAG}
podman manifest add ${IMAGE}:${TAG} ${IMAGE}:${TAG}-amd64
podman manifest add ${IMAGE}:${TAG} ${IMAGE}:${TAG}-arm64
podman manifest push --all ${IMAGE}:${TAG} ${IMAGE}:${TAG}

# latest 태그 멀티 플랫폼 매니페스트 생성 및 푸시
podman rmi ${IMAGE}:latest 2>/dev/null || true
podman manifest rm ${IMAGE}:latest 2>/dev/null || true
podman manifest create ${IMAGE}:latest
podman manifest add ${IMAGE}:latest ${IMAGE}:${TAG}-amd64
podman manifest add ${IMAGE}:latest ${IMAGE}:${TAG}-arm64
podman manifest push --all ${IMAGE}:latest ${IMAGE}:latest

echo "===== 빌드 완료: $(date '+%Y-%m-%d %H:%M:%S') ====="
