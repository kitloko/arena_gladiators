# Arena dos Gladiadores

Protótipo 2D de combate por turnos inspirado no ritmo dos jogos de arena de gladiadores. Todo o cenário e a interface são montados por GDScript — a cena existe apenas como ponto de entrada.

O plano de entrega está em [`docs/PLANO_MVP.md`](docs/PLANO_MVP.md) e as regras de organização em [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md).

## Como executar sem abrir o editor

Instale o Godot 4 e, no terminal aberto nesta pasta, execute diretamente:

```powershell
godot --path .
```

Se o executável não estiver configurado no sistema, substitua `godot` pelo caminho do `Godot_v4.x-stable_win64.exe`.

Para uma verificação rápida da estrutura sem abrir a janela do jogo:

```powershell
godot --headless --path . --quit
```

## Controles e fluxo

- **Criação**: personagem neutro — nome + distribuição de pontos em Vida/Força/Defesa/Sorte; você ganha 80 de ouro para equipar na loja antes da 1ª luta.
- **Atacar**: dano consistente.
- **Defender**: reduz o ataque inimigo daquela rodada.
- **Golpe arriscado**: mais dano, porém pode falhar.
- **Habilidade**: ação especial do arquétipo escolhido.
- **Avançar / Recuar**: mover na arena — uma ação por turno (ou você se move, ou ataca/defende).
- **Alcance**: armas melee só acertam de perto; armas de longo alcance (ex.: arco curto) erram mais conforme a distância.

O jogo gira em torno da **CIDADE** (hub): lá você **descansa** (pagando ouro proporcional à vida faltante e ao nível — sem ouro suficiente, recupera só o proporcional), luta na **Arena Livre**, se inscreve em **torneios**, vai à **loja** e abre o **Personagem/Bolsa** (status + itens comprados, com troca de equipamento).

A **loja** é **procedural**: escolha a categoria (**ARMAS** — espadas, adagas, machados, lanças, arcos, bestas, arremesso — ou **ARMADURAS** — peitorais, capacetes, luvas, botas, cintos) e veja até **3 itens por tipo**, gerados com **nível, raridade** (Comum→Épico) e bônus aleatórios. O estoque **rerolha de graça ao subir de nível** ou pagando ouro (botão REROLAR).

A **Arena Livre** é o modo principal e **infinito**: lutas em sequência (loja/descanso entre elas); a cada volta a dificuldade sobe. No **Torneio** (níveis Menor, Maior e Grande) — **sem loja nem descanso**, do início ao fim: o prêmio acumula e, se você perder, metade é perdida; **vencer uma luta devolve a vida cheia** para o próximo combate; vencer o **Grande Gladiador** entrega o item único **Gládio do Grande Gladiador**. As lutas acontecem numa arena **finita e visual**: uma trilha mostra a posição de cada lutador (muralhas nas pontas), cada turno é uma ação (atacar/defender/avançar/recuar) e os botões ficam **desabilitados quando a ação é impossível** (ex.: atacar melee longe demais).

O equipamento cobre **6 slots** (arma, armadura, capacete, luvas, botas e cinto), cada peça somando ATQ/DEF/SORTE/VIDA. As armas têm **estilos**: melee de 1 ou 2 mãos (alcance 1–2) e ranged (arco, besta e facas de arremesso — precisão cai com a distância).

O jogo **salva automaticamente** em `user://savegame.json` (Windows: `%APPDATA%\Godot\app_userdata\Arena dos Gladiadores\savegame.json`). Ao abrir o jogo, se existir um save, ele **continua direto na cidade** com o seu gladiador — só aparece a tela de criação quando não há nenhum personagem salvo. O jogo também salva ao fechar a janela e logo após cada luta na Arena Livre, para não perder progresso se você fechar no meio.

## Estrutura

`Main.tscn` carrega o roteador `scripts/ui/app.gd`, que alterna entre as telas em `scenes/` (criação, arena, resultado, loja e fim de campanha) com controladores em `scripts/ui/`. As regras ficam centralizadas: combate e IA do inimigo em `CombatResolver`, economia e opções de nível em `EconomySystem`, persistência em `SaveSystem`, estado e campanha em `GameState`, e conteúdo em `data/*.json` (via `ContentRepository`). A interface não duplica fórmulas de dano, preço ou recompensa.
