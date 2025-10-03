#!/usr/bin/env python3
import argparse
import os
from pathlib import Path
import urllib.request

import torch
from PIL import Image
from torchvision import transforms

DEFAULT_MODEL_PATH = "model.pt"
DEFAULT_CLASSES = "imagenet_classes.txt"


def ensure_imagenet_classes(path: Path) -> None:
    if path.exists():
        return
    url = "https://raw.githubusercontent.com/pytorch/hub/master/imagenet_classes.txt"
    print(f"[infer] Класи не знайдено, завантажую: {url}")
    urllib.request.urlretrieve(url, str(path))


def load_labels(path: Path):
    ensure_imagenet_classes(path)
    with path.open("r") as f:
        return [line.strip() for line in f.readlines()]


def build_transform():
    return transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])


def predict(model_path: Path, image_path: Path, topk: int = 3):
    model = torch.jit.load(str(model_path), map_location="cpu")
    model.eval()

    img = Image.open(image_path).convert("RGB")
    x = build_transform()(img).unsqueeze(0)

    with torch.inference_mode():
        logits = model(x)
        probs = torch.softmax(logits, dim=1)
        values, indices = torch.topk(probs, k=topk, dim=1)

    return values.squeeze(0).tolist(), indices.squeeze(0).tolist()


def main():
    parser = argparse.ArgumentParser(description="TorchScript inference (mobilenet_v2)")
    parser.add_argument("--image", required=True, help="Шлях до зображення")
    parser.add_argument("--model", default=DEFAULT_MODEL_PATH, help="Шлях до TorchScript-моделі")
    parser.add_argument("--labels", default=DEFAULT_CLASSES, help="Файл класів (imagenet_classes.txt)")
    args = parser.parse_args()

    model_path = Path(args.model)
    image_path = Path(args.image)
    labels_path = Path(args.labels)

    labels = load_labels(labels_path)
    values, indices = predict(model_path, image_path, topk=3)

    print("Top-3:")
    for rank, (p, idx) in enumerate(zip(values, indices), start=1):
        name = labels[idx] if 0 <= idx < len(labels) else f"class_{idx}"
        print(f"{rank}. {name}: {p:.4f}")


if __name__ == "__main__":
    main()

