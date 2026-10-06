# Arena dos Gladiadores

Protótipo 2D de combate por turnos inspirado no ritmo dos jogos de arena de gladiadores. Todo o cenário e a interface são montados por GDScript — a cena existe apenas como ponto de entrada.

O plano de entrega está em [`docs/PLANO_MVP.md`](docs/PLANO_MVP.md), as regras de organização em [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md). O histórico de números do balanceamento fica em [`docs/BALANCEAMENTO.md`](docs/BALANCEAMENTO.md), o plano de correções da versão 1.5 (com os critérios numéricos medidos) em [`docs/PLANO_CORRECOES.md`](docs/PLANO_CORRECOES.md), o plano da versão 1.6 (feedback de playtest: XP, prêmio do torneio, venda de itens, arrastar-e-soltar) em [`docs/PLANO_1.6.md`](docs/PLANO_1.6.md), a **especificação aprovada das etapas em andamento** (7 atributos, armadura, ações nomeadas, público, rank) em [`docs/PLANO_2.0.md`](docs/PLANO_2.0.md) e as ideias ainda não implementadas em [`docs/IDEIAS.md`](docs/IDEIAS.md).

Feito e testado no **Godot 4.5** (`config/features` do `project.godot`). Versões 4.3/4.4 reescrevem os arquivos `.import` dos assets — se isso acontecer, `git checkout -- .` desfaz.

## Como executar sem abrir o editor

Instale o Godot 4.5 e, no terminal aberto nesta pasta, execute diretamente:

```powershell
godot --path .
```

Se o executável não estiver configurado no sistema, substitua `godot` pelo caminho do `Godot_v4.5-stable_win64.exe`.

## Testes

Os testes de regras e de balanceamento rodam sem abrir janela (nenhum precisa de tela) e saem com código 1 se algo falhar:

```powershell
# regras: combate, itens, loja, progressão, save, XP e venda (deve dizer PASS)
godot --headless --path . -s res://tests/run_systems_test.gd

# balanceamento: curva de vitória por nível e torneios (deve dizer PASS)
godot --headless --path . -s res://tests/run_balance_test.gd
```

O teste de fluxo abre o jogo de verdade (precisa de tela) e clica pelas telas — criação, loja, cidade, personagem/bolsa, luta, resultado, torneio, save:

```powershell
godot --path . res://tests/flow_smoke.tscn
```

Para uma verificação rápida da estrutura sem abrir a janela do jogo:

```powershell
godot --headless --path . --quit
```

## Controles e fluxo

- **Criação**: personagem neutro — nome + distribuição de **20 pontos** entre os **7 atributos** (o botão de confirmar libera quando todos os pontos são distribuídos); você ganha 80 de ouro para equipar na loja antes da 1ª luta.
- **Os 7 atributos**: **STR** (dano corpo a corpo e força do Taunt) · **ATT** (precisão) · **DEF** (chance de **defender** — parte do dano é bloqueada) · **AGI** (chance de **esquivar** — dano zero) · **VIT** (vida máxima, `10 + VIT×6`) · **CHA** (preço na loja, felicidade do público, exibição) · **SOR** (acerto crítico, resistência a efeitos aleatórios e pechincha).
- **GOLPE / GOLPE FORTE / INVESTIDA** (corpo a corpo) e **TIRO / TIRO CERTEIRO / BOMBARDEIO** (à distância): ataques nomeados, com dano e precisão diferentes — GOLPE FORTE bate mais e acerta menos. O botão fica **desabilitado quando a ação é impossível** (ex.: golpe corpo a corpo longe demais).
- **DEFESA FIRME**: você não ataca e o dano que entra na rodada é reduzido.
- **TAUNT: (x%)**: provoca o adversário, que sofre um **efeito aleatório** — o mais comum é ser **empurrado um passo à frente**; se não puder avançar, ele te ataca com **precisão baixa**. A chance sai de **CHA** (+ STR) contra a DEF/SOR do alvo e a **SORTE do alvo resiste** ao empurrão.
- **DORMIR**: cura **25%** da vida máxima, mas deixa você **vulnerável** no golpe seguinte (o inimigo acerta com bônus e a sua esquiva não vale). Serve como risco calculado — quem só dorme não vence.
- **Armadura**: os itens de proteção dão **armadura**, que é uma **reserva separada da vida** — o dano consome armadura antes de encostar na vida. A luta mostra as **duas barras com números** (`VIDA x / y` e `ARMADURA x / y`); o descanso restaura as duas.
- **Resolução do ataque**: primeiro a **esquiva** do alvo (AGI) — se esquivar aparece **"ERROU"**; depois a **auto-defesa** (DEF) — se defender, aparece **"aparou X, entrou Y"** com sinalização visual; senão o dano entra cheio. Quem **apara** pode **REVIDAR** (50% de chance, contra-ataque com 60% do valor aparado).
- **Público da arena**: barra no **topo da tela de luta**, de 0 a 100%, começando conforme o **carisma** dos dois lutadores (luta contra **chefe** já começa em pelo menos 60%). A cada ação o log mostra a variação — acerto **+2**, crítico **+6**, revidar **+5**, levar golpe **+3**, drama (vida < 30% atacando) **+4**, errar **−5**, defender **−3**, recuar **−6**, dormir **−4**, rodada fria **−2**. A felicidade final **multiplica a recompensa** de **×1,0 a ×2,0** — mas **luta definida em até 3 ações não multiplica** ("o público nem viu a luta"), e a tela de resultado mostra a linha `Público: X% → recompensa ×N`.
- **EXIBIR**: gasta o turno para inflamar a plateia (**+8**), mas rende **cada vez menos** na mesma luta (+8 → +4 → +2 → **−5**) e deixa você **aberto** (o inimigo ganha +25% de precisão e a sua esquiva não vale no turno).
- **Subir de nível dá PONTOS de atributo** (4 por nível) para distribuir entre os 7 na tela do **Personagem** — o antigo menu de 4 pacotes prontos deixou de existir.
- **Avançar / Recuar**: mover na arena — uma ação por turno (ou você se move, ou ataca/defende).
- **Alcance**: armas melee só acertam de perto; armas de longo alcance (ex.: arco curto) erram mais conforme a distância.

O jogo gira em torno da **CIDADE** — agora um **cenário** com os locais clicáveis sobre ele (Arena Livre, os três torneios, Loja, Descansar, **Médico**, **Ferreiro**, **Treinador**, Personagem/Bolsa e Novo Gladiador) e o **HUD do personagem** no canto (nome, nível, **RANK**, vida, armadura, ouro e **KD**). Lá você **descansa** (pagando ouro proporcional à vida **e à armadura** faltantes — sem ouro suficiente, recupera só o proporcional), luta na **Arena Livre**, se inscreve em **torneios**, vai à **loja** e abre o **Personagem/Bolsa**.

**RANK e KD** (separado do nível): cada luta **soma ou tira pontos de rank** conforme a força do adversário — vencer alguém mais forte rende muito, vencer muito mais fraco rende **zero** (bater na arena fraca satura e **não** leva ao topo), e perder para alguém de rank menor dói mais. As faixas dão **título**: Areia · Pedra · Ferro · Aço · Prata · Ouro · Campeão · Lenda, com **rebaixa** se você cair do piso. O **rank é requisito de acesso**: Arena Livre é aberta, **Torneio Menor exige Pedra**, **Maior exige Aço** e **Grande exige Ouro** — na cidade o destino aparece **trancado com o motivo** (*"Precisa de rank Aço — você está em Ferro"*). E rank maior significa **casa mais cheia**: sobe a felicidade inicial do público e o teto do multiplicador.

**Apresentação antes da luta:** toda luta (Arena Livre e cada rodada de torneio) começa numa tela de **apresentação** — os dois lutadores frente a frente com **nome, apelido e descrição**, o inimigo declarando a própria **fraqueza**, um **VS** no meio com o **Índice de Poder** dos dois, os **7 atributos + VIDA MÁX + ARMADURA + RANK/KD** comparados em duas colunas, a **provocação sorteada** de cada lado e o botão **ENTRAR NA ARENA**. Nada acontece antes de você clicar.

**Índice de Poder:** `round(STR×2,0 + ATT×1,5 + DEF×1,5 + AGI×1,5 + VIT×1,0 + CAR×0,5 + SOR×1,0 + NÍVEL×5,0)` — aparece na **apresentação** para os **dois** lados, para você comparar de relance quem leva vantagem (a tela de luta não mostra o índice).

**Inimigos com identidade (a fraqueza morde):** cada inimigo de torneio tem um **traço** que muda o combate de verdade e o texto da apresentação **descreve exatamente esse efeito** — **Frágil** (+25% de dano de golpe pesado), **Lento** (−0,15 de esquiva e −10% de precisão), **Ágil** (+0,10 de esquiva), **Couraçado** (−20% de dano corpo a corpo, −0,10 de esquiva), **Vidro** (+15% de dano recebido e +10% causado) e **Fera** (+10% de dano causado). Quando o traço morde, a **luta escreve no log** (ex.: *"Frágil: +25% de dano"*, *"Lento: não conseguiu esquivar"*). O traço também entra no **Índice de Poder** (de −8 a +8) e na **odd da aposta** — assim a apresentação não mente sobre a dificuldade.

**Ferimentos** (consequência de perder): perder uma luta tem **75% de chance** (90% se você levou crítico) de deixar uma **sequela** — Braço quebrado (−3 STR), Costela rachada (−4 VIT) e outros 5 modelos. O ferimento **conta de verdade** no próximo combate e **não sara sozinho**: descansar recupera vida, mas a sequela **só sai no médico** (ou com a poção de cura de ferimento). No máximo **2 ativos** ao mesmo tempo e nenhum deles zera um atributo.

**Pechincha** (na loja): botão **PECHINCHAR (x%)** antes de comprar — a chance vem de **CAR e SOR** (CAR 5 ≈ 49%, CAR 40 ≈ 91%) e o desconto vai até **35%** (média medida: 3,7% com CAR 5, **31,9%** com CAR 40). Cada item só pode ser pechinchado **uma vez**, e **falhar trava** aquele item.

**Apostas** (na apresentação, antes de entrar): aposte ouro no **seu próprio combate**. A odd sai do **Índice de Poder** dos dois (`clamp(0,9/prob, 1,05, 2,00)`) e o teto é `min(ouro, 20 + 8×nível)`. Ganhou, recebe aposta × odd; perdeu, perdeu a aposta. O valor esperado é **sempre negativo** — apostar é emoção, não plano de negócios.

**Poções** (compradas na aba **POÇÕES** da loja): cura **40 de vida** (30 ouro), **30 de armadura** (30), **+6 STR/AGI por 3 turnos** (45) e **cura 1 ferimento** (90). Usar **gasta o turno** e **consome o item**; não dá para usar fora da luta. Cabem até **5** na mochila.

**Serviços da cidade** (três locais novos no cenário):
- **» MÉDICO** — cura vida, armadura e **todos** os ferimentos por ouro (curar 1 ferimento: 25 no nível 1, 95 no nível 15).
- **» FERREIRO** — **melhora a armadura de uma peça**: +1 de proteção por melhoria, **máximo 5 por peça**, com o preço subindo a cada melhoria (peça de nível 1: 31/49/67/85/103).
- **» TREINADOR** — compra **XP** por ouro (`+8 + 4×nível` de XP por `25 + 10×nível`), mas com **teto de 35% do XP do nível** — não dá para comprar o nível inteiro.

**Personagem e bolsa** (tela em duas colunas): à esquerda os **6 slots de equipamento**, à direita a **bolsa** com uma ficha por item (raridade, nível, bônus e **preço de venda** = 40% do preço de compra) e os botões **EQUIPAR** e **VENDER**. Dá para fazer o mesmo **arrastando**: item da bolsa → slot dele equipa; item do slot → bolsa desequipa (soltar em qualquer lugar da bolsa). O slot só aceita o tipo certo (arma na arma etc.) e o item **equipado não pode ser vendido** — desequipe primeiro. O **Gládio do Grande Gladiador** é único de torneio e aparece como **NÃO VENDÁVEL**. A tela mostra ainda a **barra de XP** até o próximo nível.

A **loja** é **procedural**: escolha a categoria (**ARMAS** — espadas, adagas, machados, lanças, arcos, bestas, arremesso — ou **ARMADURAS** — peitorais, capacetes, luvas, botas, cintos) e veja até **3 itens por tipo**, gerados com **nível, raridade** (Comum→Épico) e bônus aleatórios. O estoque **rerolha de graça ao subir de nível** ou pagando ouro (botão REROLAR).

A **Arena Livre** é o modo principal e **infinito**: lutas em sequência (loja/descanso entre elas); a cada volta a dificuldade sobe. A **sequência de vitórias** aumenta só o **ouro** (+12% por vitória seguida, até +180%) — o **XP não é multiplicado pela sequência** (era o que fazia o personagem subir de nível a cada luta). No **Torneio** (níveis Menor, Maior e Grande) — **sem loja nem descanso** — entrar **enche a vida**, cada rodada vencida dá **um item** (que vai para a bolsa e aparece na ficha da tela de resultado) e o prêmio acumula; se você perder, metade é perdida; vencer o **Grande Gladiador** entrega o item único **Gládio do Grande Gladiador**. As lutas acontecem numa arena **finita e visual**: uma trilha mostra a posição de cada lutador (muralhas nas pontas), cada turno é uma ação (atacar/defender/avançar/recuar) e os botões ficam **desabilitados quando a ação é impossível** (ex.: atacar melee longe demais).

O equipamento cobre **6 slots** (arma, armadura, capacete, luvas, botas e cinto), cada peça somando ATQ/DEF/SORTE/VIDA. As armas têm **estilos**: melee de 1 ou 2 mãos (alcance 1–2) e ranged (arco, besta e facas de arremesso — precisão cai com a distância).

O jogo **salva automaticamente** em `user://savegame.json` (Windows: `%APPDATA%\Godot\app_userdata\Arena dos Gladiadores\savegame.json`). Ao abrir o jogo, se existir um save, ele **continua direto na cidade** com o seu gladiador — só aparece a tela de criação quando não há nenhum personagem salvo. O jogo também salva ao fechar a janela e logo após cada luta na Arena Livre, para não perder progresso se você fechar no meio.

## Estrutura

`Main.tscn` carrega o roteador `scripts/ui/app.gd`, que alterna entre as telas em `scenes/` (criação, arena, resultado, loja e fim de campanha) com controladores em `scripts/ui/`. As regras ficam centralizadas: combate e IA do inimigo em `CombatResolver` (agora com 7 atributos, armadura como reserva, esquiva/auto-defesa, Taunt e Dormir), economia e atributos em `EconomySystem`, persistência em `SaveSystem`, estado e campanha em `GameState`, e conteúdo em `data/*.json` (via `ContentRepository`). A interface não duplica fórmulas de dano, preço ou recompensa.
