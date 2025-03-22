# 使用適用於 GPU 的 CUDA 11.8 基礎映像檔與 PyTorch 開發工具
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

# 安裝 Python 3.9 和開發工具
RUN apt-get update && apt-get install -y \
    python3.9 python3.9-dev python3.9-distutils \
    build-essential cmake git git-lfs curl \
 && rm -rf /var/lib/apt/lists/*

# 安裝 Python 3.9 的 pip
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3.9 get-pip.py && \
    rm get-pip.py

# 克隆 FAVA 儲存庫
RUN git clone https://github.com/abhika-m/FAVA.git /workspace/FAVA
WORKDIR /workspace/FAVA

# 安裝 PyTorch（對應 CUDA 11.8 的版本）及其他需求
RUN python3.9 -m pip install --no-cache-dir \
    torch==2.0.1+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118/torch_stable.html

# 安裝 FlashAttention（flash-attn），以 GPU 支援方式進行安裝
RUN MAX_JOBS=4 python3.9 -m pip install --no-cache-dir \
    flash-attn==2.1.1 --no-build-isolation

# 安裝其餘 Python 依賴項
RUN sed -i '/torch==/d' requirements.txt && sed -i '/flash-attn==/d' requirements.txt && \
    python3.9 -m pip install --no-cache-dir -r requirements.txt

# 下載 spaCy 的英文模型
RUN python3.9 -m spacy download en_core_web_sm

# 開放相關的端口（如果 FAVA 啟動了 API 服務，則使用 8000 端口）
EXPOSE 8000

# 定義默認命令（可根據需要覆蓋）
CMD ["bash"]
