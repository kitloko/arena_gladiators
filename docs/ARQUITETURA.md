# Arquitetura do projeto

## Regra principal

**Cenas mostram informação; sistemas aplicam regras; modelos guardam dados.** Uma mudança em combate não deve exigir alterar botões, e uma mudança visual não deve mudar dano ou progressão.

| Local | Responsabilidade |
| --- | --- |
| `scenes/` | Telas reutilizáveis: menu, arena, loja e resultado. |
| `scripts/ui/` | Controladores e componentes visuais criados por código. |
| `scripts/systems/` | Regras isoladas: combate, economia, progressão e salvamento. |
| `scripts/models/` | Estruturas de dados tipadas, como gladiador e item. |
| `scripts/repositories/` | Carrega conteúdo de `data/`; não contém regras do jogo. |
| `scripts/autoload/` | Estado da campanha que precisa sobreviver entre telas. |
| `data/` | Conteúdo balanceável em JSON: inimigos, itens, habilidades e eventos. |
| `assets/` | Arte, áudio, fontes e animações. |
| `tests/` | Testes automatizados para regras que não dependem da interface. |

## Convenções

- Um arquivo, uma responsabilidade e nomes em `snake_case`.
- Dados de conteúdo não ficam presos na interface.
- Nunca duplicar fórmulas de dano ou preço em telas diferentes.
- Toda alteração de balanceamento registra a versão e o motivo em `docs/BALANCEAMENTO.md`.
- Cada funcionalidade nova deve ter definição de pronto e uma rota de teste manual.
