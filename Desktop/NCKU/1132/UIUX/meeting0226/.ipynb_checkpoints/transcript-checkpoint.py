from faster_whisper import WhisperModel

model = WhisperModel("large-v2")  # 使用最高準確度的 large-v2
segments, info = model.transcribe("0226_第一段.m4a", language="zh")  # 語言設定為中文

for segment in segments:
    print(f"[{segment.start:.2f}s - {segment.end:.2f}s] {segment.text}")