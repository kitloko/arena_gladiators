# PLANO 3.0 — Arte procedural, torneio de verdade e as correções

Documento de trabalho do dono do projeto. Cada item casa com um pedido seu (06/10/2026, segunda leva).
**Nada aqui é executado antes do seu OK** — este plano é para revisão.

---

## 1. O que você pediu (checklist)

| # | Pedido | Onde entra |
| --- | --- | --- |
| 1 | "Isso parece uma cidade? Cadê a imagem da cidade?" | §4.1 (arte da cidade) |
| 2 | Bug: upar no torneio → distribuir pontos → vai para o menu principal e **reseta o torneio** | §3.1 — **bug confirmado, com a linha do código** |
| 3 | "Mudança drástica": morrer no torneio **apaga o personagem** | §6 (permadeath) |
| 4 | Mostrar **VOCÊ GANHOU / VOCÊ PERDEU** antes do resumo; resumo vira **modal** | §3.2 — **confirmado** |
| 5 | Item só do **boss final**, e essa luta **bem evidente** | §5.1 |
| 6 | Mais itens + **variações únicas só de torneio**, com **tier de dificuldade de drop**; **boss final aleatório**, drop atrelado à dificuldade | §5.2 / §5.3 |
| 7 | Gerar sprites de **arenas, cidades, armas, armaduras**, efeito de ataque **com a arma na mão** e **projéteis** | §4 |
| 8 | "Ajustar para ser **procedural** cada luta, arma, sprite e personagem" — montar o plano | §4 + §7 |

---

## 2. Diagnóstico do estado atual (com prova no código)

**Arte que existe hoje** (não há nada de cidade, nem arma na mão):

```
assets/sprites/arena/    4 imagens  (arena_background.jpeg, arena_ground.jpeg, 2 muralhas)
assets/sprites/hero/     ~4 PNGs 500x500  (pose parada, ataque, defesa...)
assets/sprites/enemies/  ~4 PNGs 500x500
assets/sprites/items/    ~13 PNGs
assets/sprites/effects/  1 imagem
assets/sprites/ui/       ~2 PNGs
```

A tela da cidade **não tem imagem própria**: ela reaproveita o piso e as muralhas da arena (era o único
asset disponível e não era permitido baixar arte externa). Os 56 arquivos seguem **sem licença/origem
documentada** (`assets/ATRIBUICOES.md` está vazio) — e o repositório é **público**. O plano resolve as duas
coisas de uma vez: arte **gerada por nós**, com licença nossa, versionável.

---

## 3. Correções (as que já estão diagnosticadas)

### 3.1 BUG — distribuir pontos no torneio reseta o torneio

**Causa raiz encontrada** (2 pontos que se somam):

- `scripts/ui/result_screen.gd:153` — quando você sobe de nível na luta, a tela de resultado cria o botão
  `DISTRIBUIR PONTOS` que roteia para a tela de **personagem**.
- `scripts/ui/app.gd:85-89` — a tela de personagem fecha em `show_city()`. Ou seja: você aloca os pontos e
  **cai na CIDADE no meio do torneio**.
- `scripts/ui/app.gd:58/73-75` — na cidade, `» Torneio Menor` chama `start_tournament()`, que **recomeça o
  torneio na rodada 0** (o placar da rodada atual se perde), e `show_city()` ainda **não salva** enquanto o
  torneio está ativo.

**Correção proposta (3 regras, todas com teste):**

1. `DISTRIBUIR PONTOS` durante o torneio abre o personagem em **modo "só pontos"** (painel/modal) e **volta
   para a tela de resultado da rodada** — nunca para a cidade.
2. **A cidade fica proibida durante um torneio**: qualquer rota para `show_city()` com `is_tournament()` é
   redirecionada para a rodada em andamento (com um aviso "você está no torneio — Combate 2/4").
3. `start_tournament()` **recusa reiniciar** um torneio em andamento; abandonar passa a exigir um botão
   explícito **ABANDONAR TORNEIO** com confirmação (e registra a derrota no KD).

### 3.2 Fim de luta: primeiro GANHOU/PERDEU, depois o resumo em modal

Hoje a luta termina e a tela salta direto para o resumo. Correção:

1. Ao cair o último golpe, a arena mostra um **cartaz grande** `VOCÊ VENCEU` / `VOCÊ PERDEU` (com o nome do
   adversário e o número de rodadas), com o botão **CONTINUAR**.
2. **CONTINUAR** abre o **resumo como modal por cima da arena** (caixa central, com rolagem própria se
   precisar), em vez de trocar a tela inteira.
3. Só a partir do modal o jogador escolhe o próximo passo (`PRÓXIMO COMBATE` / `SEGUIR` / `ACEITAR A DERROTA`),
   mantendo o fluxo do torneio intacto.

---

## 4. Arte procedural (o coração do 3.0)

### 4.1 Como (sem asset externo, sem licença de terceiro)

Um **gerador de arte dentro do próprio Godot**, rodando headless:

```
godot --headless --path . -s res://tools/gen_assets.gd -- --seed 1234
```

- Desenha com a API `Image`/`ImageTexture` do engine e salva PNG em `assets/gen/`.
- **Determinístico por seed**: o sprite de um item é `hash(id + raridade + seed)` — o mesmo item sempre gera a
  mesma arte, e dá para regerar tudo a qualquer momento.
- Um **manifesto** (`assets/gen/manifest.json`) diz qual PNG pertence a qual id; o jogo só lê o manifesto.
- Nada de download, nada de arte de terceiro: **licença nossa**, versionável, e cada item/inimigo/cenário novo
  já nasce com arte.

**Limite honesto (importante):** isto é **arte estilizada gerada por código** (pixel-art/geométrica, com
paletas e sombreamento por procedimento), **não** ilustração pintada. Neste ambiente eu não tenho gerador de
imagem por IA. Se o alvo é o acabamento "pintado" da referência do Swords and Sandals, o caminho é você me
passar as imagens (ou autorizar um gerador de imagem externo) — e o resto do pipeline continua valendo.

### 4.2 O que será gerado

| Alvo | O que sai | Detalhe |
| --- | --- | --- |
| **Cidades** | 3 cenários completos (praça com muralhas, prédios, tochas, silhueta de plateia) | um por faixa de rank (Areia/Pedra · Ferro/Aço · Prata+), com parallax em 3 camadas |
| **Arenas** | 3 a 5 cenários de luta por faixa (areia, cascalho, areia molhada, noturna com tochas) | o cenário da luta passa a ser **sorteado por luta**, casado com a faixa de rank |
| **Gladiador** | corpo em **camadas** (cabeça, tronco, braços, pernas) com cor de pele/cabelo/porte por seed | a **peça equipada aparece no corpo**: peitoral, capacete, luva, bota, cinto |
| **Arma na mão** | a arma equipada é **composta na mão** do gladiador, no sprite parado e no de ataque | responde ao seu pedido de "efeito dos ataques com a arma nas mãos" |
| **Armas** | espadas, adagas, machados, lanças, arcos, bestas, arremesso | 3 a 5 silhuetas por classe, tingidas pela **raridade** |
| **Armaduras** | peitorais, capacetes, luvas, botas, cintos | mesma regra: silhueta procedural + tinta de raridade |
| **Efeitos** | arco de corte (3 quadros), impacto, faísca de aparo, rastro de esquiva, sangue/poeira | sobrepostos na luta no momento da resolução |
| **Projéteis** | flecha, virote, faca de arremesso — com rastro e rotação | para TIRO / TIRO CERTEIRO / BOMBARDEIO |
| **Ícones de UI** | rank, ferimento, poção, pechincha, aposta | para o HUD e as telas |

**Animações (escopo inicial):** parado (2 quadros), ataque (3: preparo, impacto, volta), aparar (1), levar
golpe (1), cair (2). Andar/celebrar ficam para depois — digo abertamente que é a parte mais cara e a de menor
retorno agora.

### 4.3 Integração

- `EnemySpriteResolver` / `ItemSpriteResolver` (novos) escolhem o PNG pelo **manifesto** (id + raridade + seed).
- Os 56 assets atuais **não são apagados**: ficam como reserva e o manifesto decide; remoção só com o seu OK
  (regra permanente).
- Substituir nada em silêncio: cada troca de sprite sai em QA com antes/depois.

---

## 5. Torneio 3.0

### 5.1 Item só do boss final, e o combate final evidente

- Rodadas **1 a n−1**: só **ouro + XP** (o "item por rodada" da versão 1.6 sai, conforme você pediu).
- Rodada **final**: vira um **COMBATE FINAL** —
  - faixa vermelha/dourada no topo da arena e da apresentação com `COMBATE FINAL — <nome do boss>`;
  - introdução própria do boss (apelido, descrição, fraqueza, provocação) e **música/tema visual** por cor;
  - o log avisa "só aqui o troféu aparece".
- **O item cai exclusivamente do boss final** (com o tier de drop dele, §5.3).

### 5.2 Mais itens e variações únicas de torneio

- **Pool base maior**: mais arquétipos por slot (4 a 6 silhuetas por classe de arma, 3 a 5 por peça de
  armadura) e mais afixos (bônus por atributo, chance de crítico, resistência a Taunt, ouro por vitória...).
- **Variações únicas (só de torneio)**: 8 itens **um-de-um-tipo**, com nome próprio e um **efeito exclusivo**
  (ex.: `Manto do Público` — EXIBIR rende +50% e não deixa aberto; `Adaga da Viúva` — revida sempre que apara;
  `Elmo do Imperador` — imune a Taunt). Não aparecem na loja, não são vendáveis e **só caem de boss**.
- Cada torneio tem seu **conjunto de variações** (Menor / Maior / Grande), de modo que subir de torneio não é
  "o mesmo prêmio mais forte".

### 5.3 Boss final aleatório, drop pela dificuldade

- Cada torneio sorteia o boss final de um **pool próprio do tier** (recomendo 6 candidatos por torneio, 18 no
  total) — a luta final deixa de ser sempre a mesma.
- Cada boss tem um **grau de dificuldade (1 a 5 ⭐)** visível na apresentação. O grau define a **tabela de drop**:

| Grau | Comum | Incomum | Raro | Épico | Lendário (variação única) |
| --- | --- | --- | --- | --- | --- |
| 1 ⭐ | 55% | 25% | 12% | 6% | 2% |
| 2 ⭐ | 40% | 28% | 18% | 10% | 4% |
| 3 ⭐ | 28% | 30% | 24% | 13% | 5% |
| 4 ⭐ | 15% | 28% | 30% | 19% | 8% |
| 5 ⭐ | 10% | 22% | 32% | 26% | 10% |

- Boss mais difícil = **mais chance de item melhor** (é o que dá sentido a escolher o torneio difícil).
- O **tier do torneio** empurra a tabela para cima e o **rank do jogador** tem peso pequeno (para não virar
  farm de lendário no torneio pequeno).
- **Anti-farm/trava:** a chance de variação única é limitada por torneio e a mesma variação **não repete**
  enquanto você não tiver todas (sem duplicata inútil).

---

## 6. Permadeath no torneio ("morreu, apagou")

Regra pedida, e é a mais drástica do jogo — por isso ela vem com cinto de segurança:

1. **Aviso obrigatório antes de entrar**: na apresentação do torneio, um aviso em vermelho
   `MORTE NO TORNEIO = PERSONAGEM APAGADO`, com confirmação explícita (`ENTRAR MESMO ASSIM`).
2. **Na derrota dentro do torneio**: o personagem é **apagado** (o save da campanha é removido) e a tela de
   fim conta a história da queda: nome, rank/título, KD, torneios vencidos e o carrasco.
3. **Arena Livre continua sem permadeath** (recomendo fortemente: com morte permanente em tudo, o jogo fica
   impossível de aprender — a arena livre é onde se testa build).
4. **Mural dos caídos** (recomendo): guardamos um registro **local** dos personagens mortos (nome, rank, KD,
   torneio, carrasco) para você ver o histórico. O personagem continua apagado — só não perdemos a estatística.
5. O save é apagado de verdade: **isso precisa do seu OK explícito** (é o item mais irreversível do plano).

---

## 7. "Procedural em tudo" — o que muda no motor do jogo

Hoje já é procedural: **luta/inimigo** (escala por nível/tier), **item gerado** (nome, raridade, bônus),
**torneio** (rodadas e slots), **loja** (estoque rerolável), **público/rank**. O 3.0 fecha o ciclo:

- **Cada luta**: cenário sorteado (por faixa de rank), plateia/iluminação, clima do público, boss quando é final.
- **Cada arma/armadura**: sprite gerado (silhueta + raridade + tinta), coerente com o item que o gerador criou.
- **Cada personagem**: gladiador em camadas, com a sua cor de pele/porte e o seu equipamento visível.
- **Cada cidade**: 3 cenários por faixa de rank, com os locais ancorados.
- **Semente única por campanha**: a mesma campanha sempre gera os mesmos inimigos e cenários (reprodutível),
  e uma campanha nova gera um mundo novo.

---

## 8. Ordem de entrega (cada etapa com teste + QA e commit na `main`)

| Etapa | Conteúdo | Critério de aceite |
| --- | --- | --- |
| **6** ✅ | §3.1 bug do torneio/pontos + §3.2 GANHOU/PERDEU + resumo em modal | reproduzir o bug antes e depois na QA (o torneio **não** reinicia ao distribuir pontos); cartaz antes do resumo |
| **7** ✅ | Gerador de arte + **cidades e arenas** geradas (§4.1/4.2) | `gen_assets.gd` roda headless e produz os PNGs; cidade com imagem de verdade na QA; 3 cenários por faixa |
| **8** ✅ | Gladiador em camadas + **arma na mão** + armaduras no corpo + efeitos + projéteis | QA com print do gladiador equipado e do ataque com arma e projétil |
| **9** ✅ | Itens: pool maior + **variações únicas** + tiers §5.3 | teste de tabela de drop por grau (seed fixa) + variações fora da loja |
| **10** ✅ | Boss final **aleatório** + **COMBATE FINAL** evidente + item só do boss (§5.1/5.3) | sorteio cobrindo o pool, nenhum item em rodada 1..n−1, marcação clara na tela |
| **11** | **Permadeath** no torneio + Mural dos caídos (§6) | aviso e confirmação, personagem apagado na derrota, arena livre intacta |

Depois da 11: rebalanceamento final remedido (a economia e a curva são novamente medidas e registradas no
`BALANCEAMENTO.md`) — é o fecho do 3.0.

---

## 9. Decisões

1. **Arte**: ✅ **decidido (06/10)** — **híbrido**: você gera **folhas (atlas) por família** com o seu gerador e o
   meu código **corta, tinge e compõe** (variação infinita por semente). O contrato de corte e o **inventário
   completo das ~48 folhas com prompts prontos** estão em **`docs/ARTE.md`**. Começo por 6 folhas
   (`A1` herói espadachim, `A13`/`A14` bosses, `B1` cidade, `B4` arena, `F1`/`F2` painéis e botões) para provar
   o pipeline ponta a ponta; enquanto elas não chegam, eu gero **placeholders por código** com o mesmo contrato
   (a sua folha depois substitui o placeholder sem trocar uma linha do jogo).
2. **Permadeath**: ✅ **APROVADO por você (06/10 — "Sim, permadeath")**. Implementação na etapa 11, com as
   travas do §6: aviso vermelho + confirmação antes de entrar no torneio, derrota apaga o save, **arena livre
   sem morte permanente** (recomendação minha, mantida) e **Mural dos caídos** guardando a estatística.
3. **Save apagado de verdade** na morte do torneio — ✅ confirmado junto do item 2.
4. **Quantas cidades**: 3 por faixa de rank (`B1`/`B2`/`B3` no `ARTE.md`) — pode aumentar depois, é só folha nova.
5. **Variações únicas**: 8 no total (folha `C14`), um conjunto por torneio.
6. **O "item por rodada" da 1.6 sai de vez** — já implementado na etapa 6: só o boss final dropa.

---

## 10. Resultado da etapa 6 — medido (06/10/2026)

**As quatro correções, como ficaram:**

1. **Bug do torneio (pontos → cidade → torneio reiniciado): corrigido com três travas.**
   `DISTRIBUIR PONTOS` agora abre `scripts/ui/points_panel.gd` — um **modal "só pontos" por cima do resultado**,
   com o botão **VOLTAR AO RESULTADO** (não troca de tela). `show_city()` **recusa** abrir durante o torneio e
   redireciona para a rodada com o aviso *"Você está no torneio — Combate x/4"*. `start_tournament()` **recusa
   reiniciar** um torneio em andamento; abandonar exige **ABANDONAR TORNEIO** → **CONFIRMAR ABANDONO**, e o
   abandono **conta derrota no KD**.
   **Prova (teste de fluxo):** vence a rodada 2/4 com pontos pendentes → distribui os pontos no modal → *"DEPOIS
   de distribuir, o torneio CONTINUA na MESMA rodada"* (rodada inalterada); `show_city()` → *"a CIDADE não abre
   durante o torneio"*; abandono → *"registra a derrota no KD (0 → 1)"*.
2. **Cartaz antes do resumo:** caindo o último golpe a arena mostra **`VOCÊ VENCEU`** / **`VOCÊ PERDEU`** com
   *"<adversário> — N rodadas"* e o botão **CONTINUAR**; **só o CONTINUAR** abre o resumo, e o resumo agora é um
   **modal sobre a arena** (`show_result_modal`) — a arena continua na árvore de nós (é o que prova que o resumo
   virou modal, e não uma tela cheia).
3. **Item só do boss final:** as rodadas 1..n−1 passam a dar **apenas ouro + XP**. Medido no nível 5, com ouro
   base 56/luta e público ×1,0: ouro **inalterado** (224 / 360 / 536 nos três torneios) e itens caem de **5 para
   1** por torneio. O `gladius_magnus` só cai da rodada final. A **Arena Livre ficou intocada**.
4. **COMBATE FINAL evidente:** faixa vermelho/dourada **`COMBATE FINAL — <boss>`** na **apresentação** e na
   **arena**, com a linha *"Só aqui o troféu do campeão aparece."* e o aviso no log de combate.
   (O **sorteio** do boss final e a **tabela de drop por dificuldade** são a etapa 10 — aqui só a marcação, como
   planejado.)

**Testes:** `run_systems_test` PASS (3 regras novas: cidade bloqueada, `start_tournament` recusando, item só na
final), `flow_smoke` PASS (cartaz antes do resumo, cenário do bug, bloqueio da cidade, abandono, COMBATE FINAL) e
`run_balance_test` PASS **sem nenhum critério afrouxado**.

---

## 11. Resultado da etapa 7 — medido (06/10/2026)

**Gerador de arte no próprio engine, headless, determinístico por seed.**

```
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . -s res://tools/gen_assets.gd -- --seed 1307
```

| id | tipo | faixa | dimensões |
| --- | --- | --- | --- |
| B1 · B2 · B3 | cidades | areia · ferro · prata | 1536x1024 cada |
| B4 · B5 · B6 · B7 · B8 | arenas | areia · cascalho · noturna · nobre · **covil do boss** | 1536x1024 cada |
| B9 | plateia | todas | 1536x256 |
| F1 · F2 | painel e botão 9-slice | todas | 256x256 · 256x96 |

**O que mudou na cidade (o pedido).** Antes a tela da cidade usava **o piso da arena** (`arena_ground.jpeg`) +
as duas muralhas. Agora cada faixa de rank tem **cidade própria** (B1 areia ensolarada, B2 ferro avermelhada, B3
mármore com crepúsculo púrpura) com céu, prédios com telhado e janelas acesas, torres com bandeira, tochas com
brilho, bancas e poeira. O **terço inferior é escurecido de propósito** para os botões de local ficarem legíveis
(a sombra caiu de 0,52 para 0,34 quando a arte nova está ativa). A arena passa a usar **a arena da faixa** e o
**covil vermelho** no COMBATE FINAL.

**Critérios atendidos:** o gerador é **idempotente** (duas execuções seguidas dão bytes idênticos) e **sensível ao
seed**; `tests/run_assets_test.gd` valida o manifesto (todo id no disco, com as dimensões declaradas) e **falha
com mensagem clara** se o gerador não tiver rodado; `AssetCatalog.texture(id)` cai nos **assets antigos** se o
manifesto faltar, o id não existir ou o PNG estiver ausente — **nunca fica sem fundo** (testado: com `B1.png`
escondida, o fundo antigo aparece e nada quebra).

**Nada foi apagado:** `assets/sprites/` está intacto (só foi lido). Os PNGs novos vivem em `assets/gen/` com os
**mesmos ids do `ARTE.md`**, então **as folhas geradas por você substituem a arte sem tocar em uma linha do jogo**.

**O que ficou de fora (honesto):** F1/F2 foram gerados mas **ainda não integrados** à UI (cidade e arena primeiro,
como combinado); a plateia B9 foi gerada mas ainda não entrou como camada própria (hoje ela vem embutida em cada
arena); e nas arenas a "plateia" é abstrata (arcos/silhuetas) — é o limite da arte por código, e é justamente o
que as folhas suas vão substituir.

---

---

## 12. Resultado da etapa 8 — medido (06/10/2026)

**A luta passou a ANIMAR por pose, o golpe tem efeito, a ação à distância tem projétil, e a sua folha de personagem
tem porta de entrada própria (com precedência sobre a arte atual).** Nada de arte nova foi inventado: as poses usam
os PNGs `hero_*.png` / `enemy_*.png` que já existiam (estavam sem uso).

**1. Animação por pose (evento → sprite).** Um ponto único de troca (`_update_fighter_visuals`, usado pelos DOIS
lutadores) resolve a textura via `FighterVisuals`:

| Evento da luta | Pose | Fonte |
| --- | --- | --- |
| ataca (golpe/investida/tiro do herói ou do inimigo) | `attack` | `hero_attack.png` / `enemy_attack.png` |
| defesa firme / dormir / exibir / taunt / esquiva / aparo | `defend` | `hero_defend.png` / `enemy_defend.png` |
| levou dano de verdade | `hit` | `hero_hit.png` / `enemy_hit.png` |
| fim da ação/turno | `idle` | `hero.png` / `enemy.png` |
| **alguém caiu** (fim de luta) | `fallen` | a pose de levado **inclinada ~82° e escurecida** (sem arte nova) |

A troca dura ~0,3s e volta ao repouso (tween, sem `await` na lógica da luta) — **o ritmo não muda**. No fim da luta
o derrotado fica na pose caída e o cartaz `VOCÊ VENCEU/PERDEU` continua por cima (é overlay da arena).

**2. Efeitos e projéteis 100% por código** (`scripts/ui/fight_effects.gd`, Line2D/Polygon2D + tween):

- golpe corpo a corpo → **arco de corte** branco/dourado (~0,28s);
- aparo → **anel de faísca** (~0,28s);
- dano levado → **respingo** curto no sentido do golpe (~0,3s);
- recuo/avanço → **puff de poeira** nos pés (~0,5s);
- `tiro`/`tiro_certeiro`/`bombardeio` (arco/besta/arremesso) → **projétil voando** do atacante ao alvo, com rotação,
  rastro leve e faísca de impacto; a duração cresce com a **faixa de distância** já usada pelo combate.

Nada disso bloqueia a luta (dispara-e-esquece) — **o balanceamento não sentiu diferença** (§ abaixo).

**3. Porta de entrada da sua folha** (`assets/gen/characters.json` + `FighterVisuals`): o manifesto mapeia
`char_id` + pose semântica (`idle`/`ataque`/`defesa`/`levado`/`caido`) → PNG, com **precedência** sobre os
`hero_*`/`enemy_*`. Se a entrada ou o PNG faltarem, cai no sprite atual (o lutador nunca some). O comando exato do
cortador, por personagem, está em **`docs/ARTE.md` §7** (mesmo padrão do `AssetCatalog`).

**Testes:** `run_systems_test` PASS (novos: pose por evento, esquema do manifesto, fallback sem manifesto,
**precedência** do manifesto), `run_assets_test` PASS, `run_balance_test` PASS **sem nenhum critério afrouxado** e
`run_flow_smoke` PASS. (O `flow_smoke` tinha um *flake* raro de ~10%: o golpe único do cenário de torneio podia ser
esquivado por um inimigo com o traço Ágil / absorvido pela armadura; o cenário agora zera a armadura e marca o alvo
como vulnerável — **nenhuma asserção foi alterada**.)

**QA visual (jogo aberto):** prints do herói na pose de ATAQUE, do inimigo na pose de levado, do herói APARANDO (com
faísca), do arco de corte, de um PROJÉTIL voando (luta com arco) e do derrotado caído.

**O que ficou de fora (honesto):** os efeitos são geométricos (linhas/polígonos) — é o limite da arte por código; a
sua folha D1/D2 (`ARTE.md` §3-D) substitui por arte pintada quando quiser, pelo mesmo contrato. Andar/celebrar
seguem fora (como no §4.2: menor retorno agora). A ia de movimento já gera poeira, mas uma animação de caminhada
de verdade precisa de mais quadros de pose.

---

## 13. Resultado da etapa 9 — medido (06/10/2026)

**Pool maior.** Silhuetas por classe de arma: espada 6 · adaga 5 · machado 5 · lança 5 · arco 5 · besta 4 ·
arremesso 4. Por peça de armadura: peitoral 5 · capacete 5 · luvas 4 · botas 4 · cinto 4. A loja passou a
mostrar até 5 por tipo. **11 afixos** aplicados pelo gerador, com limite por raridade (Comum 0 · Incomum 1 ·
Raro 1–2 · Épico 2–3): os 7 atributos + armadura, e os exclusivos **Cortante** (`crit_bonus` +2–5 p.p.),
**Teimoso** (`taunt_resist` +4–10) e **Cobiçoso** (`gold_bonus` +3–8%) — todos ligados à mecânica (crítico,
Taunt, ouro e combate), com peso no preço para não existir item barato-e-forte.

**As 8 variações únicas** (fora da loja, não vendáveis, só de boss, um conjunto por torneio):

| Torneio | Item | Efeito exclusivo (onde morde) |
| --- | --- | --- |
| Menor t1 | **Adaga da Viúva** | REVIDA **sempre** que apara (`combat_resolver`) |
| Menor t1 | **Manto do Público** | EXIBIR **+50%** e não deixa aberto (`arena` + `crowd_system`) |
| Maior t2 | **Elmo do Imperador** | **imune a Taunt** (`combat_resolver.taunt_chance` → 0) |
| Maior t2 | **Botas do Mensageiro** | +0,15 esquiva **ignorando o teto** (`dodge_chance`) |
| Maior t2 | **Luvas do Carrasco** | **+15% crítico** (`critical_chance`) |
| Grande t3 | **Gládio do Grande Gladiador** | **+20% dano corpo a corpo** |
| Grande t3 | **Pingente do Sortudo** | **+25% ouro** por vitória (`player_gold_multiplier`) |
| Grande t3 | **Coração de Bronze** | **Segundo Sopro**: sobrevive ao 1º golpe fatal |

Cada efeito tem teste de comportamento real (ex.: 287/287 aparadas revidaram com a Adaga; Taunt com o Elmo
medido em 0).

**Tabela de drop por grau — medida com 20.000 amostras por grau (seed 424242) contra o plano:**

| Grau | Comum | Incomum | Raro | Épico | Lendário |
| --- | --- | --- | --- | --- | --- |
| 1 | 55 (55) | 25 (25) | 12 (12) | 6 (6) | 2 (2) |
| 2 | 40 (40) | 28 (28) | 19 (18) | 10 (10) | 4 (4) |
| 3 | 28 (28) | 30 (30) | 24 (24) | 13 (13) | 5 (5) |
| 4 | 15 (15) | 28 (28) | 30 (30) | 19 (19) | 8 (8) |
| 5 | 10 (10) | 22 (22) | 32 (32) | 26 (26) | 10 (10) |

Pior desvio **0,59 p.p.** (limite ±3) e monotonicidade confirmada. O peso efetivo é o do plano **+ empurrão do
tier** (`0/8/16`) **+ peso pequeno do rank** (≤4) **+ teto anti-farm de única** (t1 ≤4%, t2 ≤7%, t3 ≤10%) — o
torneio Menor fica exatamente na régua do plano. Anti-farm: a mesma variação **não repete** enquanto você não
tiver todas.

**Verificação minha:** regras PASS (4 testes novos), arte PASS, fluxo PASS e balanceamento PASS (`BAL=0`); a
asserção ajustada continua exigindo **exatamente 1 item, só na final** e ficou **mais forte** (agora valida a
raridade e o conjunto do tier). QA com o jogo aberto: apresentação do boss com o grau, arena, vitória de
torneio, prêmio de item e a bolsa com a variação única.

**Defeito visual corrigido por mim:** o grau saía com **retângulos vazios** porque o código usava o emoji `⭐`,
que **não existe na fonte padrão do Godot**. Medi os glifos por renderização (`qa/qa_glyphs.tscn`, porque
`has_char()` mente): a fonte **tem** `★ ☆ ✦ ✧ ✪ ● ■ ◆ ▲ ✚ ✖ ⚔ ☠ ♥` e **não tem** `⭐`. Trocado por `★` — a
apresentação agora mostra `★★★★★ (5/5)`.

---

## 14. Resultado da etapa 10 — medido (06/10/2026)

**POOL DE BOSSES FINAIS por torneio (§5.3).** `data/tournaments.json` ganhou `boss_pool` e
`data/enemies.json` ganhou **18 bosses** (6 por tier, 24 inimigos no arquivo com os 6 base intactos). Cada
candidato tem nome próprio, apelido, descrição (altura/peso), **traço** e uma **fraqueza que combina com o
traço**. O **grau (1–5)** é uma FAIXA por tier, com o topo no candidato mais duro do pool:
**Menor 1–3 · Maior 3–4 · Grande 4–5**. Como o grau define a tabela de drop, o torneio de entrada **não**
entrega mais a tabela do Grande — o plano avisa contra "farm de lendário no torneio pequeno".

| Torneio | id | Nome | Grau | Traço | HP/ATK/DEF/SORTE |
| --- | --- | --- | --- | --- | --- |
| Menor t1 | `t1_casca` | Casca, o Cabeção | 1★ | Lento | 110/13/8/3 |
| Menor t1 | `t1_medo` | Medo, o Exibido | 1★ | Frágil | 96/12/7/4 |
| Menor t1 | `t1_pulga` | Pulga, o Escorregadio | 2★ | Ágil | 97/13/7/6 |
| Menor t1 | `t1_muralha` | Muralha, o Bloqueio | 2★ | Couraçado | 95/13/7/4 |
| Menor t1 | `t1_garra` | Garra, a Fera da Areia | 3★ | Fera | 120/15/9/5 |
| Menor t1 | `t1_vulcano` | Vulcano, o Forjado | 3★ | Vidro | 132/16/10/7 |
| Maior t2 | `t2_cinza` | Cinza, o Sombrio | 3★ | Ágil | 86/11/6/7 |
| Maior t2 | `t2_ferro` | Ferro, o Teimoso | 3★ | Couraçado | 95/13/7/5 |
| Maior t2 | `t2_aguia` | Águia, a Implacável | 3★ | Frágil | 96/12/7/6 |
| Maior t2 | `t2_titano` | Titano, o Colosso | 3★ | Lento | 124/15/9/6 |
| Maior t2 | `t2_touro` | Touro, o Indomável | 4★ | Fera | 120/15/9/7 |
| Maior t2 | `t2_rufus` | Rufus, o Tormenta | 4★ | Vidro | 132/16/10/8 |
| Grande t3 | `t3_automato` | Ferro-Vivo, o Autômato | 4★ | Couraçado | 95/13/7/6 |
| Grande t3 | `t3_viuva` | A Viúva de Ébano | 4★ | Ágil | 97/13/7/9 |
| Grande t3 | `t3_carrasco` | O Carrasco Mudo | 4★ | Lento | 124/15/9/6 |
| Grande t3 | `t3_leao` | Leão de Bronze | 5★ | Fera | 120/15/9/8 |
| Grande t3 | `t3_tirano` | Tirano Sanguinário | 5★ | Vidro | 132/16/10/9 |
| Grande t3 | `t3_campeao` | O Campeão Sem Coroa | 5★ | Fera | 120/15/9/9 |

**Calibração e grau.** O `grade` **não entra no combate** (só na apresentação/arena e na tabela de drop),
então o grau foi atribuído pela FAIXA do tier e pela dureza REAL medida — não precisa mexer nas taxas. A
força dos candidatos foi calibrada contra o boss final antigo (`grande_gladiador`, hp120/atk15/def9), que
era quem produzia a curva do §5.3; o HP/ATK do pool é compensado pelo **traço** (o `Frágil`/`Lento`/`Vidro`
levam mais vida/ataque, o `Couraçado`/`Ágil`/`Fera` levam menos) para que a faixa de grau case com a dureza.
O `rounds` de cada tier aponta para o **pior-caso do pool** (`t1_vulcano`, `t2_touro`, `t3_tirano`) — é o
valor que o `run_balance_test.gd` mede.

**Sorteio (§5.3).** `scripts/systems/boss_pool.gd` (`BossPool`) é a camada PURA: `pool_for(tier_id)` lê o pool
do próprio tier e `draw_final_boss(tier_id, rng, previous_id)` sorteia excluindo o último do tier (RNG
opcional → reprodutível por seed). A UI **não** sorteia: `GameState.draw_final_boss(tier_id, rng)` guarda o
resultado em `final_boss_id` e a **memória curta** em `last_final_boss_by_tier` (por tier) para não repetir o
mesmo boss duas vezes seguidas. `build_current_foe()` materializa esse boss na rodada final; apresentação,
arena e drop leem o **mesmo** boss.

**Cobertura MEDIDA (log de `run_systems_test.gd`, seed `20261010`, 400 sorteios por tier):**

```
[t1] 400 sorteios | 6/6 candidatos do pool apareceram | 0 sorteados de fora do tier | 0 repetições em sequência
[t2] 400 sorteios | 6/6 candidatos do pool apareceram | 0 sorteados de fora do tier | 0 repetições em sequência
[t3] 400 sorteios | 6/6 candidatos do pool apareceram | 0 sorteados de fora do tier | 0 repetições em sequência
GameState.draw_final_boss('t2') em 30 sorteios seguidos: t2_rufus, t2_cinza, t2_ferro, t2_touro, t2_aguia,
  t2_touro, t2_rufus, t2_ferro, t2_titano, t2_rufus, t2_aguia, t2_ferro, ... (nenhum adjacente igual)
```

O grau do boss **sorteado** alimenta a tabela de drop: testado para os 6 bosses do t2 (`_final_boss_grade()` ==
o grau do template) e pela linha do plano (g1 `comum 55%` vs g5 `comum 10%`). A vitória final continua
entregando **exatamente 1 item** (do conjunto do tier), e rodadas 1..n−1 seguem só ouro + XP.

**Escada de prêmio (mix de raridade esperado na final = grau do boss sorteado + empurrão do tier/rank):**

| Torneio | Grau de referência | Comum | Incomum | Raro | Épico | Lendário | Épico+Lendário |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Menor t1 | 3★ | 28% | 30% | 24% | 14% | 4% | **18%** |
| Maior t2 | 4★ | 5% | 28% | 34% | 26% | 7% | **33%** |
| Grande t3 | 5★ | 5% | 22% | 34% | 29% | 10% | **39%** |

(a média do pool desenhado: Menor 13% · Maior 27% · Grande 36% de épico+lendário.) Com as faixas de grau
1–3/3–4/4–5, o Menor **deixa de entregar a tabela do Grande** — subir de tier volta a valer a pena.

**Balanceamento ANTES → DEPOIS (o `run_balance_test.gd` NÃO foi tocado; metas 60/50/50 intactas):**

| Medida | Antes (etapa 9) | Depois (etapa 10) | Meta |
| --- | --- | --- | --- |
| Torneio Menor, nível 5 equipado | 97% | **97%** | 60% |
| Torneio Maior, nível 8 equipado | 93% | **93%** | 50% |
| Grande Torneio, nível 12 equipado | 90% | **91%** | 50% |
| Escada (nível 5): menor > maior ≥ grande | 96 > 80 ≥ 44 | **97 > 81 ≥ 47** | ordem obrigatória |

A ferramenta `tools/measure_pool.gd` (não é suíte) mediu os 18 candidatos contra a régua antiga
(`grande_gladiador`, que reproduz 96/91/89 no alvo e 96/76/41 no nível 5): no alvo, Menor 97–100%,
Maior 92–99%, Grande 89–97%; no nível 5, o pior caso por tier é 97% / 79% / 39%. **O grau NÃO move essas
taxas:** medido antes e depois de trocar os graus para as faixas do §5.3, o `measure_pool` deu resultado
**idêntico linha a linha** (só o rótulo "grau N" muda) — confirmando que o `grade` é só drop/apresentação.

**Verificação:** regras **PASS** (4 testes novos: forma/isolamento dos pools, cobertura + anti-repetição, grau →
drop, boss materializado na final), arte **PASS**, **fluxo PASS** e **balanceamento PASS** (`EXIT=0`). QA com o
jogo aberto: **duas finais diferentes** — `Pulga, o Escorregadio` (2★, prêmio **Comum** `Pique`) no Menor e
`A Viúva de Ébano` (4★, prêmio **Raro** `Lança longa`) no Grande — cada uma com a faixa COMBATE FINAL, o grau
em estrelas, a apresentação completa (apelido/descrição/fraqueza/provocação) e o prêmio do boss.

**Defeito de teste corrigido:** a asserção do símbolo de grau em `run_systems_test.gd` ainda usava o emoji
`⭐` (o código já usa `★` desde a etapa 9) e `enemies.size() == 6` (o roster cresceu para 24) — ambos eram
falhas **pré-existentes da etapa 9**; ajustados para `★` e para "os 6 lutadores base continuam presentes".
