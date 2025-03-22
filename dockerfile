# 使用 PyTorch 官方映像 (含 CUDA 11.8, cuDNN 8, PyTorch 2.0.1)
FROM pytorch/pytorch:2.0.1-cuda11.8-cudnn8-devel

# 避免字符集問題
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# 更新套件庫並安裝必要工具 (若需要)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.9-distutils wget build-essential git && \
    rm -rf /var/lib/apt/lists/*

# 安裝 pip (若映像內沒預裝最新 pip)
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