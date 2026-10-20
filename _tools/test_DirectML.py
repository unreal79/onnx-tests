import time
import os
from pathlib import Path
import numpy as np
import onnxruntime as ort

print("Available providers:", ort.get_available_providers())

# 1. Loading the model and adding the DML (DirectML) provider
# model = {"path": "../models/bg_remove/BiRefNet_512x512_fp16.onnx", "height": 512, "width": 512}
model = {"path": "../models/bg_remove/u2netp.onnx", "height": 320, "width": 320}
options = ort.SessionOptions()

# Important: when using DirectML, memory pattern should be disabled,
# and execution mode should be sequential.
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
    # For most ONNX U2Net models, format is: [1, 3, H, W]
    h = model["height"]
    w = model["width"]
    c = 3
    return np.random.randn(1, c, h, w).astype(np.float32)

# 3. Testing on a single image
img = make_image_tensor()
start = time.perf_counter()
outputs = session.run(None, {input_name: img})
elapsed = time.perf_counter() - start
print(f"Single {model['height']}x{model['width']} image processing time:", round(elapsed, 3), "s")
print("Output tensors:", len(outputs))
print("Output[0].shape:", outputs[0].shape) # type: ignore

# 4. Heavy load: multiple sequential images
# Important: the model expects batch=1, so we use repeated single-image runs.
# for run_index in range(1, 2):
#     img = make_image_tensor()
#     start = time.perf_counter()
#     out = session.run(None, {input_name: img})
#     elapsed = time.perf_counter() - start
#     print(f"Stress run {run_index}: time={elapsed:.4f}s, out_shape={out[0].shape}") # type: ignore
