# 💿 IsoMounter Matrix

Monta e smonta immagini ISO su Windows con una GUI in stile Matrix, log e persistenza dello stato.

## ✨ Feature

- ✅ **Mount ISO**: seleziona o trascina un file `.iso` per montarlo come unità virtuale
- ✅ **Dismount Selected**: smonta l'ISO selezionato
- ✅ **Dismount All**: smonta tutti gli ISO contemporaneamente
- ✅ **Drag & Drop**: trascina un file ISO direttamente nella finestra
- ✅ **Persistenza**: salva la lista degli ISO montati in `mounted_isos.json`
- ✅ **Pulizia automatica**: rimuove dal JSON gli ISO smontati manualmente
- ✅ **Log su file**: `isomounter_*.log` con tutte le operazioni
- ✅ **Auto-elevazione admin**: richiede i permessi necessari

## 📋 Requisiti

- **Windows 10 / 11**
- **PowerShell 7+** (scarica da https://aka.ms/powershell)
- **Permessi di amministratore** (necessari per `Mount-DiskImage`)

## 🚀 Quick start

```powershell
git clone https://github.com/fabrytoolbox/IsoMounter-Matrix.git
cd IsoMounter-Matrix
Unblock-File .\IsoMounter-Matrix.ps1
.\IsoMounter-Matrix.ps1

Oppure doppio click su avvia.bat.

🎯 Casi d'uso
Installare software da ISO senza masterizzare

Esplorare il contenuto di un'immagine disco

Backup di ISO montate per uso immediato

Test di supporti di installazione

🛡️ Sicurezza
Log di ogni operazione

Pulizia automatica degli ISO non più montati

Elevazione admin richiesta solo per le operazioni necessarie

🐛 Problemi comuni
"Accesso negato"
Il tool richiede l'elevazione admin. Accetta il prompt UAC quando appare.

"L'ISO non si smonta"
Se un file è in uso, Windows potrebbe bloccare lo smontaggio. Chiudi i programmi che stanno usando l'unità virtuale e riprova.

"PowerShell 7 non trovato"
Installa PowerShell 7 da https://aka.ms/powershell

📜 Licenza
MIT (vedi LICENSE).

🙏 Crediti
Fabry Toolbox

PowerShell 7 + WinForms

Tema Matrix
