# ARTE.md — inventário de arte, contrato de corte e prompts

Documento de trabalho do dono. Responde: **procedural ou sprite? Como gerar em folha (atlas) e como eu corto?**
Atualizado em 06/10/2026, junto do `PLANO_3.0.md` (etapa 7 = arte).

---

## 1. Resposta curta

| Pergunta | Resposta |
| --- | --- |
| Procedural ou sprite? | **Os dois, divididos por natureza** (§5). Sprite seu para o que precisa de "cara"; procedural meu para o infinito. |
| Uma imagem com tudo e você corta? | **Sim** — uma folha por família, grade fixa, **até ~12 células por folha**. Folha densa o gerador desalinha. |
| Um prompt por sprite? | **Não**: **um prompt por folha**. Mais barato, estilo coerente e eu corto. |
| Você precisa de uma lista? | **É este documento** (§3 inventário, §4 prompts). |
| Efeito de arma na mão / projétil? | A arma vem **na própria folha do personagem** (pose de ataque e parado) — alinhar arma solta na mão por gerador é loteria. Projétil vem solto (§3-E2) e eu giro por código. |

---

## 2. O contrato de corte (as 8 regras de ouro)

Se você seguir isto, meu cortador acerta sempre:

1. **PNG com fundo transparente de verdade** (nada de xadrez desenhado, nada de branco). Cenários são a exceção (opacos).
2. **Grade exata** declarada: ex. `5 colunas x 1 linha, células de 256x256`. Eu corto por essa grade.
3. **Margem de 8 px** dentro de cada célula: nada encostando na borda da célula e **nada cruzando a grade**. (Se cruzar, eu ainda corto por detecção de alfa, mas perco precisão de ancoragem.)
4. **Personagem centralizado** e com os **pés na mesma linha** (baseline) em todas as poses — é o que permite trocar pose/animação sem o boneco "pular" na tela.
5. **Sem texto** dentro da imagem. Nome de item, rótulo de botão e número são desenhados **por código** — gerador escreve texto quebrado e em inglês errado.
6. **Mesmo estilo** em todas as folhas: comece **todo prompt** com o bloco de estilo (§4.1). Sem isso as folhas não combinam entre si.
7. **Até ~12 células** por folha, com **célula de 128 px** (itens/ícones), **256 px** (personagens) ou **1024+ px** (cenários).
8. **Uma folha = uma família** (todos os arcos; todos os capacetes; todas as poses de um inimigo). Se precisar de mais itens, faça **mais folhas**, não uma folha maior.

**O que eu faço com a folha:** corto pela grade → **detecto o alfa** dentro de cada célula → acho o desenho real, centralizo no eixo de ancoragem e salvo como `<id>.png` + registro no manifesto (`assets/gen/manifest.json`). Depois digo, em QA, **qual célula virou qual item** — nada entra em silêncio.

---

## 3. Inventário de folhas (a lista que você pediu)

**PRIORIDADE 1** = destrava a prova do pipeline (eu já corto e mostro no jogo).

### A. Personagens e inimigos (fundo transparente, 256×256, 5 poses por folha: parado · ataque · defesa · levando golpe · caído)

| # | Folha | Células | Prioridade |
| --- | --- | --- | --- |
| A1 | **Herói — espadachim** | 5 (= 5 poses) | **1** |
| A2 | Herói — machadeiro | 5 | 2 |
| A3 | Herói — lanceiro | 5 | 2 |
| A4 | Herói — arqueiro | 5 | **1** |
| A5 | Herói — besteiro | 5 | 3 |
| A6 | Herói — adagueiro | 5 | 3 |
| A7 | Herói — arremessador de facas | 5 | 3 |
| A8 | Herói — conjunto de armadura pesada (mesmas 5 poses) | 5 | 3 |
| A9 | **Inimigo Brutamontes** (`brutus`) | 5 | **1** |
| A10 | Inimiga Ágil (`livia`) | 5 | 2 |
| A11 | Inimigo Lento blindado (`maurus`) | 5 | 2 |
| A12 | Inimigo Duelista (`vettius`) | 5 | 2 |
| A13 | **Boss Imperador** (`imperator`) | 5 | **1** |
| A14 | **Boss Grande Gladiador** (`grande_gladiador`) | 5 | **1** |
| A15–A18 | Arquétipos da Arena Livre (lanceiro, arqueiro, brutamontes, besteiro — versão genérica) | 5 cada | 2 |

> A arma **sai na mão** em todas as poses (é o que você pediu). A cor/raridade do equipamento eu aplico por **tinta procedural**, então **não** preciso de uma folha por raridade.

### B. Cenários (opacos, 1536×1024, **sem grade** — 1 imagem por linha)

| # | Folha | Células | Prioridade |
| --- | --- | --- | --- |
| B1 | **Cidade 1 — Praça de Areia/Pedra** (muralhas, prédios baixos, tochas) | 1 imagem | **1** |
| B2 | Cidade 2 — Praça de Ferro/Aço (forja, grades, bandeiras) | 1 | 2 |
| B3 | Cidade 3 — Praça Nobre de Prata+ (arcos, estátuas, multidão) | 1 | 2 |
| B4 | **Arena de Areia** (com muralha e arquibancada) | 1 | **1** |
| B5 | Arena de Cascalho · B6. Arena Noturna com tochas · B7. Arena Nobre (Prata+) · B8. Covil do boss (vermelho) | 1 cada | 2 |
| B9 | **Plateia** — 8 silhuetas de expectadores (transparente) | 8 | 2 |

> Para parallax eu separo as camadas **por código** com as 3 faixas da própria imagem (céu/meio/chão). Se preferir, você entrega em 3 folhas separadas — me diga e eu ajusto o contrato.

### C. Equipamento para a loja, a bolsa e o HUD (transparente, 128×128)

| # | Folha | Células | Prioridade |
| --- | --- | --- | --- |
| C1 | **Espadas** (4 silhuetas: curta, longa, montante, gládio) | 4 | **1** |
| C2 | **Arcos** (curto, longo, composto, recurvo) | 4 | **1** |
| C3 | Adagas (4) · C4. Machados (4) · C5. Lanças (4) · C6. Bestas (3) · C7. Facas de arremesso (3) | 4/4/4/3/3 | 2 |
| C8 | Peitorais (couro, malha, placas, escamas, túnica, élfico) | 6 | 2 |
| C9 | Capacetes (6) · C10. Luvas (4) · C11. Botas (4) · C12. Cintos (4) | 6/4/4/4 | 2 |
| C13 | Poções (cura, armadura, força, agilidade, cura-ferimento) | 5 | 2 |
| C14 | Troféus de torneio (8 variações únicas — §5 do `PLANO_3.0`) | 8 | 2 |

### D. Efeitos e projéteis (transparente; efeitos 256×256, projéteis 128×128)

| # | Folha | Células | Prioridade |
| --- | --- | --- | --- |
| D1 | **Ataque corpo a corpo**: 3 quadros de arco de corte + impacto + faísca de aparo + rastro de esquiva | 6 | **1** |
| D2 | **Projéteis**: flecha, virote, faca de arremesso, pedra de funda | 4 | **1** |
| D3 | Golpe pesado (3 quadros de impacto + poeira + sangue) | 5 | 2 |

### E. Ícones (transparente, 96×96 ou 128×128)

| # | Folha | Células | Prioridade |
| --- | --- | --- | --- |
| E1 | **7 atributos**: STR · ATT (precisão) · DEF (escudo) · AGI (esquiva) · VIT (coração) · CHA (público) · SOR (dado/trevo) | 7 | **1** |
| E2 | **8 faixas de rank**: Areia · Pedra · Ferro · Aço · Prata · Ouro · Campeão · Lenda (medalha/insígnia) | 8 | **1** |
| E3 | **12 ações de luta**: golpe · golpe forte · investida · tiro · tiro certeiro · bombardeio · defesa firme · avançar · recuar · taunt · dormir · exibir | 12 (= 2 folhas de 6) | 2 |
| E4 | **10 serviços/locais**: arena · torneio · loja · descansar · médico · ferreiro · treinador · personagem · bolsa · novo gladiador | 10 (= 2 folhas de 5) | **1** |
| E5 | **Recursos/estado**: ouro · XP · vida · armadura · público · rank · KD · ferimento · aposta · pechincha | 10 (= 2 folhas de 5) | 2 |

### F. Interface — botões, painéis e barras (transparente; é o que faz a tela ficar bonita)

| # | Folha | Células | Prioridade |
| --- | --- | --- | --- |
| F1 | **Painéis 9-slice**: escuro, claro, dourado, vermelho (borda contínua!) | 4 (256×256) | **1** |
| F2 | **Botões 9-slice**: normal · hover · pressionado · desabilitado | 4 (256×96) | **1** |
| F3 | **Barras**: fundo · preenchimento · brilho/capacete da barra | 3 (256×32) | 2 |
| F4 | Molduras/fitas: fita de canto, faixa de título, moeda, coroa, caveira (permadeath) | 5 | 2 |
| F5 | Mouse/hand cursor (apontando e normal) | 2 | 3 |

> **Importante (9-slice):** no painel e no botão, a **borda tem de ser contínua e uniforme** (mesma espessura nos 4 lados) — eu estico só o miolo. Se a borda variar, aparece emenda.

**Total: ~48 folhas** (menos, se você cortar as de prioridade 3). Com ~12 células por folha são **~400 imagens** — é o "todas as imagens possíveis" que você perguntou, em 48 arquivos.

---

## 4. Prompts prontos

### 4.1 O bloco de estilo (cole no começo de TODO prompt)

```
STYLE: 2D game art, hand-painted stylized look, ancient Roman gladiator arena setting,
warm gold and sand palette with deep shadows, clean thick outlines, high contrast,
readable at small size, consistent lighting from the upper left.
OUTPUT RULES: plain fully transparent background (PNG alpha), no background scenery,
no text, no letters, no numbers, no watermark, no grid lines, no frame, no drop shadow.
LAYOUT: a single row/spread of <N> separate pictures, each one centred inside its own
invisible cell of a <C>x<R> grid, same scale, same style, nothing touching or crossing
the cell edges, extra empty margin around each picture.
```

### 4.2 Exemplos prontos (os de prioridade 1)

**A1 — Herói espadachim (5 poses, 5×1, 256 px)**
```
<BLOCO DE ESTILO>
Subject: the SAME gladiator hero, front view, male, light leather armour with a red
shoulder cloth, short sword held in the RIGHT hand.
Draw exactly 5 pictures of this same character in one horizontal row:
1) idle standing, weapon in hand pointing down  2) mid-attack, sword swinging forward
3) defensive stance, sword raised across the chest, shield-less parry
4) taking a hit, recoiling backwards  5) lying defeated on the ground.
Feet on the same baseline in poses 1-4.
```

**A13 — Boss Imperador / A14 — Grande Gladiador**: mesmo prompt, trocando o sujeito
(*"huge emperor in golden plated armour with a purple cape and a laurel crown, holding a
greatsword"* / *"giant bare-chested champion with a spiked club, scars, iron helmet with a
skull"*), e a fraqueza visual combina com o traço (§6 do `PLANO_3.0`).

**B1 — Cidade 1 (1536×1024, 1 imagem)**
```
<BLOCO DE ESTILO>
Subject: a gladiator city plaza seen from the front, wide establishing shot.
Sandstone walls and low buildings, wooden gates, torches burning, market stalls, banners,
a stone training ground on the left, a temple with columns on the right, distant desert
hills, clear sky. IMPORTANT: leave the lower third simple and dark (the game draws the
location buttons there) and keep the middle band free of important detail.
Opaque, full background, no text, no UI, no buttons.
```

**C2 — Arcos (4 células, 128 px)** · **D2 — Projéteis (4)** · **E1 — Atributos (7)** · **E2 — Ranks (8)** —
todos seguem o mesmo molde:
```
<BLOCO DE ESTILO>
Subject: <LISTA DOS 4/7/8 OBJETOS, um por célula>.
Centred, isolated, full item visible, slight top-left light.
```
- **C2**: `a shortbow · a longbow · a composite bow · a recurve bow, each unstrung profile view`
- **D2**: `an arrow with fletching · a crossbow bolt · a balanced throwing knife · a sling stone`
- **E1**: `a bicep (strength) · a crosshair (accuracy) · a shield (defence) · a wind swirl (agility) · a heart (vitality) · a crowd of tiny heads (charisma) · a four-leaf clover (luck), flat game icon set`
- **E2**: `eight heraldic rank medals, progressive: sand-coloured stone badge · pebble badge · iron badge · steel badge · silver badge · gold badge · champion laurel badge · legendary flaming crown badge`
- **F1/F2 (9-slice)**: `a rectangular UI panel with a continuous thick ornate border, uniform border width on all four sides, dark leather with gold trim, flat fill in the centre, nothing inside the centre area`

---

## 5. O que **não** vai para o gerador (é procedural, meu código)

| Feito por código | Por quê |
| --- | --- |
| **Tinta de raridade** (Comum→Épico) dos itens | mesmos 4 sprites dão 5 raridades cada = 20 visuais sem gerar de novo |
| **Variação de inimigo** (cor de pele, porte, cicatriz) por semente | 4 arquétipos × N variações em vez de N folhas |
| **Camadas de parallax** do cenário | separo a imagem por faixas e movo as camadas |
| **Animação** (interpolação entre poses, tremor de impacto, giro do projétil) | sai da folha de 5 poses, sem gerar animação |
| **Números, nomes e rótulos** (todo o texto da UI) | gerador escreve texto quebrado |
| **Barras, gradientes, brilho, fumaça, sangue** | dá para desenhar direto |
| **Cenário da Arena Livre por faixa de rank** | variação de cor/luz sobre a mesma arena |

**Regra:** o gerador faz **o que precisa de olho humano**; o código faz **o que precisa ser infinito**. É isso que segura o volume de arte em ~48 folhas em vez de milhares de imagens.

---

## 6. Entrega e prova

1. Você manda a folha (ex.: `A1_heroi_espadachim.png`) com a grade declarada: `5 colunas x 1 linha, 256x256 por célula`.
2. Eu rodo o cortador (`tools/slice_atlas.gd`): corta, detecta o alfa, ancora e grava `assets/gen/<id>.png` + o manifesto.
3. Rodo a QA e te mando o **print do jogo usando a sua arte**, com a tabela "célula → item" (prova de que nada entrou trocado).
4. Se alguma célula vier torta/fora da grade, eu **aviso com o print da folha recortada** e você regera só aquela folha.

**Ordem sugerida para começar (6 folhas):** `A1` + `A13`/`A14` (personagens) · `B1` + `B4` (cidade e arena) · `F1` + `F2` (painéis e botões). Com essas seis eu provo o pipeline inteiro ponta a ponta: corte → jogo → QA.

**Enquanto elas não chegam, eu não fico parado:** gero placeholders por código com o mesmo contrato (mesmos nomes e mesma grade). Quando a sua folha entra, ela **substitui o placeholder** sem trocar uma linha do jogo.
