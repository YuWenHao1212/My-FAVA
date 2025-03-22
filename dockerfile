# 使用符合條件的官方 PyTorch 基底映像（PyTorch 2.2.2，CUDA 11.8，含cuDNN8）
FROM pytorch/pytorch:2.2.2-cuda11.8-cudnn8-runtime

# 安裝 Python 3.9（如基底映像非 Python3.9），並將其符號連結為預設 python 執行檔
RUN apt-get update && apt-get install -y python3.9 python3.9-distutils && \
    python3.9 -m ensurepip && ln -s /usr/bin/python3.9 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

# 升級 pip 並安裝所需的 pip 套件（基底映像已包含 PyTorch，因此不重複安裝 Torch）
RUN python -m pip install --upgrade pip && \
    python -m pip install transformers spacy sentence-transformers fastapi

# 安裝 spaCy 英文模型（en_core_web_sm）
RUN python -m spacy download en_core_web_sm

# 設定工作目錄並複製應用程式程式碼
WORKDIR /app
COPY . /app

# 對外開放端口 8000
EXPOSE 8000

# 使用 uvicorn 啟動 FastAPI 應用（執行 main.py 中的 app）
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
