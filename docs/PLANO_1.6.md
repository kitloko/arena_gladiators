# Plano 1.6 — feedback do playtest (Bruno, 06/10/2026)

Referência de produto: **Swords and Sandals** (RPG de gladiador: distribuir atributos, lutar na arena,
loja, torneio, equipamento). Cada item abaixo tem causa medida no código e critério de aceite verificável.

## 1. XP sobe rápido demais (sobe de nível por luta) — BUG de balanceamento

**Medido:** XP por luta = `(18 + nível*7) × multiplicador do inimigo (1,0–2,4) × multiplicador da sequência
(1,0–2,8)`; o nível exige `50 + (nível−1)*25`. No nível 1 com 5 vitórias seguidas: 25 × 1,5 × 1,6 = **60 XP
para 50 exigidos** → sobe **toda luta**. A sequência de vitórias foi feita para multiplicar **ouro**, e está
multiplicando XP também.

**Correção:** a sequência passa a valer **só ouro**; o inimigo de tier maior dá um bônus de XP pequeno
(1,0 / 1,15 / 1,3). Nova curva: `XP = 12 + nível*8` e `exigido = 60 + (nível−1)*40`.

**Aceite B12:** lutas por nível entre **3,0** (nível 1) e **5,0** (nível 15), sem luta que sozinha dê nível
(fora do torneio, que é exceção declarada). Medido por `tests/run_balance_test.gd`.

## 2. Entrar no torneio não enche a vida — BUG

**Medido:** `GameState.start_tournament()` não cura ninguém; quem entra machucado luta a primeira rodada em
desvantagem, enquanto as rodadas seguintes curam (`_on_tournament_victory` chama `heal_full`).

**Aceite B13:** ao iniciar um torneio a vida vai a `max_health`.

## 3. Ganhar o torneio não mostra os itens ganhos — BUG

**Medido:** o campeão recebe `gladius_magnus` via `_grant_unique_item()` — que **equipa direto** — e a tela só
escreve "O Gládio do Grande Gladiador é seu", sem ficha (nome, raridade, nível, bônus). As rodadas
intermediárias dão apenas ouro + XP: **nenhum item**.

**Correção:** (a) cada rodada vencida também dá **um item** (procedural, raridade pelo tier); (b) o item entra
na **bolsa** (não equipado à força); (c) a tela de resultado mostra a **ficha** do item ganho (nome, raridade,
nível e bônus) e o ouro.

**Aceite B14:** vencer uma rodada de torneio adiciona ≥ 1 item à bolsa e o resultado exibe a ficha do item.

## 4. Vender itens da bolsa — FEATURE

**Medido:** não existe preço de venda nem caminho de venda (`EconomySystem` só tem recompensa, descanso e reroll).

**Correção:** venda por **40%** do preço (arredondado), botão em cada item da bolsa mostrando o valor
("VENDER — 18 ouro"), item equipado não aparece na bolsa (precisa desequipar antes) e o item único de torneio
tem o botão desabilitado com o motivo escrito.

**Aceite B15:** vender credita o valor, remove o item da bolsa e o `owned_item_ids`; vender 3 itens comprados
e reequipar o conjunto continua possível.

## 5. UI de personagem e bolsa + drag and drop — FEATURE

**Medido:** a bolsa é texto puro ("Bolsa vazia"), sem ações; o quadro de atributos cortava a linha de XP (já
corrigido em 1.5). Não há arrastar: `GladiatorData` tem `equip_item()` mas **não tem `unequip()`**.

**Correção:** tela em duas colunas — equipamento (6 slots) à esquerda, bolsa à direita com ficha por item e
botões **EQUIPAR** e **VENDER**; **arrastar** item da bolsa para o slot equipa (só aceita o slot certo),
arrastar do slot para a bolsa desequipa; barra de XP visível; mensagem dizendo o que aconteceu.

**Aceite B16:** arrastar espada para o slot ARMA equipa e atualiza os atributos; arrastar do slot ARMA para a
bolsa desequipa; slot errado recusa o drop. Verificado no QA visual (screenshot do antes/depois).

## 6. Mais atributos para distribuir — FEATURE

**Medido:** criação dá **12 pontos** para 4 atributos (Vida 46+6/pt, Força 8+1/pt, Defesa 3+1/pt, Sorte 5+1/pt).

**Correção:** 12 → **20 pontos** e a tela mostra "pontos restantes" em destaque.

**Aceite B17:** criação distribui 20 pontos; a curva de balanceamento segue dentro das metas com o build novo
(o simulador passa a usar 20 pontos).

## 7. Ideias novas (Swords and Sandals) — PROPOSTA, não implementar sem OK

Ordem sugerida (por impacto no jogo, não por esforço):

1. **Pontos de atributo no nível em vez de menu fixo.** Hoje subir de nível escolhe entre 4 opções prontas
   (+4 ATQ / +4 DEF / +14 VIDA / +2 SORTE). No S&S você recebe pontos e distribui. Casa com o item 6 e dá
   identidade ao personagem. *(médio)*
2. **Ferimentos depois da derrota.** Perder deixa sequela (ex.: −1 de Força até pagar o médico) — dá peso à
   derrota, que hoje só custa 25% do ouro e cura de graça. *(médio)*
3. **Títulos e fama.** Sequência de vitórias e torneios vencidos viram título ("Novato", "Veterano",
   "Campeão do Grande Torneio"), mostrado na arena e na cidade — progressão visível. *(pequeno)*
4. **Mercado negro / pechinchar na loja.** Barra de pechincha (a Sorte ajuda) para desconto ou briga com o
   vendedor; item pode ficar mais caro por um tempo. *(médio)*
5. **Bets: apostar em si mesmo.** Antes da luta, apostar ouro no próprio combate com odds pelo tier do
   inimigo; perder a aposta soma ao prejuízo. *(pequeno/médio)*
6. **Poções e itens de uso em combate.** Slot de consumível na arena (cura, força temporária) —
   primeira coisa que o combate ganha além de golpe/movimento. *(médio)*
7. **Combate: golpe forte / defesa firme com custo.** Hoje o combate é troca de golpes com posicionamento;
   um "ataque pesado" (dano alto, acerta menos) e "defesa firme" (reduz dano, não ataca) dão decisão real
   por turno. *(médio)*
8. **Inimigos com identidade.** Templates nomeados com fraqueza/resistência (armadura pesada → lento; ágil →
   esquiva) em vez de só escala numérica. *(médio)*
9. **Cidades/arenas diferentes.** Arena Livre com cenários por faixa de nível, cada um com tabela de
   recompensa própria — a S&S tem várias cidades. *(grande)*
10. **Mascates/serviços:** médico (cura barata), ferreiro (melhora item +1), treinador (XP pago). *(médio)*

## 8. Fora de escopo (não pedido, não mexo)

Remoção dos arquivos mortos de `PLANO_CORRECOES.md` §5 continua esperando OK item por item.

## 9. Resultado medido (implementado e verificado — 06/10/2026)

Tudo abaixo foi aplicado **direto na `main`** (exceção combinada para este repositório) e medido com o jogo rodando.

| Item | Estado | Evidência |
| --- | --- | --- |
| 1. XP | **Corrigido** | `run_systems_test.gd`: nível 1 dá 20 XP para 60 exigidos (nível 15: 132 para 620) — **nenhuma luta sozinha dá nível**, em nenhum nível; 3,0 a 4,7 lutas por nível. `flow_smoke.tscn` com **11 vitórias seguidas**: a luta deu 20 XP (igual à primeira) e o ouro subiu de 24 para 57 — a sequência só mexe no ouro |
| 2. Vida no torneio | **Corrigido** | QA com o jogo aberto: `VIDA NA ENTRADA DO TORNEIO: 19 -> 77 de 77 => OK (encheu)` |
| 3. Prêmio do torneio | **Corrigido** | QA: `PRÊMIO DE ITEM NA TELA DE RESULTADO: 1 ficha(s) de item | bolsa: 1 item(ns)`; screenshot `16_resultado_torneio.png` com a ficha (nome, raridade, nível, bônus). `flow_smoke.tscn`: rodada vencida adiciona 1 item; a rodada final entrega os 2 (item da rodada + item único) e o **Gládio vai para a bolsa** em vez de ser equipado à força |
| 4. Vender da bolsa | **Implementado** | `flow_smoke.tscn`: vender credita 40% do preço e o item sai da bolsa; item **equipado** é recusado; item **único** é recusado com motivo. QA: botão `VENDER (12)` para um item de 30 de ouro |
| 5. UI + arrastar-e-soltar | **Implementado** | `flow_smoke.tscn`: 6 slots desenhados (`equipslot_*`), uma linha por item da bolsa (`bagrow_*`) e os painéis implementam `_get_drag_data`. QA visual: `07_personagem_bolsa.png` (tela vazia), `19_personagem_bolsa_com_itens.png` (com item, preço e botões) |
| 6. Mais atributos | **Feito** | Criação com **20 pontos** (vida 76, ATQ 20, DEF 6 no build de teste); `run_balance_test.gd` remedido com o build novo: **PASS** |
| 7. Ideias novas | **Proposta** (sem OK) | Lista na seção 7 — nada implementado sem autorização |

### Observações honestas

- **A Arena Livre ficou mais fácil**: 100% → 98–99% (sem loja) contra 100% → 88–90% na 1.5, porque os 20 pontos de criação deixaram o jogador mais forte. As metas (piso de 55% no nível 15) seguem cumpridas com folga; se você quiser o desafio de volta, o caminho é subir um pouco o ataque do inimigo a partir do nível 8 (+1 a cada 3 níveis) — **não mexi por conta própria**, já que não foi pedido.
- **A criação exige distribuir todos os pontos** para liberar o botão (comportamento que já existia com 12 pontos; agora são 20). Se preferir permitir confirmar com pontos sobrando, é uma linha.
- **Torneio é exceção declarada** na regra "nenhuma luta dá um nível": as rodadas valem o multiplicador do torneio (1,0 / 1,6 / 2,4) e o prêmio é justamente o que se busca lá.
- **Item da bolsa tem id único** (sufixo aleatório na geração), então dois itens iguais do mesmo tipo convivem na bolsa — nenhum se funde com o outro.
