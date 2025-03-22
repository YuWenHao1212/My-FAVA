import os
from fastapi import FastAPI
from pydantic import BaseModel
import vllm  # FAVA 使用 vLLM 進行高效推理
# import transformers  # 如果日後需要 Transformers 可取消註解
# import torch         # PyTorch 將由 vLLM 使用，我們已在環境中安裝

# 從環境變數獲取 Hugging Face Token（若需要下載私有模型或登入資料集，可用）
HF_TOKEN = os.getenv("HF_TOKEN")
HF_WRITE_TOKEN = os.getenv("HF_WRITE_TOKEN")
if HF_TOKEN:
    # 如需要 HuggingFace 認證才能下載模型權重，可在此登入
    try:
        from huggingface_hub import login
        login(token=HF_TOKEN)
    except Exception as e:
        print("HuggingFace 登入失敗：", e)

app = FastAPI(title="FAVA Hallucination Detection API")

# 定義請求資料模型
class FAVARequest(BaseModel):
    passage: str   # 待檢測的文本
    reference: str  # 參考依據的事實文本

# 準備提示模板，與原始 HuggingFace Space 中定義相同
INPUT_PROMPT = (
    "Read the following references:\n{evidence}\n"
    "Please identify all the errors in the following text using the information in the references provided and suggest edits if necessary:\n"
    "[Text] {output}\n[Edited] "
)

# 載入 FAVA 模型（使用 HuggingFace 上的權重）。這會在啟動時自動下載模型權重並載入至 GPU。
# 如果模型需要權限，可確保上方 HF_TOKEN 已登入。
model = vllm.LLM(model="fava-uw/fava-model")  # 預設使用公開的 FAVA 模型

@app.post("/detect_edit")
async def detect_and_edit(data: FAVARequest):
    """接收輸入文本與參考資料，回傳偵測並標記後的編輯建議結果（HTML 格式）。"""
    prompt = INPUT_PROMPT.format(evidence=data.reference, output=data.passage)
    # 設定生成參數：溫度0確保輸出可重現，max_tokens設較大上限以涵蓋潛在輸出長度
    sampling_params = vllm.SamplingParams(temperature=0.0, top_p=1.0, max_tokens=500)
    outputs = model.generate([prompt], sampling_params)  # 呼叫 vLLM 進行生成
    # 提取輸出文字
    generated_text = outputs[0].outputs[0].text  # vLLM 回傳的第一個完成的文本

    # 按原始FAVA邏輯，將特殊標記替換為 HTML 標籤，以利前端顯示高亮
    result = generated_text
    result = result.replace("<mark>", "<span style='color: green; font-weight: bold;'>") \
                   .replace("</mark>", "</span>") \
                   .replace("<delete>", "<span style='color: red; text-decoration: line-through;'>") \
                   .replace("</delete>", "</span>") \
                   .replace("<entity>", "<span style='background-color: #E9A2D9; border-bottom: 1px dotted;'>") \
                   .replace("</entity>", "</span>") \
                   .replace("<relation>", "<span style='background-color: #F3B78B; border-bottom: 1px dotted;'>") \
                   .replace("</relation>", "</span>") \
                   .replace("<contradictory>", "<span style='background-color: #FFFF9B; border-bottom: 1px dotted;'>") \
                   .replace("</contradictory>", "</span>") \
                   .replace("<unverifiable>", "<span style='background-color: #B7E4F9; border-bottom: 1px dotted;'>") \
                   .replace("</unverifiable>", "</span>") \
                   .replace("<invented>", "<span style='background-color: #C4C4C4; border-bottom: 1px dotted;'>") \
                   .replace("</invented>", "</span>") \
                   .replace("<subjective>", "<span style='background-color: #F9E79F; border-bottom: 1px dotted;'>") \
                   .replace("</subjective>", "</span>")
    # 原始提示在結尾加了 "[Edited]" 標記，引導模型輸出。我們回傳結果中去掉多餘的提示部分
    result = result.strip().removeprefix("Edited:").strip()

    return {"edited_output": result}
