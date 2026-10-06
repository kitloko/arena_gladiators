# Plano 2.0 — especificação aprovada (06/10/2026)

Especificação **decidida pelo dono do projeto** para o desenvolvimento de A até I e das 10 ideias já listadas.
Este documento manda: em caso de dúvida, vale o que está aqui. As ideias não implementadas estão descritas em
[`IDEIAS.md`](IDEIAS.md); aqui está o que foi **aprovado com regras fechadas** e a ordem de execução.

## 1. Atributos (item A) — decisão fechada

**São 7 atributos:** STR, ATT, DEF, AGI, VIT, CHA e SOR (a Sorte foi acrescentada pelo dono depois da
primeira versão desta especificação).

| Atributo | Papel | Observação |
| --- | --- | --- |
| **STR** | dano corpo a corpo | entra também na fórmula do Taunt |
| **ATT** | precisão (chance de acertar) | |
| **DEF** | chance de **defender**: parte do dano é **bloqueada** | auto-defesa |
| **AGI** | chance de **esquiva**: não toma dano | |
| **VIT** | vida máxima | |
| **CHA** | preço na loja, **felicidade do público**, e **exibição** (aumenta a felicidade) | |
| **SOR** | chance de **acerto crítico**, **resistência a efeitos aleatórios** (reduz a chance de o Taunt do inimigo funcionar) e bônus de **pechincha** na loja | recupera o `luck` que já existia no jogo |
| **STA** | — | **NÃO implementar** |
| **MAG** | — | **NÃO implementar** |

Substituem os 4 antigos (`health`, `attack`, `defense`, `luck`). Save antigo é migrado, não zerado
(`luck` → SOR).

## 2. Armadura (item E)

- Itens das peças de proteção dão **armadura** (proteção), que é um **pool separado da vida**.
- O dano consome **armadura primeiro**; só o excedente fere a vida.
- Restaura junto com a vida (descanso e entrada no torneio); o custo do descanso considera vida + armadura faltantes.
- A tela de luta mostra **duas barras com números**: `HEALTH x/y` e `ARMOUR x/y`.

## 3. Resolução do ataque (item E) — ordem e feedback, texto literal do dono

Quando alguém ataca:

1. **Esquiva** do alvo (AGI) → se esquivou, aparece **"ERROU"** (sem dano).
2. **Auto-defesa** do alvo (DEF) → se defendeu, mostra **quanto foi aparado** e **quanto de dano entrou**
   (ex.: `aparou 6, entrou 4`), com sinalização visual de defesa.
3. Caso contrário, dano cheio.

O resultado precisa ficar **disponível por ação** (acertou / errou / aparou / dano / crítico), porque a barra de
felicidade do público (item H) consome esses eventos.

## 4. Ações de combate nomeadas (ideia 7)

- **Corpo a corpo:** GOLPE (normal) · GOLPE FORTE (dano alto, precisão menor) · INVESTIDA (avança e ataca).
- **À distância:** TIRO (normal) · TIRO CERTEIRO (precisão alta, dano menor) · BOMBARDEIO (dano alto, precisão menor).
- **Comuns:** DEFESA FIRME (não ataca, reduz o dano recebido) · AVANÇAR / RECUAR (já existem).
- Botão **desabilitado quando a ação é impossível** (regra que já existe e continua).

## 5. Taunt (item C) — decisão fechada

Força o adversário a sofrer um **efeito aleatório**, sendo **o mais comum forçá-lo a dar um passo à frente**
(se possível); **se não puder avançar, ele te ataca com precisão baixa**. Chance de sucesso em função de
**CHA** (com peso de STR), exibida na tela (ex.: `Taunt: (73%)`).

## 6. Sleep (item D)

Cura uma **% da vida máxima** (ex.: 25%), mas deixa **vulnerável** no turno seguinte (o inimigo acerta com
bônus / a esquiva não vale). Tem de ser **pior que lutar direito** quando usado em série — isso é critério de teste.

## 7. Pontos de atributo no nível (ideia 1)

Subir de nível rende **pontos para distribuir** entre os 6 atributos (sugestão: 4 por nível) — o menu de 4
pacotes prontos sai. A criação mantém **20 pontos**, agora entre os 6 atributos, exigindo distribuir todos.

## 8. Felicidade do público (item H)

Barra **no topo da luta**, 0 a 100%.

- **Início:** `30 + (CHA_seu + CHA_dele) × 1,5`, teto **70%**; contra **chefe**, piso **60%**.
- **Eventos:** acerto +2 · **crítico +6** · **revidar +5** · levei golpe +3 · vida < 30% continuando a atacar
  **+4/turno** (drama) · **errei −5** · defender −3 · **recuar/correr −6** · poção/dormir −4 · turno sem
  ninguém se acertar −2 · **EXIBIR +8**.
- **EXIBIR:** gasta o turno, dá felicidade, deixa aberto (inimigo ataca com bônus) e **rende cada vez menos**
  na mesma luta (+8 → +4 → +2 → **−5**).
- **Recompensa:** `×1,0 + felicidade/100` → **×1,0 a ×2,0**; **luta definida em ≤ 3 ações não multiplica**
  ("o público nem viu a luta").
- **Anti-exploit (é regra):** repetição rende menos; luta longa **sem ninguém perder vida** faz a barra
  **cair**; o multiplicador vale **uma vez**, no fim. Teste dedicado: spam de EXIBIR e fuga+defesa **não**
  podem render mais ouro/hora que lutar direito.

## 9. Rank e KD (item I) + títulos (ideia 3)

- **Pontos de rank** ganhos/perdidos por luta conforme a diferença de força: vencer mais forte rende muito,
  vencer muito mais fraco rende ~0 (anti-farm); perder tira, e perder para rank menor dói mais.
- **KD** (vitórias/derrotas) visível no personagem e na apresentação antes da luta.
- **Faixas com título** (cortes a calibrar): Areia 0 · Pedra 200 · Ferro 500 · Aço 900 · Prata 1.500 ·
  Ouro 2.300 · Campeão 3.500 · Lenda 5.000, com **rebaixa** ao cair do piso.
- **Acesso:** arena/torneio com rank mínimo; na cidade o destino aparece **trancado com o motivo**.
- **Arena mais lotada:** rank maior eleva a felicidade inicial e o teto do multiplicador do item H.
- A ideia 3 (títulos e fama) fica **absorvida** por este item.

## 10. Apresentação do adversário (item F) + identidade dos inimigos (item G)

Antes da luta: os dois frente a frente, nome + apelido, descrição, os atributos comparados em duas colunas com
**VS**, um **Índice de Poder**, provocação sorteada de cada lado e o botão **ENTRAR NA ARENA**. Os inimigos
ganham apelido, descrição e uma fraqueza declarada (item G).

## 11. Cidade como cenário (item B) + arenas/cidades (ideia 9)

Trocar a lista de botões por um **cenário** com locais clicáveis (ícone + nome + tooltip) e o HUD do
personagem (retrato, nível/rank, vida, ouro). Reaproveitar como fundo os assets hoje órfãos
(`assets/sprites/arena/arena_ground.jpeg`, `arena_wall_left/right.png`) em vez de apagar.

## 12. Demais ideias aprovadas

2. **Ferimentos após derrota** (sequela até pagar o médico). 4. **Pechincha na loja** (CHA/Sorte).
5. **Apostar em si mesmo** (odds pelo tier/rank). 6. **Poções de uso em combate**. 10. **Serviços**: médico,
ferreiro (melhora item), treinador (XP pago).

---

# Ordem de execução e aceite por etapa

Cada etapa termina **verde** (os três conjuntos de testes passando), com **QA rodando o jogo de verdade**,
evidência arquivada e **commit direto na `main`** (exceção combinada para este repositório).

| Etapa | Conteúdo | Aceite |
| --- | --- | --- |
| **1** ✅ | A (**7 atributos**) + 1 (pontos no nível) + E (armadura como reserva, esquiva, auto-defesa com 'aparou X, entrou Y') + 7 (ações nomeadas) + C (Taunt) + D (Sleep) | regras PASS (testes novos por atributo e por ação); balanceamento PASS sem afrouxar critérios (Arena Livre alta no nível 1, sem desabar; 3 torneios concluíveis em dificuldade crescente); fluxo PASS; duas barras na tela de luta; save antigo migrado |
| **2** ✅ | H (felicidade do público + EXIBIR + multiplicador) | eventos mexendo a barra (teste por evento); ×1,0 a ×2,0; ≤3 ações não multiplica; **teste anti-exploit** (spam de EXIBIR / fuga não rendem mais ouro por hora); linha do público no resultado |
| **3** | I (rank/KD + títulos + acesso por rank) + B (cidade cenário) + 9 (arenas por faixa) | rank sobe/desce conforme a força do adversário; **farm não chega ao topo**; rebaixa ao cair do piso; destino trancado com motivo; arena mais lotada eleva a felicidade inicial; cidade navegável por cenário |
| **4** | F (apresentação + comparação antes da luta) + G (apelidos/identidade) | tela aparece antes da luta com as estatísticas comparadas e o Índice de Poder; ENTRAR NA ARENA inicia o combate; provocação sorteada |
| **5** | 2 (ferimentos) + 4 (pechincha) + 5 (apostas) + 6 (poções em combate) + 10 (médico/ferreiro/treinador) | cada mecânica com teste próprio e efeito medido; economia final remedida (ouro por hora dentro do esperado) |

**Definição de pronto:** todas as etapas acima verdes, com evidência (saída dos testes + capturas do jogo
rodando) arquivada em `/root/workspace/docs/arena-gladiadores/`, e o README/documentos atualizados.

---

## Resultado da etapa 1 — medido (06/10/2026, commit `75ef6a0`)

**Fórmulas em vigor** (implementadas e testadas):

| Regra | Fórmula |
| --- | --- |
| Vida máxima | `10 + VIT × 6` |
| Armadura máxima | soma de `armour` dos itens equipados (reserva separada: o dano consome armadura antes da vida) |
| Acerto (ATT) | `clamp(precisão_da_ação + ATT × 0,010, 0, 1)` |
| Esquiva (AGI) | `clamp(AGI × 0,010, 0, 0,45)` → dano zero, mensagem **ERROU** |
| Auto-defesa (DEF) | `clamp(DEF × 0,010, 0, 0,50)`; ao aparar, `blocked = round(dano × 0,5)` e **"aparou X, entrou Y"** |
| Dano | `max(1, round(STR × mult + rand(−3,4) − DEF × 0,55))` |
| Crítico (SOR) | `clamp(0,06 + SOR/240, 0, 1) × 1,55` (SOR 5 → 8,1%; SOR 60 → 31,0%) |
| DEFESA FIRME | reduz 30% do dano que entra (teto 60%) |
| Taunt | `clamp(0,40 + (CHA_a − CHA_d) × 0,02 + STR_a × 0,01 + SOR_a × 0,005 − DEF_d × 0,012 − SOR_d × 0,015, 0,05, 0,95)`; efeitos: **avança 55%** / ataca com precisão baixa 25% / tropeça 20%; SORTE do alvo resiste ao empurrão |
| DORMIR | cura **25%** da vida máxima, vulnerável no próximo golpe (inimigo +30% de precisão, sem esquiva) |
| Nível | **4 pontos** de atributo para distribuir entre os 7 (o menu de 4 pacotes deixou de existir) |
| Inimigo (Arena Livre) | `vida = max(20, 25 + L×7 + T×8 ± 6)`, `STR = max(4, 7 + round(L×1,75) + T×2 ± 2)`, `DEF = max(1, 2 + round(L×1,05) + T×2)`, `ATT = max(4, 5 + round(L×0,5) + T)`, `AGI = max(1, 2 + T)` |

**Curva medida** (4.000 lutas por nível, seed fixa):

| Nível | Jogador vida/STR/DEF | Arena Livre sem loja | com loja |
| --- | --- | --- | --- |
| 1 | 88/20/7 | 100% | 100% |
| 3 | 100/28/9 | 93% | 99% |
| 5 | 100/31/11 | 93% | 99% |
| 8 | 130/41/14 | 92% | 100% |
| 12 | 148/50/18 | 91% | 100% |
| 15 | 166/57/21 | 92% | 100% |

Torneios (jogador nos 6 slots): **Menor** 64% no nível 1 → 100% no 15 · **Maior** 8% → 98% ·
**Grande** 0% → 89% (escada de dificuldade preservada). Nível 1 continua gerando só tier 1 (maior vida 46).

**Testes novos da etapa 1** (todos verdes): acerto por ATT · esquiva por AGI (3.000 amostras) · auto-defesa com
"aparou X, entrou Y" coerentes (X+Y = dano) · armadura absorvendo antes da vida · crítico por SOR · Taunt com
maioria empurrando para frente e SORTE resistindo · DORMIR curando 25% e sem ser melhor que atacar
(0 vitórias em 200 lutas de quem só dorme) · ações nomeadas · distribuição dos pontos de nível.

**QA com o jogo aberto** (23 telas em `/root/workspace/docs/arena-gladiadores/qa20/`): criação com os 7
atributos (STR 14 · ATT 11 · DEF 6 · AGI 8 · VIT 9 · CHA 6 · SOR 6, vida 64) · botões GOLPE / GOLPE FORTE
[desabilitados fora de alcance] / INVESTIDA / DEFESA FIRME / AVANÇAR / RECUAR / **TAUNT: (43%)** / DORMIR ·
log com *"Taunt: Míria, a Raposa avança um passo forçado (distância 1)"* · auto-defesa registrada
(*aparado 6*) · pontos gastos ao vivo na tela do personagem (VIT 9 → 17, vida máxima 64 → 112) · vida cheia
ao entrar no torneio (16 → 64).

---

## Resultado da etapa 2 — medido (06/10/2026, commit `42d14f1`)

**Fórmulas em vigor:**

| Regra | Fórmula |
| --- | --- |
| Felicidade inicial | `clamp(30 + (CHA_você + CHA_inimigo) × 1,5, 0, 70)`; em luta contra **chefe**, piso **60** |
| Eventos | acerto **+2** · crítico **+6** · revidar **+5** · levou golpe **+3** · drama (vida < 30% atacando) **+4** · errou **−5** · defesa **−3** · recuo **−6** · dormir **−4** · rodada fria **−2** (agravando: −2, −4, −6…) · repetir defesa/recuo custa **−2 extra** por repetição |
| **EXIBIR** | +8 → +4 → +2 → **−5** na mesma luta; deixa **ABERTO** (+25% de precisão ao inimigo e a esquiva não vale no turno) |
| **REVIDAR** | ao aparar: 50% de chance, dano = `round(valor_aparado × 0,6)`, armadura absorve antes |
| Recompensa | `clamp(1,0 + felicidade/100, 1,0, 2,0)` aplicado ao ouro (arena livre **e** rodadas de torneio); **≤ 3 ações do jogador → ×1,0** ("o público nem viu a luta") |
| Chefe | `imperator` e `grande_gladiador` marcados com `"boss": true` em `data/enemies.json` |

**Anti-exploit (o número que importa, medido em teste):**

| Estratégia | Ouro por ação | Vitórias |
| --- | --- | --- |
| Lutar direito | **14,16** | 400 |
| Spam de **EXIBIR** | **0,000** | 0 |
| Fugir + defender a luta toda | **0,000** | 0 |

**Economia com o multiplicador** (ouro por luta, sem loja / 2 peças):

| Nível | Mult. médio | Sem loja | 2 peças |
| --- | --- | --- | --- |
| 1 | ×1,19 | 30,6 | 27,6 |
| 5 | ×1,34 | 108,2 | 113,7 |
| 10 | ×1,50 | 206,4 | 203,7 |
| 15 | ×1,51 | 298,9 | 303,6 |

**Efeito no balanceamento:** o contra-ataque (REVIDAR) deixou os torneios um pouco mais difíceis — Menor nv1
(6 slots) 64% → 61%, Grande nv12 83% → 76% — **sem afrouxar nenhum critério** (todos continuam passando).

**QA com o jogo aberto** (23 telas em `/root/workspace/docs/arena-gladiadores/qa21/`): barra **PÚBLICO DA ARENA**
no topo com a % (48%, 56%, 53% conforme o carisma dos envolvidos), botão **EXIBIR** junto das demais ações,
log com a variação por evento (*"Público −6 (arena fria) → 39%"*, *"Público +2 (acerto) → 41%"*), multiplicador
final calculado (×1,55 e ×1,73) e a linha **"Público: 57% → recompensa ×1,6"** na tela de resultado. A esquiva
apareceu em jogo (*ERROU* registrado) e as duas barras de VIDA/ARMADURA seguem na tela.
