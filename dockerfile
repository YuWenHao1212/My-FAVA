FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

# 更新 apt 並安裝 Python3.9、相關開發套件及 pip
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

RUN apt-get update && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    apt-get install -y tzdata && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get install -y python3.9 python3.9-dev python3-pip build-essential && \
    rm -rf /var/lib/apt/lists/*


# 升級 pip 至最新版本（避免舊版 pip 潛在的相容性問題）
RUN python3.9 -m pip install --upgrade pip

# 將系統中的 `python` 和 `python3` 預設指向 Python3.9，確保後續指令使用的是 Python 3.9
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# 安裝 PyTorch（2.0.1 版，CUDA 11.8），使用 PyTorch 官方提供的額外索引以獲取對應的 CUDA 版本
RUN python3.9 -m pip install --no-cache-dir torch==2.0.1+cu118 -f https://download.pytorch.org/whl/torch_stable.html  \
    # 透過指定版本號中的 +cu118 並附帶 PyTorch 檔案索引，安裝對應 CUDA 11.8 的 GPU 版 PyTorch

# 安裝 FastAPI、Uvicorn（啟動服務用）、Transformers、Sentence-Transformers、spaCy 等套件
RUN python3.9 -m pip install --no-cache-dir fastapi uvicorn transformers sentence-transformers spacy

# 下載並安裝 spaCy 的英文模型（en_core_web_sm），以支援英文 NLP 功能
RUN python3.9 -m spacy download en_core_web_smFROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

# 避免安裝時跳出互動式介面（例如 tzdata）
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

# 更新 apt 並安裝 Python3.9、相關開發套件及 tzdata（避免卡住）
RUN apt-get update && \
    apt-get install -y tzdata && \
    apt-get install -y python3.9 python3.9-dev python3-pip build-essential && \
    rm -rf /var/lib/apt/lists/*

# 升級 pip 至最新版本（避免舊版 pip 潛在的相容性問題）
RUN python3.9 -m pip install --upgrade pip

# 將系統中的 `python` 和 `python3` 預設指向 Python3.9
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# 安裝 PyTorch（2.0.1 GPU 版，對應 CUDA 11.8）
RUN python3.9 -m pip install --no-cache-dir torch==2.0.1+cu118 -f https://download.pytorch.org/whl/torch_stable.html

# 安裝 FastAPI、Uvicorn、Transformers、spaCy、sentence-transformers 等
RUN python3.9 -m pip install --no-cache-dir fastapi uvicorn transformers sentence-transformers spacy

# 下載 spaCy 英文模型（en_core_web_sm）
RUN python3.9 -m spacy download en_core_web_sm

# 設定專案資料夾
WORKDIR /app

# 複製本機所有程式碼進到容器中
COPY . .

# 開放 FastAPI 埠號
EXPOSE 8000

# 啟動 FastAPI 主程式
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]


# 設定工作目錄（將您的應用程式程式碼放置於此，例如 main.py）
WORKDIR /app

# 將容器埠 8000 暴露出來（FastAPI 默認埠），設定啟動容器時用 Uvicorn 執行 FastAPI 應用
# 假設 FastAPI 應用的實例名稱為 app，定義在 /app/main.py 中
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
