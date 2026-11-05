# Project context

zPAM Plus is the competition mod of the OpenCoD2-Plus family:

| Member | Repository | Role |
|---|---|---|
| OpenCoD2-Plus Server | `JotaJazz/OpenCoD2-Plus-Server` | dedicated server; `make PLUS=1` is the Plus build |
| OpenCoD2-Plus | `opencod2-plus` | the client ("1.3 Plus") |
| zPAM Plus | `JotaJazz/zpam-plus` | this mod |

Base: zPAM 3.38, a fork of eyza-cod2/zpam3, kept fully compatible with its rules
and match flow.

## Goals

- Run competitions on our own servers and on public Plus servers.
- Later: feed an automatic ladder (results out of the server, no admin by hand).

## Non-goals

- Running on stock 1.0/1.3, CoD2x or the non-Plus builds of the server: zPAM
  3.38 already covers them.

## Anti-goals

- A match that plays differently from zPAM rules without saying so.
- Trusting a client's claim to be Plus.
