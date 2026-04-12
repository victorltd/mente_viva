# Script para criar ícone do MenteViva igual ao logo da splash screen
from PIL import Image, ImageDraw
import os
import math

# Criar ícone 1024x1024
size = 1024
img = Image.new('RGBA', (size, size), color=(0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Cores do gradiente (igual ao AppColors.primary e primaryDark)
primary = (76, 175, 80)      # #4CAF50
primary_dark = (56, 142, 60) # #388E3C

# Desenhar gradiente de fundo com cantos arredondados
corner_radius = 256  # 25% do tamanho (1024 * 0.25)

# Criar máscara para cantos arredondados
mask = Image.new('L', (size, size), 0)
mask_draw = ImageDraw.Draw(mask)

# Retângulo com cantos arredondados
mask_draw.rounded_rectangle([0, 0, size-1, size-1], radius=corner_radius, fill=255)

# Criar gradiente
gradient = Image.new('RGBA', (size, size))
for y in range(size):
    # Interpolar entre primary (topo-esquerda) e primary_dark (baixo-direita)
    for x in range(size):
        t = (x + y) / (2 * size)  # 0 a 1
        r = int(primary[0] * (1-t) + primary_dark[0] * t)
        g = int(primary[1] * (1-t) + primary_dark[1] * t)
        b = int(primary[2] * (1-t) + primary_dark[2] * t)
        gradient.putpixel((x, y), (r, g, b, 255))

# Aplicar máscara ao gradiente
gradient.putalpha(mask)
img = Image.alpha_composite(img, gradient)
draw = ImageDraw.Draw(img)

# Desenhar ícone de cérebro (psychology icon)
center_x = size // 2
center_y = size // 2
icon_size = int(size * 0.55)  # 55% do tamanho
brain_color = (255, 255, 255, 255)

# Criar cérebro simplificado mas bonito
# Círculo base do cérebro
head_radius = int(icon_size * 0.45)
draw.ellipse([
    center_x - head_radius,
    center_y - head_radius - 30,
    center_x + head_radius,
    center_y + head_radius - 30
], fill=brain_color)

# Tronco cerebral (parte inferior)
brainstem_points = [
    (center_x - 40, center_y + 100),
    (center_x + 40, center_y + 100),
    (center_x + 30, center_y + 200),
    (center_x - 30, center_y + 200),
]
draw.polygon(brainstem_points, fill=brain_color)

# Linhas de divisão do cérebro (sulcos)
line_width = 12
# Linha vertical central
draw.line([
    (center_x, center_y - 200),
    (center_x, center_y + 120)
], fill=(56, 142, 60, 200), width=line_width)

# Linhas horizontais (sulcos cerebrais)
# Sulco central superior
draw.arc([
    center_x - 150,
    center_y - 180,
    center_x + 150,
    center_y + 50
], 200, 340, fill=(56, 142, 60, 200), width=line_width)

# Sulco médio
draw.arc([
    center_x - 130,
    center_y - 120,
    center_x + 130,
    center_y + 80
], 190, 350, fill=(56, 142, 60, 200), width=line_width)

# Sulco inferior
draw.arc([
    center_x - 110,
    center_y - 60,
    center_x + 110,
    center_y + 110
], 180, 360, fill=(56, 142, 60, 200), width=line_width)

# Adicionar sombra suave
shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
shadow_draw = ImageDraw.Draw(shadow)
for i in range(20, 0, -1):
    alpha = int(30 * (i / 20))
    shadow_draw.rounded_rectangle(
        [i*2, size - 40 + i*2, size - i*2, size + i*2],
        radius=corner_radius,
        fill=(0, 0, 0, alpha)
    )

img = Image.alpha_composite(shadow, img)

# Salvar
output_path = 'assets/icons/app_icon.png'
os.makedirs('assets/icons', exist_ok=True)
img.save(output_path, 'PNG')
print(f'✓ Ícone salvo em: {output_path}')
print(f'✓ Tamanho: {size}x{size} pixels')
print(f'✓ Design: Igual ao logo da splash screen (cérebro verde com fundo gradiente)')
