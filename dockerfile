# 使用 PyTorch 官方映像 (含 CUDA 11.8, cuDNN 8, PyTorch 2.0.1 GPU 版)
FROM anibali/pytorch:2.0.1-cuda11.8-ubuntu22.04

# 避免字元集問題
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# 安裝 Python 3.9 及必要工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.9 python3.9-distutils python3.9-dev wget build-essential git && \
    rm -rf /var/lib/apt/lists/*

# 讓 python 指令預設執行 Python 3.9
RUN ln -sf /usr/bin/python3.9 /usr/bin/python

# 安裝最新 pip (for Python 3.9)
RUN wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

# 設定工作目錄
WORKDIR /app

# 複製 requirements.txt 並安裝套件 (已移除 torch 依賴)
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 安裝 spaCy 英文模型 (FAVA 需要)
RUN python -m spacy download en_core_web_sm

# 複製專案檔案 (含 main.py、其他 FAVA 檔案)
COPY . .

# 對外暴露 FastAPI 服務埠
EXPOSE 8000

# 以 Uvicorn 啟動 FastAPI 應用
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]