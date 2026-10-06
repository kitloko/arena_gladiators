# PROMPTS_ARTE.md — o prompt de CADA folha de sprite

Cada folha abaixo é **um prompt pronto para copiar e colar** no seu gerador (Flow, GPT, o que for).
Este documento é gerado por script (`scripts_gen_prompts.py`), então o estilo e as regras são idênticos
em todas as folhas — é isso que faz a arte combinar entre si.

## Como usar (3 regras)

1. **Cole o bloco inteiro** da folha, do `[STYLE]` ao `[OUTPUT RULES]`. Não corte pedaços: os blocos de
   vista, layout e fundo são o que fazem o corte automático funcionar.
2. **Salve o arquivo com o nome que está na tabela** (ex.: `A1_heroi_espadachim.png`). É por esse nome
   que eu ligo a imagem ao personagem certo.
3. **Proporção = a mais larga que a ferramenta der** (o prompt já pede). No Flow escolha **16:9**;
   **nunca** 9:16/3:4/1:1 para folha de poses — em retrato a fileira sai espremida. Multiplicador **x1**.

## A vista certa (isto é o que eu errei antes)

O jogo é de lado: o herói fica à esquerda olhando para a **direita** e o inimigo é o **espelho** dele
(`flip_h` no código). Então a arte tem de ser **3/4 virada para a DIREITA** — a mesma vista da arte que
já está no jogo. **Nunca de frente.** Para objetos, perfil limpo; para cenário, vista frontal ampla.

## Mapa das folhas

| ID | Arquivo | Família | Formato |
| --- | --- | --- | --- |
| A1 | `heroi_espadachim.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A2 | `heroi_machadeiro.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A3 | `heroi_lanceiro.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A4 | `heroi_arqueiro.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A5 | `heroi_besteiro.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A6 | `heroi_adagueiro.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A7 | `heroi_arremessador.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A8 | `heroi_armadura_pesada.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A9 | `inimigo_brutus.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A10 | `inimiga_livia.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A11 | `inimigo_maurus.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A12 | `inimigo_vettius.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A13 | `boss_imperator.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A14 | `boss_grande_gladiador.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A15 | `arquetipo_lanceiro.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A16 | `arquetipo_arqueiro.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A17 | `arquetipo_brutamontes.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| A18 | `arquetipo_duelista.png` | A. Personagens | 3:1 (ou 16:9) — 5 poses |
| B1 | `cidade_areia_pedra.png` | B. Cenários | 1 imagem 1536x1024 (opaco) |
| B2 | `cidade_ferro_aco.png` | B. Cenários | 1 imagem 1536x1024 (opaco) |
| B3 | `cidade_prata.png` | B. Cenários | 1 imagem 1536x1024 (opaco) |
| B4 | `arena_areia.png` | B. Cenários | 1 imagem 1536x1024 (opaco) |
| B5 | `arena_cascalho.png` | B. Cenários | 1 imagem 1536x1024 (opaco) |
| B6 | `arena_noturna.png` | B. Cenários | 1 imagem 1536x1024 (opaco) |
| B7 | `arena_nobre.png` | B. Cenários | 1 imagem 1536x1024 (opaco) |
| B8 | `arena_covil_boss.png` | B. Cenários | 1 imagem 1536x1024 (opaco) |
| B9 | `plateia_silhuetas.png` | B. Cenários | 8 células |
| C1 | `armas_espadas.png` | C. Equipamento | 4 células |
| C2 | `armas_arcos.png` | C. Equipamento | 4 células |
| C3 | `armas_adagas.png` | C. Equipamento | 4 células |
| C4 | `armas_machados.png` | C. Equipamento | 4 células |
| C5 | `armas_lancas.png` | C. Equipamento | 4 células |
| C6 | `armas_bestas.png` | C. Equipamento | 3 células |
| C7 | `armas_facas_arremesso.png` | C. Equipamento | 3 células |
| C8 | `armaduras_peitorais.png` | C. Equipamento | 6 células |
| C9 | `armaduras_capacetes.png` | C. Equipamento | 6 células |
| C10 | `armaduras_luvas.png` | C. Equipamento | 4 células |
| C11 | `armaduras_botas.png` | C. Equipamento | 4 células |
| C12 | `armaduras_cintos.png` | C. Equipamento | 4 células |
| C13 | `pocoes.png` | C. Equipamento | 5 células |
| C14 | `trofeus_torneio.png` | C. Equipamento | 8 células |
| D1 | `efeito_corte.png` | D. Efeitos | 6 células |
| D2 | `projeteis.png` | D. Efeitos | 4 células |
| D3 | `efeito_impacto.png` | D. Efeitos | 5 células |
| E1 | `icones_atributos.png` | E. Ícones | 7 células |
| E2 | `icones_ranks.png` | E. Ícones | 8 células |
| E3a | `icones_acoes_1.png` | E. Ícones | 6 células |
| E3b | `icones_acoes_2.png` | E. Ícones | 6 células |
| E4a | `icones_locais_1.png` | E. Ícones | 5 células |
| E4b | `icones_locais_2.png` | E. Ícones | 5 células |
| E5a | `icones_estado_1.png` | E. Ícones | 5 células |
| E5b | `icones_estado_2.png` | E. Ícones | 5 células |
| F1 | `ui_paineis.png` | F. Interface | 4 células |
| F2 | `ui_botoes.png` | F. Interface | 4 células |
| F3 | `ui_barras.png` | F. Interface | 3 células |
| F4 | `ui_adornos.png` | F. Interface | 5 células |
| F5 | `ui_cursor.png` | F. Interface | 2 células |

## Ordem sugerida de produção

**Primeiro (7 folhas):** `A1`, `A4`, `A13`, `A14` (herói e bosses), `B1`, `B4` (cidade e arena),
`F1` (painéis). Com essas eu provo o pipeline inteiro no jogo. Depois `B2`/`B3` e `B5`–`B8`, o resto
do bloco **A**, e por último **C**, **E** e **F** (são muitos objetos pequenos, e os placeholders
por código seguram bem até lá).

---

## Os prompts

### A. Personagens

#### A1 — heroi_espadachim

*Arquivo:* `heroi_espadachim.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] The SAME male gladiator hero in every picture: short dark hair, light brown leather armour with a red cloth over the left shoulder and a studded belt, bare arms, leather sandals, holding a short gladius sword in his RIGHT hand.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A2 — heroi_machadeiro

*Arquivo:* `heroi_machadeiro.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] The SAME male gladiator hero in every picture: shaved head, heavy leather harness, one iron shoulder guard, wraps on the forearms, holding a single-bladed war axe in his RIGHT hand and a small round buckler on the left arm.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A3 — heroi_lanceiro

*Arquivo:* `heroi_lanceiro.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] The SAME male gladiator hero in every picture: long dark hair tied back, bronze scale armour, a blue tunic under it, holding a long spear in the RIGHT hand and a tall oval shield on the left arm.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A4 — heroi_arqueiro

*Arquivo:* `heroi_arqueiro.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] The SAME male gladiator hero in every picture: lean build, hooded leather tunic with a quiver of arrows on the back, arm guard on the left forearm, holding a wooden recurve bow in the LEFT hand with an arrow nocked.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A5 — heroi_besteiro

*Arquivo:* `heroi_besteiro.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] The SAME male gladiator hero in every picture: sturdy build, thick padded vest with a leather bandolier of bolts, holding a heavy crossbow with both hands.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A6 — heroi_adagueiro

*Arquivo:* `heroi_adagueiro.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] The SAME male gladiator hero in every picture: agile build, bare torso with crossed leather straps, short skirt, holding one short dagger in EACH hand, no shield.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A7 — heroi_arremessador

*Arquivo:* `heroi_arremessador.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] The SAME male gladiator hero in every picture: light armour, a bandolier of throwing knives across the chest, holding a balanced throwing knife in the RIGHT hand ready to throw.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A8 — heroi_armadura_pesada

*Arquivo:* `heroi_armadura_pesada.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] The SAME male gladiator hero in every picture: full bronze plated armour, crested helmet with the visor open showing his face, heavy greaves, holding a broad short sword in the RIGHT hand and a large rectangular tower shield on the left arm.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A9 — inimigo_brutus

*Arquivo:* `inimigo_brutus.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A huge brute enemy gladiator: bald, thick neck, heavy iron-banded leather armour, iron helmet with a single horn, holding a spiked wooden club in the RIGHT hand.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A10 — inimiga_livia

*Arquivo:* `inimiga_livia.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A lean agile female gladiator: short ponytail, light leather armour with one bare shoulder, cloth wraps on the shins, no helmet, holding a short curved dagger in the RIGHT hand and another in the left.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A11 — inimigo_maurus

*Arquivo:* `inimigo_maurus.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A slow heavily armoured enemy gladiator: bulky, banded iron armour on the whole body, a plain iron helmet with a narrow eye slit, holding a tower shield on the left arm and a heavy mace in the RIGHT hand.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A12 — inimigo_vettius

*Arquivo:* `inimigo_vettius.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A duelist enemy gladiator: tall and lean, ornate bronze helmet with a fish crest, light armoured tunic, holding a trident in the RIGHT hand and a weighted net in the left.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A13 — boss_imperator

*Arquivo:* `boss_imperator.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A huge emperor champion boss standing tall: golden plated armour with engraved laurel patterns, a purple cape over the shoulders, a laurel crown on his head, holding an oversized golden greatsword in the RIGHT hand.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A14 — boss_grande_gladiador

*Arquivo:* `boss_grande_gladiador.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A giant champion boss, bare chest covered in scars and war paint, iron helmet shaped like a skull, heavy belt with trophies, holding a spiked club as tall as himself in the RIGHT hand.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A15 — arquetipo_lanceiro

*Arquivo:* `arquetipo_lanceiro.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A generic arena enemy gladiator with a plain look: simple leather cuirass, plain helmet with no decoration, holding a spear in the RIGHT hand and a small shield on the left arm.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A16 — arquetipo_arqueiro

*Arquivo:* `arquetipo_arqueiro.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A generic arena enemy archer with a plain look: simple leather tunic, plain hood, quiver on the back, holding a plain bow with an arrow nocked.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A17 — arquetipo_brutamontes

*Arquivo:* `arquetipo_brutamontes.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A generic arena enemy brute with a plain look: bare chest, rough leather belt, plain iron helmet with no decoration, holding a heavy wooden club.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### A18 — arquetipo_duelista

*Arquivo:* `arquetipo_duelista.png` · *formato:* 3:1 (ou 16:9) — 5 poses

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[CHARACTER] A generic arena enemy duelist with a plain look: light tunic, plain helmet, holding a short sword in the RIGHT hand and a small round buckler on the left arm.

[VIEW] Three-quarter view: the body is turned so the character FACES THE RIGHT side of the image (same camera angle as a 3/4 side view in a side-scrolling fighting game), full body from head to toe, weapon visible in the hand.

[LAYOUT] One single horizontal row of 5 separate full-body pictures, same character, same scale (the character fills about 85% of the cell height), each one centred inside its own invisible cell of a 5x1 grid, with a wide empty gap between pictures and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (3:1 if possible, otherwise 16:9) — never a vertical one.

[POSES] Draw exactly 5 separate pictures of this same character in one horizontal row, in this order: 1) standing idle, weapon held ready at his side; 2) mid-attack, lunging forward toward the right, weapon swinging in a wide slash; 3) defending, weapon raised in a parry, weight on the back foot; 4) taking a hit, recoiling backwards toward the left, head back, arms loose; 5) defeated, lying flat on the ground, weapon dropped near his hand.

[BASELINE] In pictures 1 to 4 the feet are on exactly the same horizontal line.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

### B. Cenários

#### B1 — cidade_areia_pedra

*Arquivo:* `cidade_areia_pedra.png` · *formato:* 1 imagem 1536x1024 (opaco)

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] A gladiator city plaza of sandstone: low stone buildings with flat roofs, a wooden gate, burning torches on poles, market stalls with awnings, cloth banners, a sand training yard on the left, a small temple with columns on the right, distant desert hills, clear sky.

[VIEW] Wide establishing shot seen from the front, the ground plane occupies the bottom third of the image and reads clearly as a walkable floor.

[LAYOUT] One single image, full-bleed, no grid, no cells, generous resolution (about 1536x1024). IMPORTANT: keep the bottom third simple and darker (the game draws clickable location buttons over it) and keep the middle band free of important detail.

[BACKGROUND] Opaque, full background covering the whole canvas — no transparency.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No UI, no buttons, no menu, no interface elements.
```

#### B2 — cidade_ferro_aco

*Arquivo:* `cidade_ferro_aco.png` · *formato:* 1 imagem 1536x1024 (opaco)

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] A gladiator city plaza of iron and steel: an open-air forge with glowing coals on the left, iron-barred windows, tall steel banners, a blacksmith anvil and weapon racks, stone barracks in the background, grey overcast sky, a few torches.

[VIEW] Wide establishing shot seen from the front, the ground plane occupies the bottom third of the image and reads clearly as a walkable floor.

[LAYOUT] One single image, full-bleed, no grid, no cells, generous resolution (about 1536x1024). IMPORTANT: keep the bottom third simple and darker (the game draws clickable location buttons over it) and keep the middle band free of important detail.

[BACKGROUND] Opaque, full background covering the whole canvas — no transparency.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No UI, no buttons, no menu, no interface elements.
```

#### B3 — cidade_prata

*Arquivo:* `cidade_prata.png` · *formato:* 1 imagem 1536x1024 (opaco)

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] An imperial gladiator city plaza: polished marble colonnade, statues of past champions, purple and gold banners, a grand stairway in the background, braziers with tall flames, crowds of small distant spectators, dramatic sunset sky.

[VIEW] Wide establishing shot seen from the front, the ground plane occupies the bottom third of the image and reads clearly as a walkable floor.

[LAYOUT] One single image, full-bleed, no grid, no cells, generous resolution (about 1536x1024). IMPORTANT: keep the bottom third simple and darker (the game draws clickable location buttons over it) and keep the middle band free of important detail.

[BACKGROUND] Opaque, full background covering the whole canvas — no transparency.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No UI, no buttons, no menu, no interface elements.
```

#### B4 — arena_areia

*Arquivo:* `arena_areia.png` · *formato:* 1 imagem 1536x1024 (opaco)

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] The inside of a gladiator arena: raked sand floor, low stone walls around the fighting pit, packed wooden stands with indistinct tiny spectators, a canopy of ropes and cloth above, dust in the air, hot midday light.

[VIEW] Wide establishing shot seen from the front, the ground plane occupies the bottom third of the image and reads clearly as a walkable floor.

[LAYOUT] One single image, full-bleed, no grid, no cells, generous resolution (about 1536x1024). IMPORTANT: keep the bottom third simple and darker (the game draws clickable location buttons over it) and keep the middle band free of important detail.

[BACKGROUND] Opaque, full background covering the whole canvas — no transparency.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No UI, no buttons, no menu, no interface elements.
```

#### B5 — arena_cascalho

*Arquivo:* `arena_cascalho.png` · *formato:* 1 imagem 1536x1024 (opaco)

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] The inside of a gladiator arena: rough gravel and pebbles floor with scattered bones, wooden palisade walls, stone archways, grey daylight, small distant crowd silhouettes.

[VIEW] Wide establishing shot seen from the front, the ground plane occupies the bottom third of the image and reads clearly as a walkable floor.

[LAYOUT] One single image, full-bleed, no grid, no cells, generous resolution (about 1536x1024). IMPORTANT: keep the bottom third simple and darker (the game draws clickable location buttons over it) and keep the middle band free of important detail.

[BACKGROUND] Opaque, full background covering the whole canvas — no transparency.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No UI, no buttons, no menu, no interface elements.
```

#### B6 — arena_noturna

*Arquivo:* `arena_noturna.png` · *formato:* 1 imagem 1536x1024 (opaco)

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] The inside of a gladiator arena at night: sand floor dimly lit by tall burning torches along the walls, deep blue night sky above, orange firelight pools on the ground, silhouettes of a distant crowd barely visible.

[VIEW] Wide establishing shot seen from the front, the ground plane occupies the bottom third of the image and reads clearly as a walkable floor.

[LAYOUT] One single image, full-bleed, no grid, no cells, generous resolution (about 1536x1024). IMPORTANT: keep the bottom third simple and darker (the game draws clickable location buttons over it) and keep the middle band free of important detail.

[BACKGROUND] Opaque, full background covering the whole canvas — no transparency.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No UI, no buttons, no menu, no interface elements.
```

#### B7 — arena_nobre

*Arquivo:* `arena_nobre.png` · *formato:* 1 imagem 1536x1024 (opaco)

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] The inside of an imperial arena: polished stone floor with inlaid patterns, marble columns with gilded capitals, purple canopies over the nearest stands, a large imperial box with an awning, bright warm light.

[VIEW] Wide establishing shot seen from the front, the ground plane occupies the bottom third of the image and reads clearly as a walkable floor.

[LAYOUT] One single image, full-bleed, no grid, no cells, generous resolution (about 1536x1024). IMPORTANT: keep the bottom third simple and darker (the game draws clickable location buttons over it) and keep the middle band free of important detail.

[BACKGROUND] Opaque, full background covering the whole canvas — no transparency.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No UI, no buttons, no menu, no interface elements.
```

#### B8 — arena_covil_boss

*Arquivo:* `arena_covil_boss.png` · *formato:* 1 imagem 1536x1024 (opaco)

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] A brutal underground champion arena: black stone and red-lit pit floor with cracks glowing like embers, chains hanging from the ceiling, skulls and broken weapons piled on the sidelines, heavy red torchlight, ominous dark atmosphere.

[VIEW] Wide establishing shot seen from the front, the ground plane occupies the bottom third of the image and reads clearly as a walkable floor.

[LAYOUT] One single image, full-bleed, no grid, no cells, generous resolution (about 1536x1024). IMPORTANT: keep the bottom third simple and darker (the game draws clickable location buttons over it) and keep the middle band free of important detail.

[BACKGROUND] Opaque, full background covering the whole canvas — no transparency.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No UI, no buttons, no menu, no interface elements.
```

#### B9 — plateia_silhuetas

*Arquivo:* `plateia_silhuetas.png` · *formato:* 8 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] The same simple spectator crowd drawn as 8 separate dark silhouettes: different people of a cheering crowd (man with raised arm, woman clasping hands, fat man laughing, old man with a beard, boy on shoulders, soldier, merchant with a hat, noble lady with a fan), all in solid dark grey silhouette with no interior detail.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 8 separate objects, each one centred inside its own invisible cell of a 8x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 8:1).

[BACKGROUND] Background: flat solid MAGENTA (#FF00FF) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

### C. Equipamento

#### C1 — armas_espadas

*Arquivo:* `armas_espadas.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four different swords shown side by side from simplest to most ornate: a plain short sword, a longer gladius with a grooved blade, a broad spatha, an ornate gilded parade sword with an engraved pommel.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 4 separate objects, each one centred inside its own invisible cell of a 4x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 4:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C2 — armas_arcos

*Arquivo:* `armas_arcos.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four different bows standing on their side: a simple shortbow, a tall longbow, a recurve bow with curved tips, an ornate composite bow with bone inlays.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 4 separate objects, each one centred inside its own invisible cell of a 4x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 4:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C3 — armas_adagas

*Arquivo:* `armas_adagas.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four different daggers: a plain steel stiletto, a curved poniard, a broad leaf-shaped dagger, an ornate gilded ceremonial dagger.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 4 separate objects, each one centred inside its own invisible cell of a 4x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 4:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C4 — armas_machados

*Arquivo:* `armas_machados.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four different axes: a small one-handed hatchet, a battle axe with a single crescent blade, a double-bladed axe, an ornate gilded ceremonial axe.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 4 separate objects, each one centred inside its own invisible cell of a 4x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 4:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C5 — armas_lancas

*Arquivo:* `armas_lancas.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four different spears: a plain wooden spear, a broad-bladed war spear, a trident with three prongs, an ornate gilded ceremonial spear.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 4 separate objects, each one centred inside its own invisible cell of a 4x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 4:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C6 — armas_bestas

*Arquivo:* `armas_bestas.png` · *formato:* 3 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Three different crossbows: a light hunting crossbow, a heavy arbalest with a windlass, an ornate gilded crossbow with engraved metal fittings.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 3 separate objects, each one centred inside its own invisible cell of a 3x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 3:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C7 — armas_facas_arremesso

*Arquivo:* `armas_facas_arremesso.png` · *formato:* 3 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Three different throwing knives: a slim balanced thrower, a heavier one with a ring pommel, an ornate gilded show thrower.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 3 separate objects, each one centred inside its own invisible cell of a 3x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 3:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C8 — armaduras_peitorais

*Arquivo:* `armaduras_peitorais.png` · *formato:* 6 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Six different chest armours displayed as if worn on an invisible torso, side by side from cheapest to best: a plain leather chest piece, a studded leather cuirass, a chainmail shirt, a scale-mail cuirass with bronze plates, a steel breastplate, an ornate gilded engraved breastplate.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 6 separate objects, each one centred inside its own invisible cell of a 6x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 6:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C9 — armaduras_capacetes

*Arquivo:* `armaduras_capacetes.png` · *formato:* 6 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Six different helmets in profile: a plain leather cap, a simple bronze pot helmet, a legionary helmet with cheek guards, a crested helmet with a red crest, a gladiator helmet with a face grille, an ornate gilded helmet with a laurel crest.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 6 separate objects, each one centred inside its own invisible cell of a 6x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 6:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C10 — armaduras_luvas

*Arquivo:* `armaduras_luvas.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four different armoured gloves: a plain leather wrap, a studded leather bracer, a plate gauntlet, an ornate gilded gauntlet.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 4 separate objects, each one centred inside its own invisible cell of a 4x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 4:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C11 — armaduras_botas

*Arquivo:* `armaduras_botas.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four different pairs of boots and greaves seen from the side: simple sandals, wrapped leather boots, banded bronze greaves, ornate gilded greaves.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 4 separate objects, each one centred inside its own invisible cell of a 4x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 4:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C12 — armaduras_cintos

*Arquivo:* `armaduras_cintos.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four different belts: a plain rope belt, a thick leather belt with studs, a belt with bronze plates and pouches, an ornate gilded belt with a laurel buckle.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 4 separate objects, each one centred inside its own invisible cell of a 4x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 4:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C13 — pocoes

*Arquivo:* `pocoes.png` · *formato:* 5 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Five potion bottles side by side on a plain invisible shelf, all the same size with different liquids and stoppers: red health potion, grey armour potion, orange strength potion, green agility potion, blue wound-healing potion.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 5 separate objects, each one centred inside its own invisible cell of a 5x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 5:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### C14 — trofeus_torneio

*Arquivo:* `trofeus_torneio.png` · *formato:* 8 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Eight different champion trophies in a row: a bronze laurel wreath, a stone champion medallion, a spiked iron bracer, a steel champion belt, a silver chalice, a gold laurel cup, a jewelled champion crown, a flaming legendary crown with glowing laurel leaves.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 8 separate objects, each one centred inside its own invisible cell of a 8x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 8:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

### D. Efeitos

#### D1 — efeito_corte

*Arquivo:* `efeito_corte.png` · *formato:* 6 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Six separate combat effects: three frames of a sword slash arc (thin white-gold crescent, wider arc, full arc with motion streaks), a burst of impact sparks, a bright parry spark with a small ring wave, and a thin speed trail of dust.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 6 separate objects, each one centred inside its own invisible cell of a 6x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 6:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### D2 — projeteis

*Arquivo:* `projeteis.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four separate projectiles flying horizontally: an arrow with fletching, a short crossbow bolt, a balanced throwing knife, a rounded sling stone.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 4 separate objects, each one centred inside its own invisible cell of a 4x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 4:1).

[BACKGROUND] Background: flat solid MAGENTA (#FF00FF) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### D3 — efeito_impacto

*Arquivo:* `efeito_impacto.png` · *formato:* 5 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Five separate hit effects: a bright heavy-blow impact flash, blood droplets splashing, a dust puff cloud, a burst of broken sand grains, and a heavy ground-impact dust ring.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 5 separate objects, each one centred inside its own invisible cell of a 5x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 5:1).

[BACKGROUND] Background: flat solid MAGENTA (#FF00FF) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

### E. Ícones

#### E1 — icones_atributos

*Arquivo:* `icones_atributos.png` · *formato:* 7 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Seven attribute icons in a row: a flexed bicep (strength), a crosshair (accuracy), a round shield (defence), a swirl of wind (agility), a red heart (vitality), a group of three tiny heads (charisma), a four-leaf clover (luck).

[VIEW] Flat game-icon style, centred, simplified shape with a strong readable silhouette.

[LAYOUT] One single horizontal row of 7 separate icons, each one centred inside its own invisible cell of a 7x1 grid, same visual weight and same scale, evenly spaced, nothing touching or crossing the cell edges or the image border.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### E2 — icones_ranks

*Arquivo:* `icones_ranks.png` · *formato:* 8 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Eight rank medals in a row, growing in quality: a sand-coloured stone badge, a pebble badge, a plain iron badge, a steel badge, a silver badge, a gold badge, a gold laurel champion badge, and a legendary flaming crown badge.

[VIEW] Flat game-icon style, centred, simplified shape with a strong readable silhouette.

[LAYOUT] One single horizontal row of 8 separate icons, each one centred inside its own invisible cell of a 8x1 grid, same visual weight and same scale, evenly spaced, nothing touching or crossing the cell edges or the image border.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### E3a — icones_acoes_1

*Arquivo:* `icones_acoes_1.png` · *formato:* 6 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Six combat action icons: a single sword strike, a heavy overhead blow, a charging shoulder rush, a bow shot, a precise aimed shot, a volley of arrows.

[VIEW] Flat game-icon style, centred, simplified shape with a strong readable silhouette.

[LAYOUT] One single horizontal row of 6 separate icons, each one centred inside its own invisible cell of a 6x1 grid, same visual weight and same scale, evenly spaced, nothing touching or crossing the cell edges or the image border.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### E3b — icones_acoes_2

*Arquivo:* `icones_acoes_2.png` · *formato:* 6 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Six combat action icons: a raised shield (firm defence), a single footstep forward (advance), a footstep backward (retreat), an open shouting mouth (taunt), a 'Z' with closed eyes (sleep), a flexing arm with a crown (show off).

[VIEW] Flat game-icon style, centred, simplified shape with a strong readable silhouette.

[LAYOUT] One single horizontal row of 6 separate icons, each one centred inside its own invisible cell of a 6x1 grid, same visual weight and same scale, evenly spaced, nothing touching or crossing the cell edges or the image border.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### E4a — icones_locais_1

*Arquivo:* `icones_locais_1.png` · *formato:* 5 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Five location icons: a small arena building, a tournament trophy stand, a market stall, a bedroll (rest), a medical cross with a leaf (medic).

[VIEW] Flat game-icon style, centred, simplified shape with a strong readable silhouette.

[LAYOUT] One single horizontal row of 5 separate icons, each one centred inside its own invisible cell of a 5x1 grid, same visual weight and same scale, evenly spaced, nothing touching or crossing the cell edges or the image border.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### E4b — icones_locais_2

*Arquivo:* `icones_locais_2.png` · *formato:* 5 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Five location icons: an anvil and hammer (blacksmith), a training dummy (trainer), a gladiator helmet portrait (character), a leather satchel (bag), a new gladiator helmet with a plus sign (new gladiator).

[VIEW] Flat game-icon style, centred, simplified shape with a strong readable silhouette.

[LAYOUT] One single horizontal row of 5 separate icons, each one centred inside its own invisible cell of a 5x1 grid, same visual weight and same scale, evenly spaced, nothing touching or crossing the cell edges or the image border.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### E5a — icones_estado_1

*Arquivo:* `icones_estado_1.png` · *formato:* 5 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Five status icons: a stack of gold coins, a star (experience), a red heart with a pulse line (health), a shield with a crack (armour), a cheering crowd of tiny heads (crowd mood).

[VIEW] Flat game-icon style, centred, simplified shape with a strong readable silhouette.

[LAYOUT] One single horizontal row of 5 separate icons, each one centred inside its own invisible cell of a 5x1 grid, same visual weight and same scale, evenly spaced, nothing touching or crossing the cell edges or the image border.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### E5b — icones_estado_2

*Arquivo:* `icones_estado_2.png` · *formato:* 5 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Five status icons: a heraldic rank badge, two roman numerals V and D crossed (wins and losses), a bandaged arm (injury), a pair of dice (betting), a hand holding a coin with a discount tag (haggling).

[VIEW] Flat game-icon style, centred, simplified shape with a strong readable silhouette.

[LAYOUT] One single horizontal row of 5 separate icons, each one centred inside its own invisible cell of a 5x1 grid, same visual weight and same scale, evenly spaced, nothing touching or crossing the cell edges or the image border.

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

### F. Interface

#### F1 — ui_paineis

*Arquivo:* `ui_paineis.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four rectangular UI panels, each a separate object in its own cell of a 4x1 grid, all with a CONTINUOUS ornamented border of the same thickness on all four sides and a flat empty centre area: 1) dark leather panel with a thin gold trim; 2) lighter parchment panel with a brown trim; 3) black panel with an ornate thick gold border; 4) dark red panel with a blood-red border.

[LAYOUT] A single object centred in the canvas with a WIDE empty margin on all four sides (the margin is cut out by the game), rectangular, straight parallel edges, no perspective, no tilt.

[BACKGROUND] Background: flat solid MAGENTA (#FF00FF) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No text inside the panel, the centre area must be empty.
```

#### F2 — ui_botoes

*Arquivo:* `ui_botoes.png` · *formato:* 4 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Four rectangular buttons in a row, each one a separate object in its own cell of a 4x1 grid, all the same size with a continuous uniform border, flat empty centre and no text: 1) dark leather button with gold trim; 2) the same button brighter (hover); 3) the same button darker and pressed inward with a shadow line (pressed); 4) the same button desaturated grey (disabled).

[LAYOUT] A single object centred in the canvas with a WIDE empty margin on all four sides (the margin is cut out by the game), rectangular, straight parallel edges, no perspective, no tilt.

[BACKGROUND] Background: flat solid MAGENTA (#FF00FF) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No text inside the panel, the centre area must be empty.
```

#### F3 — ui_barras

*Arquivo:* `ui_barras.png` · *formato:* 3 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Three long horizontal bar pieces stacked in a column, each a separate object: 1) an empty recessed bar track with dark inner shadow and a uniform border; 2) a smooth solid red fill bar of the same size; 3) a glossy lighter highlight strip for the top half of the bar.

[LAYOUT] A single object centred in the canvas with a WIDE empty margin on all four sides (the margin is cut out by the game), rectangular, straight parallel edges, no perspective, no tilt.

[BACKGROUND] Background: flat solid MAGENTA (#FF00FF) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow. No text inside the panel, the centre area must be empty.
```

#### F4 — ui_adornos

*Arquivo:* `ui_adornos.png` · *formato:* 5 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Five separate interface ornaments: a corner ribbon banner in gold and red, a horizontal title ribbon, a single gold coin, a golden laurel crown, and a small grey skull coin.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 5 separate objects, each one centred inside its own invisible cell of a 5x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 5:1).

[BACKGROUND] Background: flat solid pure BLACK (#000000) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```

#### F5 — ui_cursor

*Arquivo:* `ui_cursor.png` · *formato:* 2 células

```
[STYLE] 2D game art, hand-painted stylized look, ancient Roman gladiator setting, warm gold and sand palette with deep shadows, clean thick dark outlines, high contrast, readable at small size, consistent light coming from the upper left.

[SUBJECT] Two mouse cursors: a classic pointed arrow cursor and a pointing hand cursor, both in gold with a dark outline.

[VIEW] Each object in a clean profile / three-quarter view, floating, isolated, nothing else around it.

[LAYOUT] One single horizontal row of 2 separate objects, each one centred inside its own invisible cell of a 2x1 grid, all at the same scale, evenly spaced, with a wide empty gap between them and nothing touching or crossing the cell edges or the image border. Generate the widest proportion your tool offers (about 2:1).

[BACKGROUND] Background: flat solid MAGENTA (#FF00FF) filling everything behind the art, perfectly uniform, no gradient, no shadow on the background, no scenery, no floor.

[OUTPUT RULES] No text, no letters, no numbers, no watermark, no logo, no signature, no grid lines, no panel frames, no drop shadow.
```
