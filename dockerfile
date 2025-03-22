# 使用 NVIDIA 官方 devel 映像，內含 CUDA 11.8 與 cuDNN 8，適合 A100（Ampere）
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# 設定非互動式安裝與台北時區，避免安裝 tzdata 時卡住
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

# 更新套件庫並安裝基礎工具（含 Python3、pip、git、編譯器等）
RUN apt-get update && \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    apt-get install -y tzdata python3 python3-pip git build-essential ninja-build && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    ln -sf /usr/bin/python3 /usr/bin/python && ln -sf /usr/bin/pip3 /usr/bin/pip && \
    pip install --no-cache-dir --upgrade pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 設定 CUDA 與 PyTorch 相關環境變數，確保編譯 GPU 擴充套件時正確偵測到 CUDA
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV FORCE_CUDA=1
ENV TORCH_CUDA_ARCH_LIST="8.0"

# 安裝所有 FAVA 所需的 Python 套件（一次完成，避免多層浪費）
# 先安裝 wheel、packaging 等基礎，再安裝 torch==2.0.1+cu118，最後安裝其餘依賴
RUN pip install --no-cache-dir wheel packaging && \
    pip install --no-cache-dir torch==2.0.1+cu118 && \
    pip install --no-cache-dir \
      accelerate==0.21.0 \
      deepspeed==0.10.1 \
      flash-attn==2.1.1 \
      jsonlines==3.1.0 \
      nltk==3.8.1 \
      numpy==1.24.4 \
      openai==0.27.8 \
      protobuf==4.24.0 \
      safetensors==0.3.2 \
      sentence-transformers==2.2.2 \
      sentencepiece==0.1.99 \
      spacy==2.2.4 \
      tiktoken==0.5.1 \
      tokenizers==0.15.0 \
      tqdm==4.66.1 \
      transformers==4.35.2 \
      uvicorn==0.23.2 \
      vllm==0.2.1.post1

# 下載 spaCy 英文模型（2.2.4 版對應的 en_core_web_sm）
# 若 spacy==2.2.4 無法直接安裝 en_core_web_sm 3.x 版，可手動安裝對應版本
RUN python -m spacy download en_core_web_sm

# 將容器的工作目錄設為 /app，並複製本機程式碼到容器內
WORKDIR /app
COPY . /app

# 對外開放埠 80（可在 vast.ai 模板中自行指定對映）
EXPOSE 80

# 容器啟動時執行 uvicorn，假設 main.py 裡有 app = FastAPI()
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
