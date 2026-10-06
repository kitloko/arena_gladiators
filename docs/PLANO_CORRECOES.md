# Plano de correções 1.5 — balanceamento, bugs e UX

Base: commit `86bd28b` (protótipo 1.4). Referência da análise que originou este plano: revisão técnica
do commit (screenshots + simulação de balanceamento com as regras reais do jogo).

**Motivo em uma frase:** o jogo está certo de arquitetura e abre sem erro, mas a curva de progressão está
invertida (o inimigo escala mais rápido que o jogador) e isso fecha o Torneio — que é o conteúdo de fim de jogo.

## Definição de pronto (critérios numéricos)

Nada aqui é "achismo": cada item tem número e método de verificação. A verificação vira teste no repo
(`tests/run_balance_test.gd`), para o balanceamento não regredir em silêncio.

| # | Critério | Antes | Meta | Medido (1.5) | Como medir |
| --- | --- | --- | --- | --- | --- |
| B1 | Vitória na Arena Livre, nível 1, **sem** comprar equipamento | 76% | ≥ 92% | **100%** | simulação 4.000 lutas |
| B2 | Vitória na Arena Livre, nível 10, sem comprar equipamento | 7% | ≥ 68% | **89%** | idem |
| B3 | Vitória na Arena Livre, nível 15, sem comprar | 0% | ≥ 55% | **89%** | idem |
| B4 | Vitória com equipamento do próprio nível, níveis 1→15 | 89% → 59% | ≥ 88% → ≥ 70% | **100% → 100%** | idem |
| B5 | Tier do inimigo nos níveis 1 e 2 | tier 3 em 14% | sempre tier 1 | **100% tier 1** (vida máxima 45, era 106) | 2.000 gerações |
| B6 | Derrota na 1ª luta de um personagem novo (com loja inicial) | 13,5% | ≤ 5% | **0,0%** | 4.000 simulações |
| B7 | Torneio **Menor** concluído no nível 5, jogador equipado | 0% | ≥ 60% | **78%** | 600 simulações |
| B8 | Torneio **Maior** concluído no nível 8, jogador equipado | 0% | ≥ 50% | **61%** | idem |
| B9 | **Grande Torneio** concluído no nível 12, jogador equipado | 0% | ≥ 50% | **64%** | idem |
| B10 | Escada de dificuldade no nível 5: Menor > Maior ≥ Grande | todos 0% | ordem respeitada | **78% > 12% ≥ 0%** | idem |
| B11 | A curva "golpes para matar" não inverte antes do nível 8 | inverte no nível 4-5 | vantagem do jogador até o nível 8 | **você mata em 4, ele te mata em 6-9** | tabela do simulador |

**Correção de rumo durante a execução (torneio).** A meta original de B7/B8 era "vencível já no nível 1
com 25%" — estava errada: o torneio é o conteúdo de fim de jogo e *não deve* ser vencível no nível 1 (com
jogador equipado, o Menor dá 8% e o Grande 0% no nível 1, e isso é saudável). O que precisa ser verdade é:
(1) cada torneio fecha em algum nível com o jogador equipado (B7-B9 + B10 "não existe torneio impossível"),
e (2) os três formam uma escada de dificuldade de verdade (B10). Medido: Menor fecha no 5, Maior no 8,
Grande no 12 — e nenhum deles passa por acaso. Sem equipamento o torneio fica em 0-3% de propósito: é o
desafio de quem investiu ouro na loja.

**Nota de medição (jogador "equipado").** Os critérios de torneio medem um jogador com os **6 slots**
preenchidos com o melhor item do tipo disponível para o nível (é o que a loja oferece). Medir o torneio com
só 2 peças (arma + peitoral) foi um erro do primeiro modelo e dava 0% em tudo — o torneio exige equipamento
completo, então é com equipamento completo que ele deve ser medido.

Critérios de bug/UX (binários):

| # | Critério |
| --- | --- |
| U1 | Nenhum botão com glifo que a fonte do jogo não desenha. **Medido na renderização de verdade** (a saída do jogo salva em PNG, não a API): os únicos que faltam são 🛒 🛌 👤 — `⚔ ✦ ▸ ● ▌ ▐ → » •` desenham certo. **Atenção:** `Font.has_char()` responde *falso* para `⚔ ▸ ●` também, então essa API não serve para decidir (o fallback do Godot resolve em tempo de render) |
| U2 | "Novo Gladiador" pede confirmação e diz o que será perdido |
| U3 | Nenhum card de item aparece cortado na loja (altura da lista fecha no card) |
| U4 | O nome do item não contradiz o preço/poder (mesmo subtipo → mais poder, nome mais forte) |
| U5 | `README.md` não cita arquivo inexistente nem controle que o jogo não tem |
| U6 | `project.godot` declara a versão real do engine (4.5) — sem reescrita de `.import` a cada abertura |
| U7 | `assets/README.md` descreve a árvore real e o `assets/ATRIBUICOES.md` que ele promete existe (o repo é público: asset sem licença registrada é problema de redistribuição) |

## 1. Balanceamento (arquivos: `scripts/systems/`)

1. **`combat_resolver.gd::generate_enemy()`** — reduzir o escalonamento por nível e travar tier no começo:
   - nível do inimigo: `player_level + randi(-1, 0) + (tier - 1)` (hoje vai até `+tier`, o que permite nível 4 contra nível 1);
   - vida: `24 + level*7 + tier*8` (hoje `28 + level*10 + tier*10` — +10/nível contra +3 de ataque do jogador);
   - ataque: `6 + level*1.6 + tier*2` (hoje `6 + level*2 + tier*2`);
   - **níveis 1 e 2 só geram tier 1** (hoje 14% de tier 3 no nível 1, com até 106 de vida contra 58 do jogador).
2. **`combat_resolver.gd::enemy_for_level()`** (usada pelo torneio) — de `+12 vida/+3 atq/+2 def` por nível
   para `+8/+2/+1`. É esta linha, somada ao `nível + tier×2 + rodada` de `game_state.gd:72`, que fecha o torneio.
3. **`economy_system.gd::level_up_options()`** — Força +3→**+4**, Proteção +3→**+4**, Vigor +12→**+14**, Sorte +2.
   O ganho de nível precisa competir com o escalonamento do inimigo, senão o nível não significa nada.
4. Não mexer em `fight_rewards()` (ouro/XP estão saudáveis: 2,0 a 3,3 lutas por nível) nem nos preços.

Se a simulação não bater as metas, o passo (1) e (2) são ajustados **antes** de olhar para o resto — e o número
final entra em `docs/BALANCEAMENTO.md` com o resultado do playtest.

## 2. Bugs

1. **`README.md` aponta para `docs/PLANO_MVP.md`, que não existe.** Criar o documento (plano de entrega do MVP,
   reconstruído a partir do estado real do repo: marcos entregues, pendências, definição de pronto) e corrigir os
   links. O `ARQUITETURA.md` exige "definição de pronto" por funcionalidade — hoje não há onde consultá-la.
2. **Habilidade de arquétipo: caminho morto e teste com cobertura falsa.** `player_skill()` devolve `{}` sempre
   (`game_state.gd:393`); `data/archetypes.json`, `archetype_id` e `_test_archetypes_content` seguem no repo;
   o README promete "Habilidade: ação especial do arquétipo escolhido" e a arena monta o botão condicionalmente.
   Decisão desta rodada: **não implementar nem apagar** (apagar conteúdo exige OK explícito) — corrigir o README
   para não prometer o que não existe, marcar o ponto de extensão no código e ajustar o teste para afirmar só o que
   é verdade (o conteúdo carrega e o `archetype_id` sobrevive ao save), tirando a falsa sensação de cobertura.
   O que sobra (arquivo, função e botão) vai para a lista de remoção que depende do seu OK, no fim deste plano.
3. **`project.godot` declara `features=4.3`, mas os 28 `.import` versionados são do 4.5** (verificado: importar com
   4.5 não muda um byte; com 4.3/4.4 reescreve os 28 arquivos). Declarar 4.5 e documentar no README, senão todo
   clone-antigo suja o `git status`.
4. **`assets/README.md` descreve uma árvore que não existe** (`art/ audio/ fonts/ ui/`; a real é
   `sprites/arena|effects|enemies|hero|items|ui`). Alinhar o texto.

## 3. UX (não exige decisão de conteúdo)

1. **Glifos ausentes**: `⚔ 🛒 🛌 👤` (`city_screen.gd:60,69,70,73`) não renderizam na fonte padrão — aparecem
   quadradinhos na tela da cidade. Substituir por marcadores ASCII que existem na fonte.
2. **`✦ NOVO GLADIADOR` apaga o save no primeiro clique** (`city_screen.gd:74`). Adicionar diálogo de confirmação
   dizendo nível/ouro que serão perdidos (mesmo padrão do diálogo de descanso, que já existe na tela).
3. **Lista da loja corta o terceiro card** (`shop_screen.gd`): a área de lista tem altura fixa e o card não cabe
   inteiro. Fechar a altura em múltiplo do card e/ou garantir a barra de rolagem visível.
4. **Nome do item contradiz o preço**: na loja do nível 1, "Espada longa" custa 30 e dá ATQ +2, e "Espada curta"
   custa 40 e dá ATQ +3. Os substantivos são embaralhados e o bônus leva `randi(-1,1)`
   (`item_generator.gd:67-68,112-118`), então o nome não informa nada. Ordenar os substantivos pelo poder final
   do item (mais forte → substantivo mais forte do tipo), mantendo o embaralhamento interno por raridade.
5. **Falta ler quanto falta para o próximo nível**: a tela de personagem mostra o ouro e os atributos, mas não o XP
   restante. Adicionar uma linha "X / Y XP para o nível N+1".

## 4. Verificação (o que precisa rodar antes do PR)

1. `godot --headless --path . -s res://tests/run_systems_test.gd` → **PASS** (regras).
2. `godot --headless --path . -s res://tests/run_balance_test.gd` → **PASS** com os critérios B1-B9 como asserção.
3. `xvfb-run … godot --path . res://tests/flow_smoke.tscn` → **PASS** (fluxo, agora com os textos novos).
4. `xvfb-run … godot --path . res://tests/qa_playthrough.tscn` → joga de verdade e fotografa as 18 telas;
   conferir no olho: emojis, diálogo de confirmação, lista da loja, nomes dos itens, XP na tela do personagem.
5. `BALANCEAMENTO.md` com a linha 1.5 (mudança, motivo, resultado do playtest preenchido com os números medidos).

## 5. Aguardando OK explícito para remover (não removo sem autorização)

Regra do projeto: nada é apagado sem pedido explícito. Estes itens ficam parados **por sua decisão**:

| Item | Tamanho | Por que está sobrando |
| --- | --- | --- |
| `assets/sprites/arena/arena_ground.jpeg` | 1.035 KB | nenhum código carrega |
| `assets/sprites/arena/arena_wall_left.png` | 207 KB | a arena desenha muralha com glifo de texto, não sprite |
| `assets/sprites/arena/arena_wall_right.png` | 207 KB | byte-idêntico ao left (não é espelhado) |
| `assets/sprites/effects/arena_wall_left.png` | 207 KB | terceira cópia do mesmo arquivo, em pasta que o código não lê |
| `assets/sprites/items/shield.png` | 237 KB | não existe slot de escudo no jogo |
| `assets/sprites/ui/coin.png`, `heart.png` | 218 KB | a UI escreve ouro/vida em texto |
| `scenes/debug.tscn` + `scripts/ui/debug_screen.gd` | — | não referenciados |
| `scripts/ui/arena_screen.gd`: `fill_card`, `make_card`, `hero_card`, `foe_card`, `_on_foe_card_input`, `_make_legend_row` | ~90 linhas | sobras da UI de cards, que a arena nova não usa |
| `data/archetypes.json`, `GladiatorData.archetype_id`, `GameState.player_skill()` e o botão de habilidade | — | arquétipos saíram da criação; decidir entre implementar a habilidade ou apagar |

Total: ~2,1 MB de assets, 1 cena, ~90 linhas. **Só mexo depois do seu OK, item por item ou no pacote.**

## 6. Fora do escopo desta rodada (propostas para depois)

- Implementar a habilidade por arquétipo (exige voltar a escolher arquétipo na criação).
- Segundo inimigo por arena, eventos entre lutas, áudio (não há nenhum som no jogo).
- Exportação (não há `export_presets.cfg`; o `.gitignore` já protege segredos de keystore).
- Ranking de torneio / recompensa parcial progressiva.
