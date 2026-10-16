# Blender моделі

`build_roof_props.py` будує low-poly будівлі для даху (сховище, генератор, фільтр, пульт мосту):

```
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --factory-startup --python blender/build_roof_props.py
```

Результат:
- `assets/models/RoofProps.fbx` — для імпорту в Studio;
- `blender/RoofProps.blend` — джерело, можна відкрити й правити руками;
- `assets/previews/RoofProps.png` — прев'ю.

Кожна деталь називається `<Будівля>_<Частина>_<Фарба>`. Колір і матеріал у грі беруться з `<Фарба>` (таблиця `PROP_PAINTS` у `WorldBuilder.luau`), текстури не потрібні.

## Як моделі потрапляють у гру

Roblox приймає меші тільки через Studio, тому один раз:

1. Studio → вкладка **Home** → **Import** (3D Importer) → вибрати `assets/models/RoofProps.fbx` → **Import**.
2. У Explorer правий клік по імпортованій моделі → **Save to File…** → `C:\Roblox\assets\models\RoofProps.rbxm`.
3. Проєкт Rojo кладе цей файл у `ReplicatedStorage.Models`, а `WorldBuilder` ставить моделі на місце сірих коробок.

Якщо `ReplicatedStorage.Models` немає, гра працює зі звичайними сірими блоками.
