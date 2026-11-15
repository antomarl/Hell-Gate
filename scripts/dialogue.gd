class_name HavenDialogue
extends RefCounted

const IDLE = [
	"Ragazzi, ricordatevi di bere. Anche acqua, eh.",
	"Avete già provato ad avviarlo?",
	"Chi ha chiamato il progetto final_final_v7?",
	"Possiamo aprire un attimo la finestra?",
	"Se funziona, non toccatelo fino alla presentazione.",
	"Salvate, che poi qualcuno stacca la ciabatta.",
	"C'è qualcuno che sa dove sia finito l'adattatore?",
	"Di chi è il caricatore vicino alla porta?",
	"Avete bisogno di una mano con qualcosa?",
	"Mi raccomando, una pausa ogni tanto.",
	"Il Wi-Fi regge? Non gufatela.",
	"A che ora volete presentare?"]
const APPROACH = [
	"Passo a vedere come procede!",
	"Mi fate vedere un pezzetto di codice?",
	"Fermi un secondo, cosa c'è sullo schermo?",
	"Aspettate, che tab avete aperto?",
	"Quella finestra prima non c'era.",
	"Un attimo: vengo alla vostra postazione.",
	"State scrivendo o state aspettando una risposta?",
	"Mi spiegate cosa fa questa funzione?"]
const SAFE = [
	"Ah, documentazione. Bravi, bravi.",
	"Ok. Fatemi sapere se si blocca ancora.",
	"Tutto a posto. Continuate così.",
	"Ah, state ancora sistemando il ciclo.",
	"Va bene, torno dopo.",
	"Mi piace: almeno qualcuno legge il README.",
	"State debuggando? Vi lascio concentrati.",
	"Bene. Torno a cercare il cavo HDMI."]
const SUSPICIOUS = [
	"Perché avete cambiato tab così in fretta?",
	"Ho letto 'Certamente!' o me lo sono immaginato?",
	"Quei commenti sembrano un po' troppo educati.",
	"Non era una chat, quella?",
	"Curioso... scrivete 200 righe al secondo?",
	"Aspetta, torna sulla scheda di prima."]
const DISTRACT = [
	"La stampante fa COSA? Arrivo!",
	"Un bug sul proiettore? Vado a vedere.",
	"Chi ha staccato il router?!",
	"Va bene, controllo io il cavo HDMI."]
const CAUGHT = [
	"'Come modello linguistico...' Ragazzi. Sul serio?",
	"Eccola, è la chat che avevo visto prima.",
	"Bel prompt. Ora me lo spiegate alla lavagna?",
	"Vi ho beccati! Almeno chiedetegli di fixare i bug."]
const WIN = [
	"Gioco consegnato! Fatto tutto voi, vero?",
	"Funziona davvero? Questa sì che è una sorpresa.",
	"Ok, funziona. Fatelo vedere agli altri.",
	"Bella demo. Ci vediamo al prossimo Haven!"]

const BOUNCE = [
	"Ok, ora gira. Non toccate più quella funzione.",
	"Avete salvato prima del crash, sì?",
	"Ecco, molto meglio. Fate un commit.",
	"Mancano pochi minuti, riuscite a chiuderla?",
	"Quel bug lo conosco. Ci sono cascato anch'io.",
	"Ripartite dal salvataggio, vi aspetto alla demo."
]
