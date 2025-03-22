import os
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv

# 讀取 .env 中的環境變數（如 OPENAI_API_KEY, HF_TOKEN）
load_dotenv()

# 若需要 Hugging Face Token 下載私有模型，確保 token 已寫入環境變數
hf_token = os.getenv("HF_TOKEN")
if hf_token:
    os.environ["HF_TOKEN"] = hf_token

# 載入 vLLM
from vllm import LLM, SamplingParams

app = FastAPI()

class VerifyRequest(BaseModel):
    evidence: str
    output: str

class VerifyResponse(BaseModel):
    edited_text: str

# 載入 FAVA 模型，若需要 Hugging Face 認證，會自動使用 HF_TOKEN
fava_model = LLM(model="fava-uw/fava-model")

sampling_params = SamplingParams(
    temperature=0.0,
    top_p=1.0,
    max_tokens=1024,
)

prompt_template = (
    "Read the following references:\n{evidence}\n"
    "Please identify all the errors in the following text using the information in the references provided and suggest edits if necessary:\n"
    "[Text] {output}\n[Edited] "
)

@app.post("/verify", response_model=VerifyResponse)
def verify_text(request: VerifyRequest):
    prompt = prompt_template.format(evidence=request.evidence, output=request.output)
    outputs = fava_model.generate([prompt], sampling_params)
    edited_text = outputs[0].outputs[0].text
    return VerifyResponse(edited_text=edited_text)