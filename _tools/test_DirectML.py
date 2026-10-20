import time
import os
from pathlib import Path
import numpy as np
import onnxruntime as ort

print("Available providers:", ort.get_available_providers())

# 1. Загрузка модели и добавление провайдера DML (DirectML)
# model = {"path": "../models/bg_remove/BiRefNet_512x512_fp16.onnx", "height": 512, "width": 512}
model = {"path": "../models/bg_remove/u2netp.onnx", "height": 320, "width": 320}
options = ort.SessionOptions()

# Важно: при использовании DirectML память по шаблону должна быть отключена,
# а режим выполнения — последовательным.
options.enable_mem_pattern = False
options.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL

current_dir = Path(__file__).parent
model_path = os.path.abspath(current_dir / model["path"])
session = ort.InferenceSession(model_path, options, providers=['DmlExecutionProvider'])
print("Session providers:", session.get_providers())
print("The first provider in session.get_providers() is the active one used by the model:", session.get_providers()[0])

input_name = session.get_inputs()[0].name
input_shape = session.get_inputs()[0].shape

def make_image_tensor():
    # для большинства ONNX U2Net форматы: [1, 3, H, W]
    h = model["height"]
    w = model["width"]
    c = 3
    return np.random.randn(1, c, h, w).astype(np.float32)

# 3. Проверка на одном изображении
img = make_image_tensor()
start = time.perf_counter()
outputs = session.run(None, {input_name: img})
elapsed = time.perf_counter() - start
print(f"Single {model['height']}x{model['width']} image processing time:", round(elapsed, 3), "s")
print("Output tensors:", len(outputs))
print("Output[0].shape:", outputs[0].shape) # type: ignore

# 4. Серьезная нагрузка: несколько последовательных изображений
# Важно: модель ожидает batch=1, поэтому используем повторные прогоны по одному изображению.
# for run_index in range(1, 2):
#     img = make_image_tensor()
#     start = time.perf_counter()
#     out = session.run(None, {input_name: img})
#     elapsed = time.perf_counter() - start
#     print(f"Stress run {run_index}: time={elapsed:.4f}s, out_shape={out[0].shape}") # type: ignore
