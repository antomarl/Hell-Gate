# Hell gate — Bounce Back Edition

Gioco stealth in pixel art ambientato all'Haven di Acireale (Hack Club).
Creato in Godot 4.6.3 con GDScript. Nessun addon necessario.
Tema dell’evento: **Bounce Back** — cadere, imparare e tornare più forti.

## Aprire e modificare

1. Installa Godot 4.6 (edizione standard, non serve .NET).
2. Importa `project.godot` dal Project Manager.
3. Premi F6 sulla scena `scenes/main.tscn`, oppure F5 per avviare il progetto.

## Giocare

Completa le quattro fasi del gioco prima della demo. Lo schermo IA aperto
sotto lo sguardo di Richard aumenta il sospetto. A 100% sei scoperto,
ma una sfida Bounce Back ti offre una seconda chance (una in tutte le difficoltà).

- **Spazio, tenuto premuto**: invia il prompt e genera con l'IA.
- **Shift, premuto una volta**: cambia tab (IA / documentazione innocente).
- **1 / 2 / 3**: scegli il fix quando compare un bug; funziona anche il tastierino numerico.
- **Frecce / WASD**: ripeti la sequenza nella sfida di recupero.
- **C**: caffè, -30 sospetto, una volta a partita.
- **E**: distrazione del proiettore per 7 secondi, una volta a partita.
- **Esc / P**: pausa.
- **F11**: schermo intero.
- Mouse/touch: pulsanti sullo schermo. Mantieni premuto GENERA.

Menu con guida, opzioni e tre difficoltà. Record e impostazioni
sono salvati localmente in `user://hellgate.cfg`. Il livello Incubo richiede
una buona gestione della copertura e della distrazione.

## Bounce Back: le nuove regole

- **Checkpoint ogni 25%**: i rollback non cancellano mai una fase completata.
- **Quattro bug di fase**, selezionati da otto problemi. La generazione si blocca:
  leggi il problema e scegli uno dei tre fix mentre Richard continua la pattuglia.
- **Fix giusto**: -20 calore e generazione x1,5 per 6 secondi. Un errore costa
  5 secondi e aggiunge 8 sospetto. Puoi riprovare, ma il tempo conta.
- **Calore**: generare senza pause scalda il portatile. Smettere di generare lo
  raffredda, nascondere la chat ancora più velocemente. A 100% il crash causa
  rollback fino a 7%, -6 secondi, +12 sospetto e un nuovo bug da risolvere.
- **Recupero dopo la scoperta**: ripeti 5 frecce in 11 secondi (6 in 8 secondi
  in Incubo). Il timer della demo continua. Una freccia errata costa 1,5 secondi
  e un passo indietro; tre errori o il timer esaurito finiscono la partita.
- **Recupero riuscito**: rollback fino a 8%, -5 secondi, sospetto a 15, schermo
  nascosto, calore a 20, Richard distratto per 4 secondi e boost x1,5 per 10 secondi.
  La seconda chance è consumata quando la sfida comincia, anche se fallisci.
- **Difficoltà**: Tranquillo 200 s / 1 chance; Hackathon 175 s / 1 chance;
  Incubo 145 s / 1 chance. In Incubo il PC scalda più in fretta.

La chat IA è una simulazione interna al gioco: non usa API, account o rete.
Lo sguardo di Richard è rappresentato dall'alone. Quando appare ! hai un breve
preavviso (0,8 secondi, 0,6 in Incubo) prima che il sospetto aumenti.
L'organizzatore si muove tra mete casuali nel corridoio, con soste, ispezioni,
velocità e dialoghi variabili. Dopo un'ispezione torna verso il fondo dell'aula.

## File principali

- `scripts/main.gd`: interfaccia, menu, pixel art animata e suoni sintetizzati.
- `scripts/game_model.gd`: regole, progressione, chat IA e abilità.
- `scripts/patrol.gd`: pattuglia casuale e campo visivo.
- `scripts/dialogue.gd`: battute contestuali.
- `scripts/bugs.gd`: problemi di debug e risposte.
- Il menu usa la stessa aula in pixel art della partita.

## Export

Installa i template di export Godot 4.6.3 dal menu Editor.
I preset Web (senza thread, WebGL 2) e Linux x86_64 sono già configurati.

```sh
godot --headless --path . --export-release Web ../hell-gate-builds/web/index.html
godot --headless --path . --export-release Linux ../hell-gate-builds/linux/hell-gate.x86_64
```

Per host con limiti alle dimensioni dei singoli file, dopo l’export:

```sh
python3 tools/package_web.py ../hell-gate-builds/web
```

Il loader ricompone in streaming i byte originali del motore da file più piccoli.

La build Web va servita tramite HTTP(S); non si avvia aprendo il file HTML
con doppio click. La build Linux è autonoma: non richiede Godot installato.

## Verifiche

```sh
godot --headless --path . --script res://tests/test_game.gd
godot --headless --path . --script res://tests/test_ui.gd
```

Verifica 90 partite con 30 semi per ciascuna delle tre difficoltà, esiti,
pattuglie diverse e limitate al corridoio, copertura, abilità monouso e timer.
Include anche fix corretti ed errati, checkpoint, calore, recovery riusciti,
errori e timeout, pause durante il recupero e pulsanti del nuovo HUD.

Licenze di motore e font incluse nella cartella assets.

Test Incubo: `godot --headless --path . --script res://tests/test_nightmare.gd`.
Simula 300 semi con decisioni ogni 300 ms e lettura del bug di 2 secondi.
