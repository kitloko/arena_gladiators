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
| **1** | A (6 atributos) + 1 (pontos no nível) + E (armadura como reserva, esquiva, auto-defesa com 'aparou X, entrou Y') + 7 (ações nomeadas) + C (Taunt) + D (Sleep) | regras PASS (testes novos por atributo e por ação); balanceamento PASS sem afrouxar critérios (Arena Livre alta no nível 1, sem desabar; 3 torneios concluíveis em dificuldade crescente); fluxo PASS; duas barras na tela de luta; save antigo migrado |
| **2** | H (felicidade do público + EXIBIR + multiplicador) | eventos mexendo a barra (teste por evento); ×1,0 a ×2,0; ≤3 ações não multiplica; **teste anti-exploit** (spam de EXIBIR / fuga não rendem mais ouro por hora); linha do público no resultado |
| **3** | I (rank/KD + títulos + acesso por rank) + B (cidade cenário) + 9 (arenas por faixa) | rank sobe/desce conforme a força do adversário; **farm não chega ao topo**; rebaixa ao cair do piso; destino trancado com motivo; arena mais lotada eleva a felicidade inicial; cidade navegável por cenário |
| **4** | F (apresentação + comparação antes da luta) + G (apelidos/identidade) | tela aparece antes da luta com as estatísticas comparadas e o Índice de Poder; ENTRAR NA ARENA inicia o combate; provocação sorteada |
| **5** | 2 (ferimentos) + 4 (pechincha) + 5 (apostas) + 6 (poções em combate) + 10 (médico/ferreiro/treinador) | cada mecânica com teste próprio e efeito medido; economia final remedida (ouro por hora dentro do esperado) |

**Definição de pronto:** todas as etapas acima verdes, com evidência (saída dos testes + capturas do jogo
rodando) arquivada em `/root/workspace/docs/arena-gladiadores/`, e o README/documentos atualizados.
