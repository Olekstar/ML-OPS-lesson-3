#!/usr/bin/env python3
import os
import sys
import urllib.request
from pathlib import Path

import torch
import torchvision
from torchvision import transforms

THIS_DIR = Path(__file__).resolve().parent
MODEL_OUT = THIS_DIR / "model.pt"
CLASSES_TXT = THIS_DIR / "imagenet_classes.txt"


def ensure_imagenet_classes(target_path: Path) -> None:
    if target_path.exists():
        return
    url = "https://raw.githubusercontent.com/pytorch/hub/master/imagenet_classes.txt"
    print(f"[export] Завантажую ImageNet класи з {url}")
    urllib.request.urlretrieve(url, str(target_path))


def get_model() -> torch.nn.Module:
    try:
        # Новіша API з enum ваг
        weights = torchvision.models.MobileNet_V2_Weights.DEFAULT
        model = torchvision.models.mobilenet_v2(weights=weights)
    except Exception:
        # Стара API
        model = torchvision.models.mobilenet_v2(pretrained=True)
    model.eval()
    return model


def main() -> int:
    ensure_imagenet_classes(CLASSES_TXT)

    model = get_model()
    example = torch.randn(1, 3, 224, 224)

    print("[export] Трасую модель (torch.jit.trace)...")
    with torch.inference_mode():
        scripted = torch.jit.trace(model, example)
        scripted = torch.jit.optimize_for_inference(scripted)

    MODEL_OUT.parent.mkdir(parents=True, exist_ok=True)
    scripted.save(str(MODEL_OUT))
    print(f"[export] TorchScript збережено у: {MODEL_OUT}")
    print("Готово.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

