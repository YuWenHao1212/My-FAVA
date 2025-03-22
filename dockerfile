FROM pytorch/pytorch:2.0.1-cuda11.8-cudnn8-devel

# 避免字元集問題
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# (可選) 如果你想要 Python 3.9，而映像裡預設不是 3.9:
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.9 python3.9-distutils python3.9-dev wget && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/bin/python3.9 /usr/bin/python

# 安裝 pip
RUN wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# 安裝 spaCy 英文模型
RUN python -m spacy download en_core_web_sm

COPY . .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
