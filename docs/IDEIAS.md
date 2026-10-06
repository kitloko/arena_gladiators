# Backlog de ideias — Arena dos Gladiadores

Documento único de ideias/roadmap. **Nada aqui está implementado** sem OK explícito.
Cada item diz o que é, por que vale, **onde encosta no código**, o esforço e **como verificar**.

Referências do dono do projeto (Swords and Sandals — SOS): criação com 8 atributos, cidade como cenário
com locais clicáveis, apresentação do adversário com comparação antes da luta, e combate com **Taunt**,
**Sleep**, **armadura como reserva separada da vida**, auto-defesa e evasão.

Pedidos novos de 06/10 (segunda leva): **felicidade do público** (barra na luta, eventos que sobem/descem e
multiplicador de recompensa — item **H**) e **rank/KD** separado do nível, com títulos, arenas por rank mínimo
e arena mais cheia conforme o rank (item **I**).

> **Correção de leitura registrada (06/10/2026):** o item "mais atributos" do playtest **não era** mais
> pontos de distribuição — era **mais categorias de atributo** (o SOS tem 8: strength, attack, defence,
> agility, charisma, vitality, stamina, magicka). Os 20 pontos entregues na 1.6 seguem válidos; o que muda
> com a ideia A é **quais atributos existem**. Hoje o jogo tem 4 (vida, ataque, defesa, sorte) — ver item A.

---

## A. Atributos no estilo SOS (8 categorias) — *grande*

**Estado hoje:** 4 atributos (`health`/`attack`/`defense`/`luck`) em `scripts/models/gladiator_data.gd`,
distribuídos na criação (`scripts/ui/creation_screen.gd`) e usados em `scripts/systems/combat_resolver.gd`.

**Referência do SOS (tela de criação):** `strength · agility · attack · defence · vitality · charisma ·
stamina · magicka`, com *skill points* para distribuir. Na comparação da luta eles aparecem como
`STR · ATT · DEF · AGI · CHA · VIT · STA · MAG`.

**Proposta de mapeamento para o que o jogo já tem:**

| Atributo | O que faz aqui | Onde encosta |
| --- | --- | --- |
| **Força (STR)** | dano corpo a corpo (o que hoje é `attack` para melee) | `combat_resolver` (cálculo de dano) |
| **Ataque (ATT)** | precisão — chance de acertar (hoje existe `accuracy` no resolver, sem atributo por trás) | `combat_resolver.resolve_attack` |
| **Defesa (DEF)** | chance de **aparar/auto-defender** (reduz o dano) | `combat_resolver` (defesa automática) |
| **Agilidade (AGI)** | esquiva + iniciativa (quem age primeiro no turno) | `combat_resolver` (evasão/ordem) |
| **Vitalidade (VIT)** | vida máxima (hoje `health`) | `gladiator_data` |
| **Carisma (CHA)** | preço na loja, prêmio dos torneios e eficácia do Taunt | `economy_system`, `shop_screen`, Taunt (item C) |
| **Fôlego (STA)** | nº de ações/sequência por turno — hoje é 1 ação sempre | `combat_resolver`, `arena_screen` |
| **Magicka (MAG)** | base para magias (depende do item F) | novo sistema de magia |

**Por que:** é o item que mais muda a sensação de construir personagem — distribuir 20 pontos entre 8
atributos com efeitos distintos gera builds (bruto, ágil, carismático/negociador, mago).

**Esforço:** grande (toca combate, criação, itens, loja, tela do personagem e o balanceamento inteiro).
**Depende de:** decidir primeiro se entra magia (item F) — sem magia, `MAG` não tem efeito.
**Como verificar:** `tests/run_balance_test.gd` refeito com os atributos novos (a curva não pode inverter);
`tests/run_systems_test.gd` cobrindo cada atributo com efeito mensurável (ex.: +10 AGI reduz o dano recebido
em X% em N simulações).

---

## B. Cidade como cenário, com locais clicáveis — *médio*

**Referência:** `Doomtrek Town Square` — wallpaper da cidade, o personagem parado na praça e **botões
circulares com ícone + nome** para cada local (Weapons, Arena, Armoury, Magic Shoppe), com o nome do lugar e
o horário/dia no centro, e o HUD do personagem no canto (retrato, nível, vida, ouro).

**Hoje:** `scripts/ui/city_screen.gd` é uma lista de botões de texto (LOJA / DESCANSAR / ARENA LIVRE /
TORNEIOS / PERSONAGEM E BOLSA / NOVO GLADIADOR).

**Proposta:** trocar a lista por um cenário desenhado com 4–6 pontos clicáveis (cada um com ícone, nome e
tooltip). Bom momento para **reaproveitar os assets hoje órfãos** (`assets/sprites/arena/arena_ground.jpeg`,
`arena_wall_left/right.png` — ver `PLANO_CORRECOES.md` §5): em vez de apagar, viram o fundo da cidade.
**Esforço:** médio (arte + layout). **Sem dependência.**
**Como verificar:** teste de fluxo já navega pela cidade — as mesmas asserções valem com os botões novos
(achados por texto/nome), mais uma checagem de que os 6 destinos continuam alcançáveis.

---

## C. Taunt (provocar) com % de sucesso — *pequeno*

**Referência:** balão `Taunt: (99%)` sobre o lutador — a ação é anunciada com a chance de funcionar.

**Proposta:** ação de turno que força o inimigo a te atacar (em vez de recuar/defender/usar magia) por
1–2 turnos, com chance de sucesso = f(Carisma do provocador vs Carisma/sabedoria do alvo). Serve para
controlar a luta (segurar o inimigo longe do seu aliado, impedir que ele fuja).
**Onde encosta:** `combat_resolver` (nova ação), `arena_screen` (botão), IA do inimigo (`enemy_*`/resolver).
**Esforço:** pequeno. **Depende de:** Carisma (item A) para a fórmula; sem ele, usa Sorte.
**Como verificar:** simulação com N lutas mostrando a % real de inimigos que atacam em vez de recuar com
e sem Taunt; e o balão com a % na arena (QA visual).

---

## D. Sleep / descanso em combate (cura uma %) — *pequeno*

**Referência:** no SOS o sono cura uma % da vida **enquanto você fica vulnerável** (o inimigo pode te acertar
de graça). No print aparece como uma das ações circulares.

**Proposta:** ação "Dormir/Recuperar": cura X% da vida máxima, mas você fica indefeso no turno seguinte
(o inimigo acerta com bônus). Faz a luta ter um risco/recompensa real em vez de só trocar golpes.
**Onde encosta:** `combat_resolver` (nova ação + estado "vulnerável"), `arena_screen` (botão + balão da %).
**Esforço:** pequeno. **Sem dependência.**
**Como verificar:** teste do resolver (curou a % e, no turno vulnerável, o dano recebido sobe); simulação
mostrando que usar Sleep toda hora **piora** a taxa de vitória (senão é exploit).

---

## E. Armadura como reserva separada + auto-defesa e evasão — *médio*

**Referência:** no print da luta existem **duas barras por lutador**: `HEALTH 170/170` e `ARMOUR 450/450`
(o inimigo em `199/318`); a comparação antes da luta mostra vida, armadura e poções lado a lado.

**Proposta:**
1. **Armadura vira uma reserva própria** (não só bônus de defesa): o dano come a armadura primeiro e só
   depois encosta na vida; itens passam a ter "armadura" (peitoral/capacete/luvas/botas/cinto somam), e a
   armadura se recupera (parte) entre lutas ou com ferreiro.
2. **Auto-defesa:** a defesa dá chance de **aparar** (reduz o dano do golpe que entrou).
3. **Evasão:** o ataque pode **errar** conforme Ataque do atacante vs Agilidade do alvo (o `accuracy` do
   resolver já existe e hoje é passado fixo — vira atributo).

**Por que:** hoje a defesa é só subtração de dano, então "defesa" e "vida" são quase a mesma coisa; com
reserva + aparar + esquivar, equipar armadura pesada vira uma escolha de estilo (aguentar vs esquivar).
**Onde encosta:** `gladiator_data` (novo campo + regeneração), `combat_resolver` (ordem do dano, aparar,
esquiva), `item_generator`/`data/items.json` (armadura por peça), `arena_screen` (segunda barra + números).
**Esforço:** médio. **Depende de:** nada (mas conversa com o item A).
**Como verificar:** simulação de "golpes para matar" com e sem armadura; teste de esquiva (alvo com AGI alta
erra mais); o balanceamento tem de continuar dentro das metas (`run_balance_test.gd`).

---

## F. Apresentação do adversário + comparação antes da luta — *pequeno/médio*

**Referência:** tela com os dois lutadores frente a frente, nome/apelido (`The Sandstorm Orpheus` vs
`Coinlust Huntley`), descrição (`Gunteran Knight, 76, 336 lbs`), as 8 estatísticas lado a lado com um **VS**
no meio e um **POWER SCORE** de cada lado; **provocações em balão** antes do combate
(`"May the fleas of a thousand camels inhabit your bed!"`) e o botão `Enter Arena`.

**Proposta:** antes de cada luta (ou ao menos nas de torneio), uma tela de apresentação com: retrato dos dois,
nome + apelido, as estatísticas comparadas em duas colunas, um **Índice de Poder** (soma ponderada) e uma
**provocação** sorteada de cada lado. Botão "ENTRAR NA ARENA".
**Por que:** dá expectativa, faz o número do inimigo ser lido (hoje o jogador descobre a força dele apanhando)
e reaproveita os arquivos de personagem que já existem.
**Onde encosta:** nova cena `scripts/ui/pre_fight_screen.gd` + `scripts/ui/arena_screen.gd` (chamar antes da
luta), dados de apelido/descrição/provocação em `data/enemies.json`.
**Esforço:** pequeno/médio. **Sem dependência** (a lista de estatísticas cresce sozinha quando o item A entrar).
**Como verificar:** teste de fluxo (a tela aparece antes da luta e "ENTRAR NA ARENA" começa o combate) e QA
visual com screenshot.

---

## G. Sorteio de apelido/identidade do inimigo

Semelhança com o SOS: cada inimigo tem **nome + apelido + biografia curta** ("Dangerous Phaeton Warrior,
618, 230 lbs" = altura/peso). Hoje os inimigos são templates funcionais (`Brutos`, `Lívia, a Falcão`...).
**Proposta:** ampliar `data/enemies.json` com apelidos, descrição, altura/peso (só sabor, mostrado na tela do
item F) e uma fraqueza declarada. **Esforço:** pequeno. **Depende de:** item F para ter onde mostrar.

---

## H. Felicidade do público (entusiasmo da arena) — *médio*

**Pedido:** barra **no topo da tela de luta** com a empolgação da plateia, de **0 a 100%**. Começa conforme o
**carisma** dos dois lutadores (luta contra **chefe já começa mais empolgada**) e termina **multiplicando a
recompensa** — mas luta rápida ou definida em um só golpe **não** multiplica; luta acirrada, com muitas ações,
multiplica mais.

**Valor inicial:** `30 + (carisma_seu + carisma_dele) × 1,5`, com teto de **70%**; se o inimigo for **chefe**,
o início tem piso de **60%**. É aqui que o carisma "melhora a % inicial".

**Tabela de eventos (o que mexe na barra durante a luta):**

| Evento | Efeito |
| --- | --- |
| seu acerto normal | **+2** |
| **acerto crítico** | **+6** |
| **revidar** (contra-ataque depois de aparar) | **+5** |
| você levou um golpe | **+3** (o público gosta de pancadaria) |
| sua vida abaixo de 30% e você **continua atacando** | **+4** por turno (drama) |
| **errou** o ataque | **−5** |
| entrou em **defesa** (postura defensiva) | **−3** |
| **recuou** / ficou correndo (arqueiro preservando distância) | **−6** |
| usou poção / dormiu | **−4** |
| turno em que **ninguém se acertou** | **−2** |
| **EXIBIR** (ação nova) | **+8** (com risco, ver abaixo) |

**Ação nova — EXIBIR:** gasta o turno provocando/posando para a plateia. Dá felicidade, mas **te deixa aberto**:
o inimigo ataca com bônus no turno seguinte, e o **retorno cai por repetição** na mesma luta (+8 → +4 → +2 →
**−5** "o público se cansou"). Sem isso, exibir vira máquina de dinheiro.

**Recompensa:** `multiplicador = 1,0 + felicidade_final/100` → de **×1,0 a ×2,0**. **Luta definida em ≤ 3 ações
não multiplica** (fica em ×1,0 e mostra o recado "o público nem viu a luta") — ou seja, aniquilar rápido paga
menos do que vencer com espetáculo.

**Guardas contra exploit (a barra multiplica dinheiro, então isto é regra, não detalhe):**
- teto de 100% e queda contínua — não existe luta "perfeita" parada no máximo;
- **repetição da mesma ação rende cada vez menos** (EXIBIR, e defender/recuar em sequência);
- luta longa **sem ninguém perder vida** (dois covardes se movendo) faz a barra **cair rápido** (vaias);
- o multiplicador vale **uma única vez**, no fim, e respeita o teto da arena;
- **teste dedicado:** "spam de EXIBIR" e "fugir + defender a luta inteira" **não podem** render mais
  ouro por hora do que lutar direito.

**Onde encosta:** `scripts/ui/arena_screen.gd` (barra no topo + botão EXIBIR + balão da última mudança),
`scripts/systems/combat_resolver.gd` (cada ação devolve o resultado: acerto / erro / crítico / aparou — o
`accuracy` e o crítico já existem, falta expor por ação), `scripts/models/fight_result.gd` (campos `crowd` e
`crowd_multiplier`), `scripts/autoload/game_state.gd` (aplicar o multiplicador na recompensa),
`data/enemies.json` (marcar **chefe** e o carisma do inimigo), `scripts/ui/result_screen.gd` (linha
"Público: 82% → recompensa ×1,8").
**Esforço:** médio. **Depende de:** **Carisma** (item A) para a % inicial — sem o atributo, usaria nível + tier
do inimigo como substituto. **Como verificar:** teste de regras comparando três lutas (morna/fugitiva ×
acirrada × nocaute em 1 golpe) e conferindo o multiplicador final; QA visual com a barra subindo e descendo
pelos eventos; e o **ouro por hora** no `run_balance_test.gd`, que hoje não considera multiplicador nenhum.

---

## I. Rank e KD do gladiador — títulos, acesso e arena cheia — *médio/grande*

**Pedido:** além do **nível**, um **rank** por **pontos ganhos e perdidos a cada luta** — um **KD do
personagem** — com **título por faixa**, **arenas com rank mínimo** e, quanto maior o rank, **mais difícil e
mais lotada** a arena.

**Proposta:**
- **Pontos de rank por luta** conforme a diferença de força: vencer alguém **mais forte** rende muito, vencer
  alguém **muito mais fraco** rende pouco ou **zero** (piso 0, mata o farm); perder **tira** pontos, e perder
  para alguém de rank bem menor tira muito (é vergonhoso).
- **KD** (cartel): vitórias/derrotas registradas, mostradas na tela do personagem e na apresentação antes da
  luta (item F).
- **Faixas com título** (sugestão de cortes, calibrar depois com simulação): Areia `0` · Pedra `200` ·
  Ferro `500` · Aço `900` · Prata `1.500` · Ouro `2.300` · Campeão `3.500` · Lenda `5.000`. Cair abaixo do piso
  da faixa **rebaixa** o rank, com aviso na tela.
- **Acesso por rank:** cada destino tem mínimo — Arena Livre aberta, Torneio Menor a partir de **Pedra**,
  Maior a partir de **Aço**, Grande a partir de **Ouro**. Na cidade o local aparece **trancado com o motivo**
  ("Precisa de rank Aço — você está em Ferro").
- **Arena mais lotada:** o rank alimenta o item **H** — a felicidade inicial **e** o teto do multiplicador
  crescem com o rank (em Ouro a casa está cheia). "Mais difícil" vem da força dos adversários da faixa.

**Onde encosta:** `scripts/models/gladiator_data.gd` (pontos, vitórias, derrotas, rank), `scripts/autoload/
game_state.gd` (somar/tirar no fim da luta e checar acesso), **novo** `data/ranks.json` (faixas, títulos,
pisos, rank mínimo por destino, bônus de público), `scripts/ui/city_screen.gd` (locais trancados + título no
cabeçalho), `scripts/ui/character_screen.gd` (rank, título, KD), `scripts/ui/result_screen.gd` (linha
"Rank: +12 / −0"), `data/tournaments.json` (rank mínimo).
**Esforço:** médio a grande (persistência + telas + economia). **Depende de:** campo novo no **save** com
retrocompatibilidade (o save que já existe não tem rank). **Como verificar:** teste de regras — vencer mais
forte rende mais que vencer mais fraco; perder para rank muito menor dói mais; **rebaixar** ao cair do piso;
destino bloqueado abaixo do rank. E uma **simulação de farm** (jogador vencendo sempre na arena fraca): não
pode chegar ao topo do rank — se chegar, o rank não diz nada.

---

# Ideias já listadas antes (seguem valendo)

1. **Pontos de atributo no nível em vez de menu fixo.** Hoje subir de nível escolhe entre 4 opções prontas
   (+4 ATQ / +4 DEF / +14 VIDA / +2 SORTE). No S&S você recebe pontos e distribui. Casa com o item A e dá
   identidade ao personagem. *(médio)*
2. **Ferimentos depois da derrota.** Perder deixa sequela (ex.: −1 de Força até pagar o médico) — dá peso à
   derrota, que hoje só custa 25% do ouro e cura de graça. *(médio)*
3. **Títulos e fama.** Sequência de vitórias e torneios vencidos viram título ("Novato", "Veterano",
   "Campeão do Grande Torneio"), mostrado na arena e na cidade — progressão visível. *(pequeno)*
   → **absorvido pelo item I**: o título passa a vir do rank, com o KD como histórico.
4. **Mercado negro / pechinchar na loja.** Barra de pechincha (o Carisma/Sorte ajuda) para desconto ou briga
   com o vendedor; item pode ficar mais caro por um tempo. *(médio)*
5. **Apostar em si mesmo.** Antes da luta, apostar ouro no próprio combate com odds pelo tier do inimigo;
   perder a aposta soma ao prejuízo. *(pequeno/médio)* — as odds conversam com o item **H** (público empolgado
   = aposta maior).
6. **Poções e itens de uso em combate.** Slot de consumível na arena (cura, força temporária) — no print do
   SOS as poções aparecem no HUD, com contagem (260 / 190). *(médio)*
7. **Combate: golpe forte / defesa firme com custo.** O print mostra ações nomeadas (`HACK`, `SNIPE`,
   `BOMBARD`): ataques com dano/precisão diferentes em vez de um único "Atacar". *(médio)*
8. **Inimigos com identidade.** Templates com fraqueza/resistência (armadura pesada → lento; ágil → esquiva)
   em vez de só escala numérica. *(médio)* — casa com o item G.
9. **Cidades/arenas diferentes.** Arena Livre com cenários por faixa de nível, cada um com tabela de
   recompensa própria — a S&S tem várias cidades. *(grande)* — casa com o item B.
10. **Mascates/serviços:** médico (cura barata), ferreiro (melhora item +1), treinador (XP pago). *(médio)*

---

## Ordem sugerida (impacto primeiro, esforço depois)

| Fase | Itens | Por quê nesta ordem |
| --- | --- | --- |
| **1 — barato e visível** | F (apresentação/comparação), C (Taunt), D (Sleep), G (apelidos) | meses de "sabor" com risco baixo: não mexem na curva de balanceamento |
| **2 — combate de verdade** | E (armadura como reserva + aparar + esquiva), 7 (ataques nomeados), **H (felicidade do público + EXIBIR)** | muda a matemática do combate: exige refazer `run_balance_test.gd` **antes** de codar. O H depende dos eventos por ação do E/7 |
| **3 — o salto do SOS** | A (8 atributos) + 1 (pontos no nível) + magia | redesenho grande: criação, itens, loja, IA e balanceamento inteiro. O **carisma** do A é o que dá a % inicial do H |
| **4 — mundo e progressão** | **I (rank/KD + títulos + acesso)**, B (cidade cenário), 9 (cidades diferentes), 10 (serviços), 2, 3, 4, 5, 6 | economia e progressão de longo prazo; o I alimenta o H (arena mais cheia com rank maior) |

> **Dependências entre os dois itens novos:** o **I** (rank) mexe no **H** (público) — rank maior = arena mais
> lotada = felicidade inicial e teto do multiplicador maiores. Se a ordem de implementação inverter (H antes do
> I), o H usa o **nível** no lugar do rank e depois é só trocar a fonte do bônus.

Os itens 1–10 já estavam propostos em `docs/PLANO_1.6.md` §7; este documento é a versão consolidada
e ampliada (não substitui o histórico, complementa).
