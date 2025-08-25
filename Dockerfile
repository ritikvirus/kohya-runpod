# syntax=docker/dockerfile:1.6
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    WORKSPACE=/workspace \
    KOHYA_DIR=/opt/kohya_ss \
    VENV_DIR=/opt/venv \
    PORT=7860 \
    GRADIO_SERVER_NAME=0.0.0.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl ca-certificates tini ffmpeg \
    python3 python3-venv python3-pip \
    libgl1 libglib2.0-0 jq && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv ${VENV_DIR} && ${VENV_DIR}/bin/pip install --upgrade pip wheel

# PyTorch matching CUDA 12.4 wheels
RUN ${VENV_DIR}/bin/pip install --index-url https://download.pytorch.org/whl/cu124 \
    torch torchvision torchaudio

# Kohya GUI
RUN git clone --depth=1 https://github.com/bmaltais/kohya_ss.git ${KOHYA_DIR}

# Dependencies (lenient: don't fail the build if optional files aren't present)
RUN ${VENV_DIR}/bin/pip install -r ${KOHYA_DIR}/requirements_linux.txt || true && \
    ${VENV_DIR}/bin/pip install -r ${KOHYA_DIR}/requirements_runpod.txt || true && \
    ${VENV_DIR}/bin/pip install xformers || true && \
    ${VENV_DIR}/bin/pip install bitsandbytes || true

# Default folders and configs
RUN mkdir -p ${WORKSPACE}/SARAHJACKSON/training_data/{img,log,model} \
           ${KOHYA_DIR}/models ${KOHYA_DIR}/configs/presets
COPY configs/config.toml ${KOHYA_DIR}/config.toml

# Startup scripts
COPY start.sh /start.sh
COPY entrypoint.sh /opt/entrypoint.sh
COPY scripts/download_models.sh /opt/download_models.sh
COPY scripts/download_presets.sh /opt/download_presets.sh
RUN chmod +x /start.sh /opt/entrypoint.sh /opt/download_models.sh /opt/download_presets.sh

WORKDIR ${WORKSPACE}
EXPOSE 7860
ENTRYPOINT ["/usr/bin/tini","-g","--"]
CMD ["/start.sh"]
