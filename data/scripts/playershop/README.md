# Player Shop (Priston Tale style) — Realera TFS 1.5 / 8.0

Sistema de loja de jogador onde players ficam parados em PZ vendendo itens do
inventário. Outros players clicam neles e compram via janela customizada.

## Instalação

### Server
1. Os arquivos em `data/scripts/playershop/` são auto-carregados (revscripts).
2. Reinicie o server (não basta `/reload`).
3. Verifique no boot log que cada arquivo carregou sem erro.

### Cliente (otclientv80)
1. Copiar a pasta `modules/game_playershop/` para o cliente do jogador.
2. Reinicie o cliente.
3. Botão "Criar Loja" aparece na barra superior à direita.

## Uso

### Como vendedor
1. Vá pra **PZ** (zona protegida), sem battle, sem skull red/black.
2. Clique no botão **Criar Loja** (ícone do shop) na top bar.
3. Preencha texto da loja, clique em cada slot pra escolher item do inventário,
   defina preço por unidade.
4. Clique **Iniciar Venda**.
5. Você fica **parado** (não pode mover, deslogar, mover/dropar itens da loja).
6. Pra fechar manualmente: digite `!fecharloja`.

### Como comprador
1. Clique no vendedor (com balão de texto e ícone dourado).
2. Janela da loja abre listando itens + preço.
3. Defina quantidade no campo, clique **Comprar**.
4. Gold sai primeiro da BP, completa do banco. Vendedor recebe no banco.

## Comandos

| Comando | Quem | Função |
|---------|------|--------|
| `!fecharloja` | Vendedor | Fecha a própria loja |
| `!lojas` | Todos | Lista lojas ativas no server |
| `/shop list` | GOD | Lista lojas com posição |
| `/shop close <name>` | GOD | Força fechamento da loja de alguém |

## Arquivos

```
Server (TFS 1.5)
data/scripts/playershop/
  ├── 01_config.lua       config + opcode IDs + helpers
  ├── 02_core.lua         open / close / buy (synchronous w/ rollback)
  ├── 03_opcodes.lua      handlers dos 5 opcodes
  ├── 04_events.lua       movement lock, logout block, item-move block, tick
  ├── 05_talkactions.lua  !fecharloja, !lojas, /shop list, /shop close
  └── 06_save_hook.lua    fechar tudo no shutdown + VIP sync no login

Client (otclientv80)
modules/game_playershop/
  ├── game_playershop.otmod  manifest
  ├── playershop.lua          opcodes + bubble + name icon + click intercept + VIP hook
  ├── playershop.otui         ShopBubble + CreateShopWindow + ShopViewWindow
  ├── create_shop.lua         lógica da janela "Criar Loja"
  └── shop_view.lua           lógica da janela do comprador
```

## ExtendedOpcodes

| ID | Nome | Direção | Payload |
|----|------|---------|---------|
| 130 | OPEN | C→S | text(str), n(u8), [uid(u32) id(u16) count(u16) price(u32)]×n |
| 131 | CLOSE | C→S | (vazio) |
| 132 | REQUEST | C→S | sellerCid(u32) |
| 133 | BUY | C→S | sellerCid(u32) slot(u8) qty(u16) |
| 134 | DATA | S→C | sellerId(u32) name(str) text(str) n(u8) [slot(u8) id(u16) count(u16) price(u32) charges(u16) name(str)]×n |
| 135 | STATE_BROADCAST | S→C | cid(u32) isOpen(u8) text(str if open) |
| 136 | VIP_STATUS | S→C | guid(u32) name(str) isOpen(u8) |
| 137 | INVENTORY_LIST | S↔C | (request: vazio; response: n(u16) [uid(u32) id(u16) count(u16) charges(u16) name(str)]×n) |
| 138 | REJECT | S→C | reason(str) |

## Decisões técnicas

- **Não usa `Player:openShopWindow` nativo** — esse método existe só pra Npc no Nekiro 1.5. Adicionar binding C++ requer rebuild; preferimos opcode driven UI.
- **Movimento bloqueado por warp-back tick** (500ms) — TFS 1.5 não tem `onMove` direto pra player; comparamos posição saved vs current e teleportamos de volta.
- **Compras síncronas com rollback** — se `addItem` falhar (cap cheio), gold é devolvido na hora.
- **VIP color/icon** atualiza em tempo real via opcode + cache local no cliente; também sync no login (após 1.5s, dá tempo do client_vip carregar).

## Edge cases tratados

- Vendedor crasha/desconecta → tick detecta `Player()` nulo, fecha shop.
- Comprador entra em battle ou sai da PZ → BUY rejeitado.
- Item já vendido → slot.count=0, slot some, próximo BUY rejeita.
- Cap cheio do comprador → rollback completo do gold.
- Server save → `06_save_hook.lua` fecha todas as lojas no shutdown.
- Tempo limite (8h) → tick detecta e fecha.
- GM teleporta vendedor pra fora da PZ → tick detecta e fecha.

## Limitações conhecidas

- Não persiste em SQL (por design — vendedor reabre manualmente).
- `Item:serializeAttributes` não é exposto em TFS 1.5 Lua; preservamos só
  `charges` e `actionId`. Itens com encantos custom (gems imbued etc) podem
  perder o atributo na transferência.
- Cliente modificado pode tentar enviar payload corrupto; server valida tudo
  e rejeita com REJECT opcode.
