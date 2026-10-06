# Plano de entrega do MVP — Arena dos Gladiadores

> **Nota de reconstrução (v1.5):** este arquivo é citado pelo `README.md` como fonte do plano de entrega, mas nunca
> esteve versionado. Ele foi reconstruído a partir do changelog `docs/BALANCEAMENTO.md` (versões 0.1 a 1.4) e do
> estado real do código, e passa a ser mantido daqui para frente. Onde não havia registro, o campo diz
> `não registrado` em vez de inventar histórico.

## 1. Escopo do MVP

Um jogo single-player de arena por turnos, em Godot 4.5, que rode do início ao fim sem intervenção manual e cumpra:

| Área | O que o MVP precisa ter | Estado em 1.5 |
| --- | --- | --- |
| Criação | Nome + distribuição de pontos (personagem neutro, sem classe) e ouro inicial para equipar | **Entregue** (v1.3) |
| Hub | Cidade como centro: loja, arena livre, torneio, descanso pago, personagem/bolsa | **Entregue** (v1.3) |
| Combate | Turnos posicionais (distância 1-6), alcance por arma, ranged com precisão caindo, defesa, golpe arriscado, botões desabilitados quando a ação é impossível | **Entregue** (v0.7 / v1.1) |
| Progressão | Nível com escolha de treino, 6 slots de equipamento, estatísticas derivadas = base + equipamento | **Entregue** (v0.5 / v0.8) |
| Conteúdo infinito | Arena Livre procedural: inimigo novo a cada luta, tier 1-3, recompensa por tier, sequência de vitórias | **Entregue** (v1.0 / v1.4) |
| Conteúdo finito | Torneios (Menor/Maior/Grande), sem loja/descanso, prêmio acumulado, item único do Grande Gladiador | **Entregue, mas fechado ao jogador** — corrigido em 1.5 |
| Loja | Estoque procedural por categoria/tipo, nível, raridade, reroll (grátis ao subir de nível, pago por ouro) | **Entregue** (v1.3) |
| Persistência | Autosave em `user://savegame.json`, continuar de onde parou, save após cada luta | **Entregue** (v0.6) |
| Habilidade do personagem | "Ação especial do arquétipo" | **Pendente de decisão** — arquétipos saíram da criação; hoje o botão nunca aparece (ver `PLANO_CORRECOES.md` §2.2 e §5) |
| Áudio | Efeitos de golpe/interface | **Pendente** — o jogo não tem nenhum som |
| Distribuição | Exportação para Windows | **Pendente** — não há `export_presets.cfg` (e ele deve seguir fora do repositório) |

## 2. Definição de pronto por área

O `docs/ARQUITETURA.md` exige "cada funcionalidade nova deve ter definição de pronto e uma rota de teste manual".
Para o MVP, vale o seguinte:

1. **Regra nova** → teste em `tests/run_systems_test.gd` (regras puras, sem UI). Sem teste, não entra.
2. **Número novo de balanceamento** → linha em `docs/BALANCEAMENTO.md` com motivo **e** resultado do playtest
   preenchido (o campo não pode ficar "Pendente" na entrega) e asserção em `tests/run_balance_test.gd`.
3. **Tela nova ou alterada** → rota manual em `tests/qa_playthrough.gd` (o harness clica e fotografa) e conferência
   visual das telas geradas.
4. **Conteúdo novo** → JSON em `data/`, consumido só por `scripts/repositories/`; nenhuma fórmula na UI.
5. **Entrega** → os quatro comandos de verificação em `PLANO_CORRECOES.md` §4 verdes.

## 3. Marcos

| Marco | Conteúdo | Estado |
| --- | --- | --- |
| 1 | Criação, primeira luta, resultado, loja | **Concluído** (v0.3 / v0.4) |
| 2 | Progressão, equipamento, economia | **Concluído** (v0.5) |
| 3 | Campanha, derrota/retry, salvamento | **Concluído** (v0.6) |
| 4 | Infraestrutura de testes (regras + smoke de fluxo) | **Concluído** — não registrado no changelog |
| 5 | Combate posicional (distância, alcance, ranged) | **Concluído** (v0.7) |
| 6 | Equipamento por slot, chefes com habilidade, Arena Livre e Torneios | **Concluído** (v0.8 a v1.0) |
| 7 | Loja procedural, sequência de vitórias, descanso pago | **Concluído** (v1.3 / v1.4) |
| 8 | **Balanceamento jogável e torneio vencível + correções de bug/UX** | **Este ciclo** (v1.5) |
| 9 | Habilidade do personagem (decidir: implementar ou retirar de vez) | Pendente de decisão |
| 10 | Áudio, arte final, exportação Windows, polimento de publicação | Pendente |

## 4. Riscos conhecidos

- **Balanceamento é o risco nº 1** e não se vê no `tsc`/suíte: só aparece jogando muitas partidas. Por isso o
  ciclo 1.5 transforma os números em teste (`tests/run_balance_test.gd`) — o balanceamento passa a ser verificável.
- **Economia acoplada à progressão**: hoje o equipamento é a única fonte de escala que acompanha o inimigo.
  Se o ouro secar, o jogo fecha. Depois do ciclo 1.5, medir a taxa de vitória com e sem loja nas duas pontas.
- **`.import` versionados** amarram o repo a uma versão do engine: declarar 4.5 no `project.godot` (feito em 1.5)
  evita reescrita acidental dos 28 arquivos.
- **Repositório público**: se a intenção for publicar o jogo comercialmente, revisar visibilidade e licença dos
  assets antes do lançamento.
