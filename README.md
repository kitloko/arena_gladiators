# Arena dos Gladiadores

Protótipo 2D de combate por turnos inspirado no ritmo dos jogos de arena de gladiadores. Todo o cenário e a interface são montados por GDScript — a cena existe apenas como ponto de entrada.

O plano de entrega está em [`docs/PLANO_MVP.md`](docs/PLANO_MVP.md), as regras de organização em [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md). O histórico de números do balanceamento fica em [`docs/BALANCEAMENTO.md`](docs/BALANCEAMENTO.md), o plano de correções da versão 1.5 (com os critérios numéricos medidos) em [`docs/PLANO_CORRECOES.md`](docs/PLANO_CORRECOES.md), o plano da versão 1.6 (feedback de playtest: XP, prêmio do torneio, venda de itens, arrastar-e-soltar, 20 pontos de criação) em [`docs/PLANO_1.6.md`](docs/PLANO_1.6.md) e as **ideias ainda não implementadas** (atributos no estilo Swords and Sandals, Taunt, Sleep, armadura como reserva, apresentação do adversário, cidade como cenário) em [`docs/IDEIAS.md`](docs/IDEIAS.md).

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

- **Criação**: personagem neutro — nome + distribuição de **20 pontos** em Vida/Força/Defesa/Sorte (o botão de confirmar libera quando todos os pontos são distribuídos); você ganha 80 de ouro para equipar na loja antes da 1ª luta.
- **Atacar**: dano consistente.
- **Defender**: reduz o ataque inimigo daquela rodada.
- **Golpe arriscado**: mais dano, porém pode falhar.
- **Habilidade**: ação especial de arquétipo — **ainda não implementada**. A criação é neutra (sem classe), então nenhum personagem recebe arquétipo e o botão não aparece na arena; `data/archetypes.json` existe como conteúdo para quando a escolha de classe entrar.
- **Avançar / Recuar**: mover na arena — uma ação por turno (ou você se move, ou ataca/defende).
- **Alcance**: armas melee só acertam de perto; armas de longo alcance (ex.: arco curto) erram mais conforme a distância.

O jogo gira em torno da **CIDADE** (hub): lá você **descansa** (pagando ouro proporcional à vida faltante e ao nível — sem ouro suficiente, recupera só o proporcional), luta na **Arena Livre**, se inscreve em **torneios**, vai à **loja** e abre o **Personagem/Bolsa**.

**Personagem e bolsa** (tela em duas colunas): à esquerda os **6 slots de equipamento**, à direita a **bolsa** com uma ficha por item (raridade, nível, bônus e **preço de venda** = 40% do preço de compra) e os botões **EQUIPAR** e **VENDER**. Dá para fazer o mesmo **arrastando**: item da bolsa → slot dele equipa; item do slot → bolsa desequipa (soltar em qualquer lugar da bolsa). O slot só aceita o tipo certo (arma na arma etc.) e o item **equipado não pode ser vendido** — desequipe primeiro. O **Gládio do Grande Gladiador** é único de torneio e aparece como **NÃO VENDÁVEL**. A tela mostra ainda a **barra de XP** até o próximo nível.

A **loja** é **procedural**: escolha a categoria (**ARMAS** — espadas, adagas, machados, lanças, arcos, bestas, arremesso — ou **ARMADURAS** — peitorais, capacetes, luvas, botas, cintos) e veja até **3 itens por tipo**, gerados com **nível, raridade** (Comum→Épico) e bônus aleatórios. O estoque **rerolha de graça ao subir de nível** ou pagando ouro (botão REROLAR).

A **Arena Livre** é o modo principal e **infinito**: lutas em sequência (loja/descanso entre elas); a cada volta a dificuldade sobe. A **sequência de vitórias** aumenta só o **ouro** (+12% por vitória seguida, até +180%) — o **XP não é multiplicado pela sequência** (era o que fazia o personagem subir de nível a cada luta). No **Torneio** (níveis Menor, Maior e Grande) — **sem loja nem descanso** — entrar **enche a vida**, cada rodada vencida dá **um item** (que vai para a bolsa e aparece na ficha da tela de resultado) e o prêmio acumula; se você perder, metade é perdida; vencer o **Grande Gladiador** entrega o item único **Gládio do Grande Gladiador**. As lutas acontecem numa arena **finita e visual**: uma trilha mostra a posição de cada lutador (muralhas nas pontas), cada turno é uma ação (atacar/defender/avançar/recuar) e os botões ficam **desabilitados quando a ação é impossível** (ex.: atacar melee longe demais).

O equipamento cobre **6 slots** (arma, armadura, capacete, luvas, botas e cinto), cada peça somando ATQ/DEF/SORTE/VIDA. As armas têm **estilos**: melee de 1 ou 2 mãos (alcance 1–2) e ranged (arco, besta e facas de arremesso — precisão cai com a distância).

O jogo **salva automaticamente** em `user://savegame.json` (Windows: `%APPDATA%\Godot\app_userdata\Arena dos Gladiadores\savegame.json`). Ao abrir o jogo, se existir um save, ele **continua direto na cidade** com o seu gladiador — só aparece a tela de criação quando não há nenhum personagem salvo. O jogo também salva ao fechar a janela e logo após cada luta na Arena Livre, para não perder progresso se você fechar no meio.

## Estrutura

`Main.tscn` carrega o roteador `scripts/ui/app.gd`, que alterna entre as telas em `scenes/` (criação, arena, resultado, loja e fim de campanha) com controladores em `scripts/ui/`. As regras ficam centralizadas: combate e IA do inimigo em `CombatResolver`, economia e opções de nível em `EconomySystem`, persistência em `SaveSystem`, estado e campanha em `GameState`, e conteúdo em `data/*.json` (via `ContentRepository`). A interface não duplica fórmulas de dano, preço ou recompensa.
