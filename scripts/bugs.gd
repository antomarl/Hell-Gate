class_name BounceBugs
extends RefCounted

const CASES = [
	{"title": "IL SALTO NON RIPARTE", "question": "Dopo una caduta il salto resta bloccato.\nQuale fix fa ripartire il personaggio?", "choices": ["Ripristina il salto quando atterra", "Aumenta il volume dell'audio", "Cancella tutti i checkpoint"], "correct": 0},
	{"title": "RIMBALZO AL CONTRARIO", "question": "La pallina colpisce il pavimento\nma continua a scendere. Cosa cambi?", "choices": ["Il colore dello sfondo", "Inverti la velocità verticale", "Raddoppia il peso del menu"], "correct": 1},
	{"title": "CHECKPOINT DIFETTOSO", "question": "Dopo il KO riparti sempre dall'inizio.\nChe cosa manca al salvataggio?", "choices": ["Il nome del font", "La lista dei caffè bevuti", "La posizione dell'ultimo checkpoint"], "correct": 2},
	{"title": "VITE INFINITE? MAGARI", "question": "Una collisione toglie 60 vite al secondo.\nCome eviti i colpi ripetuti?", "choices": ["Breve invulnerabilità dopo il colpo", "Più particelle sullo schermo", "Rimuovi il tasto Pausa"], "correct": 0},
	{"title": "RICHARD PASSA NEI TAVOLI", "question": "La pattuglia attraversa le scrivanie.\nQuale modifica è utile?", "choices": ["Nascondi i tavoli con una texture", "Percorso su punti nel corridoio", "Muovilo ancora più velocemente"], "correct": 1},
	{"title": "IL TIMER NON SI FERMA", "question": "Il conto alla rovescia scorre in pausa.\nDove deve stare l'aggiornamento?", "choices": ["Dentro il loop dei pixel", "Nel titolo della finestra", "Solo nello stato di gioco attivo"], "correct": 2},
	{"title": "IL RIMBALZO ESPLODE", "question": "Ogni rimbalzo aumenta la velocità.\nCome tieni la pallina sotto controllo?", "choices": ["Metti un limite alla velocità", "Moltiplica la velocità per dieci", "Cambia il nome al progetto"], "correct": 0},
	{"title": "RESPAWN NEL VUOTO", "question": "Il personaggio ricompare sotto la mappa.\nQual è il controllo da aggiungere?", "choices": ["Quanti tab sono aperti", "Che il punto di respawn sia sicuro", "La risoluzione del logo"], "correct": 1}
]
