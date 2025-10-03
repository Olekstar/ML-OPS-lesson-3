# Lesson 3: Контейнеризація ML-моделі (TorchScript + Docker)

Цей проєкт демонструє підготовку TorchScript-моделі (`mobilenet_v2`), створення простого inference-сервісу та побудову двох Docker-образів: важкого (fat) і оптимізованого (slim).

## Вимоги
- Docker (Compose не обов'язково для цього завдання)
- Python 3.9+
- Інтернет для завантаження ваг і класів ImageNet

За потреби запустіть ідемпотентний скрипт підготовки середовища:
```bash
bash install_dev_tools.sh
```

## 1) Експорт TorchScript-моделі
Згенеруйте `model.pt` (TorchScript) та файл класів `imagenet_classes.txt`:
```bash
python export_model.py
```
Після виконання в каталозі `lesson-3/` з'явиться `model.pt`. Цей файл потрібен для збірки Docker-образів.

## 2) Локальний inference (поза контейнером)
```bash
python inference.py --image ./sample.jpg --model ./model.pt
```
Вивід міститиме топ-3 класи з імовірностями.

## 3) Збірка Docker-образів
Перед збіркою переконайтесь, що `model.pt` існує в `lesson-3/`.

- Fat-образ:
```bash
docker build -f Dockerfile.fat -t ml-infer-fat:latest .
```

- Slim-образ (multi-stage):
```bash
docker build -f Dockerfile.slim -t ml-infer-slim:latest .
```

## 4) Запуск контейнерів
Для прикладу використайте будь-яке зображення, наприклад `sample.jpg` у поточній папці.

- Fat:
```bash
docker run --rm -v $(pwd):/app -w /app ml-infer-fat:latest \
  python3 inference.py --image /app/lesson-3/sample.jpg --model /app/lesson-3/model.pt
```

- Slim:
```bash
docker run --rm -v $(pwd):/app -w /app ml-infer-slim:latest \
  python3 inference.py --image /app/lesson-3/sample.jpg --model /app/lesson-3/model.pt
```

## 5) Порівняння образів
Після збірки заповніть `comparison.txt` або `report.md`:
- Розмір образів
- Кількість шарів
- Наявність зайвих інструментів
- Ідеї подальшої оптимізації

Корисні команди:
```bash
docker images | grep ml-infer-
docker history ml-infer-fat:latest
docker history ml-infer-slim:latest
```

## Структура
```
lesson-3/
├── inference.py
├── export_model.py
├── model.pt             # згенерувати через export_model.py
├── Dockerfile.fat
├── Dockerfile.slim
├── install_dev_tools.sh
├── comparison.txt
└── README.md
```

