# 使用指定的 CUDA 11.8 開發版 Ubuntu 22.04 作為基底
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# 環境變數：避免安裝過程中交互式介面干擾
ARG DEBIAN_FRONTEND=noninteractive

# 1. 安裝 Python 3.9 及相關工具
#    Ubuntu 22.04 預設 Python3 為3.10，故使用 deadsnakes PPA 來安裝3.9
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && apt-get update && \
    apt-get install -y python3.9 python3.9-dev python3.9-distutils curl

# 建立 python 指令的連結到 3.9版，並安裝最新 pip
RUN ln -s /usr/bin/python3.9 /usr/bin/python && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.9

# 安裝編譯必要套件（編譯C/C++擴充、PyTorch等可能需要）
RUN apt-get install -y build-essential git cmake

# 2. 設定工作目錄並複製專案檔案
WORKDIR /app
COPY requirements.txt ./ 
# 先安裝關鍵套件（如 PyTorch 與其 CUDA 相依），再安裝其餘 Python 相依
# 使用 PyTorch 官方提供的額外索引來安裝 torch==2.0.1（CUDA 11.8 版）&#8203;:contentReference[oaicite:4]{index=4}
RUN pip install --no-cache-dir torch==2.0.1+cu118 torchvision==0.15.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118 && \
    pip install --no-cache-dir -r requirements.txt

# 將其餘所有程式碼檔案複製進映像
COPY . . 

# 安裝 SpaCy 英文模型（供 FAVA 資料處理使用）
RUN python -m spacy download en_core_web_sm

# 3. 對外暴露 FastAPI 埠號（預設8000）
EXPOSE 8000

# 4. 啟動 FastAPI 應用（使用 Uvicorn server）
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
