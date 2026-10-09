/* =====================================================================
   Java-Trainer - Oberfläche
   ===================================================================== */
'use strict';

const TOKEN = document.querySelector('meta[name="token"]').content;
const $ = (id) => document.getElementById(id);

let kurs = { kapitel: [], lektionen: [] };
let zustand = leererZustand();
let aktuelle = null;
let editor = null;
let speicherTimer = null;
let beschaeftigt = false;
const offeneKapitel = new Set();

function leererZustand() {
  return {
    version: 1,
    erledigt: {},       // id -> { xp, datum }
    code: {},           // id -> zuletzt geschriebener Code
    versuche: {},       // id -> Anzahl Prüfungen
    loesungGesehen: {}, // id -> true
    tipps: {},          // id -> Anzahl aufgedeckter Tipps
    tage: [],           // Tage mit gelösten Lektionen (JJJJ-MM-TT)
    letzte: null,
    thema: 'dark',
    geaendert: 0,
  };
}

// ---------------------------------------------------------------------
//  Server
// ---------------------------------------------------------------------
async function api(pfad, optionen = {}) {
  const antwort = await fetch(pfad, {
    ...optionen,
    headers: { 'X-Token': TOKEN, ...(optionen.headers || {}) },
  });
  if (!antwort.ok) {
    throw new Error('HTTP ' + antwort.status);
  }
  return antwort.json();
}

function base64(text) {
  const bytes = new TextEncoder().encode(text);
  let binaer = '';
  for (const b of bytes) {
    binaer += String.fromCharCode(b);
  }
  return btoa(binaer);
}

// ---------------------------------------------------------------------
//  Fortschritt speichern
// ---------------------------------------------------------------------
function speichern(sofort = false) {
  zustand.geaendert = Date.now();
  try {
    localStorage.setItem('javatrainer', JSON.stringify(zustand));
  } catch (e) {
    // privater Modus o. ä. - der Server speichert trotzdem
  }
  clearTimeout(speicherTimer);
  const senden = () => fetch('/api/fortschritt', {
    method: 'POST',
    keepalive: true,
    headers: { 'X-Token': TOKEN, 'Content-Type': 'application/json' },
    body: JSON.stringify(zustand),
  }).catch(() => toast('Fortschritt konnte nicht gespeichert werden – läuft der Trainer noch?'));
  if (sofort) {
    senden();
  } else {
    speicherTimer = setTimeout(senden, 700);
  }
}

function heute() {
  const d = new Date();
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
}

function lernserie() {
  const tage = new Set(zustand.tage);
  const tag = new Date();
  if (!tage.has(heute())) {
    tag.setDate(tag.getDate() - 1); // Serie zählt bis gestern, solange heute noch Zeit ist
  }
  let serie = 0;
  for (;;) {
    const s = tag.getFullYear() + '-' + String(tag.getMonth() + 1).padStart(2, '0') + '-' + String(tag.getDate()).padStart(2, '0');
    if (!tage.has(s)) {
      return serie;
    }
    serie++;
    tag.setDate(tag.getDate() - 1);
  }
}

function gesamtXp() {
  return Object.values(zustand.erledigt).reduce((summe, e) => summe + (e.xp || 0), 0);
}

function istErledigt(id) {
  return Boolean(zustand.erledigt[id]);
}

// ---------------------------------------------------------------------
//  Start
// ---------------------------------------------------------------------
async function start() {
  try {
    const lokal = JSON.parse(localStorage.getItem('javatrainer') || 'null');
    if (lokal && lokal.thema) {
      setzeThema(lokal.thema);
    }
  } catch (e) {
    // egal
  }
  try {
    const [k, server] = await Promise.all([api('/api/kurs'), api('/api/fortschritt')]);
    kurs = k;
    let lokal = null;
    try {
      lokal = JSON.parse(localStorage.getItem('javatrainer') || 'null');
    } catch (e) {
      lokal = null;
    }
    const basis = (lokal && (lokal.geaendert || 0) > (server.geaendert || 0)) ? lokal : server;
    zustand = { ...leererZustand(), ...basis };
  } catch (e) {
    document.body.innerHTML = '<div style="padding:40px;font:16px system-ui">'
      + '<h2>Der Trainer ist nicht erreichbar</h2>'
      + '<p>Bitte starte ihn neu mit <code>java Trainer.java</code> im Ordner <code>java-lernprogramm</code> '
      + 'und öffne die angezeigte Adresse.</p></div>';
    return;
  }
  setzeThema(zustand.thema || 'dark');
  baueEditor();
  verbindeKnoepfe();
  renderKopf();
  window.addEventListener('hashchange', route);
  route();
}

function route() {
  const treffer = location.hash.match(/^#\/l\/(.+)$/);
  const lektion = treffer && kurs.lektionen.find((l) => l.id === decodeURIComponent(treffer[1]));
  schliesseMenue();
  if (lektion) {
    zeigeLektion(lektion);
  } else {
    zeigeUebersicht();
  }
}

function geheZu(lektion) {
  location.hash = lektion ? '#/l/' + encodeURIComponent(lektion.id) : '#/';
}

// ---------------------------------------------------------------------
//  Kopfzeile und Seitenleiste
// ---------------------------------------------------------------------
function renderKopf() {
  const geloest = kurs.lektionen.filter((l) => istErledigt(l.id)).length;
  const gesamt = kurs.lektionen.length;
  $('gesamtText').textContent = geloest + ' / ' + gesamt;
  $('gesamtBalken').style.width = (gesamt ? (100 * geloest / gesamt) : 0) + '%';
  $('xpWert').textContent = gesamtXp();
  $('serieWert').textContent = lernserie();
}

function lektionenVon(kapitel) {
  return kurs.lektionen.filter((l) => l.kapitel === kapitel.nummer);
}

function renderSeitenleiste() {
  const leiste = $('seitenleiste');
  leiste.innerHTML = '';
  for (const k of kurs.kapitel) {
    const lektionen = lektionenVon(k);
    const geloest = lektionen.filter((l) => istErledigt(l.id)).length;
    const box = document.createElement('div');
    box.className = 'kapitel' + (offeneKapitel.has(k.nummer) ? ' offen' : '')
      + (lektionen.length && geloest === lektionen.length ? ' fertig' : '');

    const kopf = document.createElement('button');
    kopf.className = 'kapitel-kopf';
    kopf.innerHTML = `<span class="kapitel-nummer">${geloest === lektionen.length && lektionen.length ? '✓' : Number(k.nummer)}</span>
      <span class="kapitel-titel">${esc(k.titel)}<span class="kapitel-zaehler">${geloest} von ${lektionen.length} gelöst</span></span>
      <span class="kapitel-pfeil">›</span>`;
    kopf.addEventListener('click', () => {
      if (offeneKapitel.has(k.nummer)) {
        offeneKapitel.delete(k.nummer);
      } else {
        offeneKapitel.add(k.nummer);
      }
      box.classList.toggle('offen');
    });
    box.appendChild(kopf);

    const liste = document.createElement('ul');
    liste.className = 'lektionsliste';
    for (const l of lektionen) {
      const li = document.createElement('li');
      const knopf = document.createElement('button');
      knopf.className = 'lektion-link' + (istErledigt(l.id) ? ' erledigt' : '') + (aktuelle && aktuelle.id === l.id ? ' aktiv' : '');
      const marke = l.typ === 'quiz' ? 'Quiz' : l.typ === 'info' ? 'Info' : '';
      knopf.innerHTML = `<span class="status-punkt"></span><span>${esc(l.titel)}</span>${marke ? `<span class="typ-marke">${marke}</span>` : ''}`;
      knopf.addEventListener('click', () => geheZu(l));
      li.appendChild(knopf);
      liste.appendChild(li);
    }
    box.appendChild(liste);
    leiste.appendChild(box);
  }
  const aktiv = leiste.querySelector('.lektion-link.aktiv');
  if (aktiv) {
    aktiv.scrollIntoView({ block: 'nearest' });
  }
}

// ---------------------------------------------------------------------
//  Kursübersicht
// ---------------------------------------------------------------------
function naechsteOffene() {
  const start = Math.max(0, kurs.lektionen.findIndex((l) => l.id === zustand.letzte));
  for (let i = 0; i < kurs.lektionen.length; i++) {
    const l = kurs.lektionen[(start + i) % kurs.lektionen.length];
    if (!istErledigt(l.id)) {
      return l;
    }
  }
  return null;
}

function zeigeUebersicht() {
  aktuelle = null;
  $('lektion').hidden = true;
  const ue = $('uebersicht');
  ue.hidden = false;
  renderSeitenleiste();

  const geloest = kurs.lektionen.filter((l) => istErledigt(l.id)).length;
  const kapitelFertig = kurs.kapitel.filter((k) => {
    const ls = lektionenVon(k);
    return ls.length && ls.every((l) => istErledigt(l.id));
  }).length;
  const weiter = naechsteOffene();
  const neu = geloest === 0;

  ue.innerHTML = `
    <div class="willkommen">
      <div>
        <h1>${neu ? 'Willkommen beim Java-Trainer!' : 'Schön, dass du wieder da bist!'}</h1>
        <p>${neu
          ? 'Kurze Lektionen, echter Java-Code und sofortiges Feedback – passend zum Skript „Einführung in die objektorientierte Programmierung, Teil 1“. Lies die Erklärung, löse die Aufgabe im Editor und klicke auf <b>Prüfen</b>.'
          : (weiter ? 'Als Nächstes wartet: <b>' + esc(weiter.titel) + '</b>' : 'Du hast alle Lektionen gelöst. Stark!')}</p>
      </div>
      ${weiter ? `<button class="knopf knopf-haupt" id="weiterLernen">${neu ? 'Los geht’s' : 'Weiter lernen'} →</button>` : ''}
    </div>
    <div class="statistik-reihe">
      <div class="statistik"><div class="statistik-wert">${geloest}<span class="gedaempft"> / ${kurs.lektionen.length}</span></div><div class="statistik-name">Lektionen gelöst</div></div>
      <div class="statistik"><div class="statistik-wert" style="color:var(--gelb)">${gesamtXp()}</div><div class="statistik-name">Erfahrungspunkte (XP)</div></div>
      <div class="statistik"><div class="statistik-wert" style="color:var(--rot)">${lernserie()} ${lernserie() === 1 ? 'Tag' : 'Tage'}</div><div class="statistik-name">Lernserie</div></div>
      <div class="statistik"><div class="statistik-wert" style="color:var(--gruen)">${kapitelFertig}<span class="gedaempft"> / ${kurs.kapitel.length}</span></div><div class="statistik-name">Kapitel abgeschlossen</div></div>
    </div>
    <h2>Kapitel</h2>
    <div class="kapitel-raster" id="kapitelRaster"></div>`;

  const raster = $('kapitelRaster');
  for (const k of kurs.kapitel) {
    const ls = lektionenVon(k);
    const g = ls.filter((l) => istErledigt(l.id)).length;
    const fertig = ls.length && g === ls.length;
    const karte = document.createElement('button');
    karte.className = 'kapitel-karte' + (fertig ? ' fertig' : '');
    karte.innerHTML = `
      <span class="kapitel-nummer" style="${fertig ? 'background:var(--gruen-weich);color:var(--gruen)' : ''}">${fertig ? '✓' : Number(k.nummer)}</span>
      <h3>${esc(k.titel)}</h3>
      <p>${esc(k.untertitel)}</p>
      <div class="karten-fuss"><div class="balken"><div class="balken-fuellung" style="width:${ls.length ? 100 * g / ls.length : 0}%"></div></div>${g}/${ls.length}</div>`;
    karte.addEventListener('click', () => {
      const ziel = ls.find((l) => !istErledigt(l.id)) || ls[0];
      if (ziel) {
        geheZu(ziel);
      }
    });
    raster.appendChild(karte);
  }
  const knopf = $('weiterLernen');
  if (knopf) {
    knopf.addEventListener('click', () => geheZu(weiter));
  }
}

// ---------------------------------------------------------------------
//  Lektion anzeigen
// ---------------------------------------------------------------------
function zeigeLektion(l) {
  aktuelle = l;
  zustand.letzte = l.id;
  speichern();
  offeneKapitel.add(l.kapitel);
  $('uebersicht').hidden = true;
  const bereich = $('lektion');
  bereich.hidden = false;
  bereich.className = 'lektion' + (l.typ === 'quiz' ? ' einspaltig nur-arbeit' : l.typ === 'info' ? ' einspaltig nur-text' : '');

  renderSeitenleiste();
  renderLektionText(l);

  $('editorBereich').hidden = l.typ !== 'code';
  $('quizBereich').hidden = l.typ !== 'quiz';
  $('infoBereich').hidden = true;

  if (l.typ === 'code') {
    const code = zustand.code[l.id] ?? l.vorlage;
    editor.setValue(code);
    editor.clearHistory();
    markiereFehlerzeilen([]);
    $('eingabeText').value = '';
    $('eingabeFeld').hidden = !l.vorlage.includes('Scanner');
    $('eingabeKnopf').classList.toggle('aktiv', !$('eingabeFeld').hidden);
    zeigeReiter('ergebnis');
    $('konsoleErgebnis').innerHTML = istErledigt(l.id)
      ? '<div class="ergebnis-kopf ergebnis-ok"><span class="symbol">✓</span><div>Diese Lektion hast du schon gelöst.<small>Du kannst trotzdem weiter üben.</small></div></div>'
      : '<p class="leer-hinweis">Schreibe deinen Code und klicke auf <b>Prüfen</b>. Mit <b>Ausführen</b> startest du nur dein Programm und siehst die Ausgabe im Reiter „Konsole“.</p>';
    $('konsoleAusgabe').textContent = '';
    setzeAusgabeZahl(0);
    setTimeout(() => {
      editor.refresh();
      if (window.innerWidth > 860) {
        editor.focus();
      }
    }, 30);
  } else if (l.typ === 'quiz') {
    renderQuiz(l);
  }
  $('lektionText').scrollTop = 0;
  $('quizBereich').scrollTop = 0;
}

function renderLektionText(l) {
  const kapitel = kurs.kapitel.find((k) => k.nummer === l.kapitel);
  const index = kurs.lektionen.indexOf(l);
  const imKapitel = lektionenVon(kapitel || { nummer: l.kapitel });
  const nr = imKapitel.indexOf(l) + 1;
  const typName = l.typ === 'quiz' ? 'Quiz' : l.typ === 'info' ? 'Info' : 'Programmieren';
  const erledigt = istErledigt(l.id);
  const t = $('lektionText');

  if (l.typ === 'quiz') {
    t.innerHTML = '';
    return;
  }

  const tippsOffen = Math.min(zustand.tipps[l.id] || 0, l.tipps.length);
  let tippsHtml = '';
  for (let i = 0; i < tippsOffen; i++) {
    tippsHtml += `<div class="tipp"><div class="tipp-titel">💡 Tipp ${i + 1}</div><div class="md">${md(l.tipps[i])}</div></div>`;
  }

  t.innerHTML = `
    <div class="brotkrumen">Kapitel ${Number(l.kapitel)} · ${esc(kapitel ? kapitel.titel : '')} · Lektion ${nr} von ${imKapitel.length}</div>
    <h1>${esc(l.titel)}</h1>
    <div class="marken">
      <span class="marke">${typName}</span>
      <span class="marke marke-xp">⚡ ${l.xp} XP</span>
      ${erledigt ? '<span class="marke marke-erledigt">✓ gelöst</span>' : ''}
      ${l.aufgabe ? '<button class="link-knopf zur-aufgabe" id="zurAufgabe">🎯 Zur Aufgabe ↓</button>' : ''}
    </div>
    <div class="md">${md(l.erklaerung)}</div>
    ${l.aufgabe ? `<div class="aufgabe-karte" id="aufgabeKarte"><div class="aufgabe-titel">🎯 Deine Aufgabe</div><div class="md">${md(l.aufgabe)}</div></div>` : ''}
    <div id="tippListe">${tippsHtml}</div>
    ${l.typ === 'code' ? `<div class="hilfe">
      ${l.tipps.length ? `<button class="knopf knopf-zweit" id="tippKnopf" ${tippsOffen >= l.tipps.length ? 'hidden' : ''}>💡 Tipp anzeigen (${tippsOffen + 1}/${l.tipps.length})</button>` : ''}
      ${l.hatLoesung ? '<button class="link-knopf" id="loesungKnopf">Musterlösung ansehen</button>' : ''}
    </div>` : ''}
    ${l.typ === 'info' ? `<div class="hilfe"><button class="knopf ${erledigt ? 'knopf-zweit' : 'knopf-gruen'}" id="gelesenKnopf">${erledigt ? '✓ Gelesen' : '✓ Gelesen – weiter'}</button></div>` : ''}
    <div class="navigation">
      <button class="knopf knopf-zweit" id="zurueckKnopf" ${index <= 0 ? 'disabled' : ''}>← Zurück</button>
      <button class="knopf knopf-zweit" id="vorKnopf">${index >= kurs.lektionen.length - 1 ? 'Zur Übersicht' : 'Nächste Lektion →'}</button>
    </div>`;

  hebeCodeHervor(t);
  const zurAufgabe = $('zurAufgabe');
  if (zurAufgabe) {
    zurAufgabe.addEventListener('click', () => $('aufgabeKarte').scrollIntoView({ behavior: 'smooth', block: 'start' }));
  }
  const tippKnopf = $('tippKnopf');
  if (tippKnopf) {
    tippKnopf.addEventListener('click', () => {
      zustand.tipps[l.id] = (zustand.tipps[l.id] || 0) + 1;
      speichern();
      renderLektionText(l);
      const tipps = $('tippListe').querySelectorAll('.tipp');
      if (tipps.length) {
        tipps[tipps.length - 1].scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      }
    });
  }
  const loesungKnopf = $('loesungKnopf');
  if (loesungKnopf) {
    loesungKnopf.addEventListener('click', () => zeigeLoesung(l));
  }
  const gelesen = $('gelesenKnopf');
  if (gelesen) {
    gelesen.addEventListener('click', () => {
      if (istErledigt(l.id)) {
        geheZu(kurs.lektionen[index + 1]);
      } else {
        lektionGeschafft(l);
      }
    });
  }
  $('zurueckKnopf').addEventListener('click', () => geheZu(kurs.lektionen[index - 1]));
  $('vorKnopf').addEventListener('click', () => geheZu(kurs.lektionen[index + 1]));
}

// ---------------------------------------------------------------------
//  Editor
// ---------------------------------------------------------------------
function baueEditor() {
  editor = CodeMirror($('editorHuelle'), {
    mode: 'text/x-java',
    lineNumbers: true,
    indentUnit: 4,
    tabSize: 4,
    indentWithTabs: false,
    matchBrackets: true,
    autoCloseBrackets: true,
    styleActiveLine: true,
    viewportMargin: 20,
    extraKeys: {
      Tab: (cm) => {
        if (cm.somethingSelected()) {
          cm.indentSelection('add');
        } else {
          cm.replaceSelection('    ', 'end');
        }
      },
      'Shift-Tab': (cm) => cm.indentSelection('subtract'),
      'Ctrl-Enter': () => pruefen(),
      'Cmd-Enter': () => pruefen(),
      'Shift-Ctrl-Enter': () => ausfuehren(),
      'Shift-Cmd-Enter': () => ausfuehren(),
      'Ctrl-S': () => toast('Dein Code wird automatisch gespeichert.'),
      'Cmd-S': () => toast('Dein Code wird automatisch gespeichert.'),
    },
  });
  editor.on('change', () => {
    if (aktuelle && aktuelle.typ === 'code') {
      zustand.code[aktuelle.id] = editor.getValue();
      speichern();
      markiereFehlerzeilen([]);
    }
  });
}

let fehlerzeilen = [];

function markiereFehlerzeilen(zeilen) {
  for (const z of fehlerzeilen) {
    editor.removeLineClass(z, 'background', 'cm-fehlerzeile');
  }
  fehlerzeilen = [];
  for (const nr of zeilen) {
    if (nr >= 1 && nr <= editor.lineCount()) {
      editor.addLineClass(nr - 1, 'background', 'cm-fehlerzeile');
      fehlerzeilen.push(nr - 1);
    }
  }
}

function setzeBeschaeftigt(an, text) {
  beschaeftigt = an;
  $('pruefenKnopf').disabled = an;
  $('ausfuehrenKnopf').disabled = an;
  if (an) {
    $('konsoleErgebnis').innerHTML = `<p class="leer-hinweis"><span class="lade-punkte">${text}</span></p>`;
  }
}

function zeigeReiter(name) {
  $('reiterErgebnis').classList.toggle('aktiv', name === 'ergebnis');
  $('reiterAusgabe').classList.toggle('aktiv', name === 'ausgabe');
  $('konsoleErgebnis').hidden = name !== 'ergebnis';
  $('konsoleAusgabe').hidden = name !== 'ausgabe';
}

function setzeAusgabeZahl(n) {
  $('reiterAusgabe').innerHTML = 'Konsole' + (n ? '<span class="zahl">●</span>' : '');
}

async function ausfuehren() {
  if (beschaeftigt || !aktuelle || aktuelle.typ !== 'code') {
    return;
  }
  setzeBeschaeftigt(true, 'Wird übersetzt und gestartet');
  $('konsoleAusgabe').textContent = '';
  try {
    const kopf = { 'Content-Type': 'text/plain; charset=utf-8' };
    const eingabe = $('eingabeText').value;
    if (eingabe) {
      kopf['X-Eingabe'] = base64(eingabe.endsWith('\n') ? eingabe : eingabe + '\n');
    }
    const r = await api('/api/ausfuehren', { method: 'POST', body: editor.getValue(), headers: kopf });
    if (r.status === 'kompilierfehler') {
      zeigeDiagnosen(r.diagnosen);
      zeigeReiter('ergebnis');
      return;
    }
    let text = r.ausgabe || '';
    if (r.status === 'zeitlimit') {
      text += (text ? '\n\n' : '') + '⏱ Zeitlimit von 5 Sekunden überschritten – das Programm wurde beendet. Endlosschleife? Oder wartet ein Scanner auf Eingaben (⌨ Eingabe)?';
    } else if (!text) {
      text = '(Das Programm hat nichts ausgegeben.)';
    }
    $('konsoleAusgabe').textContent = text;
    $('konsoleErgebnis').innerHTML = r.status === 'ok'
      ? '<p class="leer-hinweis">Programm ausgeführt – die Ausgabe steht im Reiter „Konsole“. Zum Bewerten klicke auf <b>Prüfen</b>.</p>'
      : '<div class="ergebnis-kopf ergebnis-warnung"><span class="symbol">!</span><div>Das Programm wurde mit einem Fehler beendet.<small>Details im Reiter „Konsole“.</small></div></div>';
    markiereFehlerzeilen([]);
    setzeAusgabeZahl(1);
    zeigeReiter('ausgabe');
  } catch (e) {
    $('konsoleErgebnis').innerHTML = '<p class="leer-hinweis">Keine Verbindung zum Trainer. Läuft <code>java Trainer.java</code> noch?</p>';
    zeigeReiter('ergebnis');
  } finally {
    setzeBeschaeftigt(false);
  }
}

async function pruefen() {
  if (beschaeftigt || !aktuelle || aktuelle.typ !== 'code') {
    return;
  }
  const l = aktuelle;
  setzeBeschaeftigt(true, 'Wird geprüft');
  zeigeReiter('ergebnis');
  try {
    const r = await api('/api/pruefen?id=' + encodeURIComponent(l.id), {
      method: 'POST',
      body: editor.getValue(),
      headers: { 'Content-Type': 'text/plain; charset=utf-8' },
    });
    zustand.versuche[l.id] = (zustand.versuche[l.id] || 0) + 1;
    speichern();
    if (aktuelle !== l) {
      return;
    }
    $('konsoleAusgabe').textContent = r.ausgabe ? r.ausgabe : '(Beim Prüfen hat dein Programm nichts zusätzlich ausgegeben.)';
    setzeAusgabeZahl(r.ausgabe ? 1 : 0);
    if (r.status === 'kompilierfehler') {
      zeigeDiagnosen(r.diagnosen);
      return;
    }
    markiereFehlerzeilen([]);
    zeigeTests(r);
    if (r.status === 'bestanden') {
      lektionGeschafft(l);
    }
  } catch (e) {
    $('konsoleErgebnis').innerHTML = '<p class="leer-hinweis">Keine Verbindung zum Trainer. Läuft <code>java Trainer.java</code> noch?</p>';
  } finally {
    setzeBeschaeftigt(false);
  }
}

function zeigeDiagnosen(diagnosen) {
  const eigene = diagnosen.filter((d) => d.datei === 'Main.java');
  const fremde = diagnosen.filter((d) => d.datei !== 'Main.java');
  let html = `<div class="ergebnis-kopf ergebnis-fehler"><span class="symbol">✗</span><div>Der Compiler hat ${diagnosen.length === 1 ? 'einen Fehler' : diagnosen.length + ' Fehler'} gefunden
    <small>Klicke auf einen Fehler, um zur Zeile zu springen.</small></div></div>`;
  for (const d of eigene) {
    html += `<button class="diagnose" data-zeile="${d.zeile}" data-spalte="${d.spalte}"><span class="diagnose-zeile">Zeile ${d.zeile}</span><pre>${esc(d.meldung)}</pre></button>`;
  }
  if (fremde.length) {
    html += `<div class="diagnose"><span class="diagnose-zeile">Hinweis</span>Die Prüfung findet etwas nicht, das sie erwartet.
      Hast du eine Methode oder Klasse umbenannt, gelöscht oder ihre Parameter geändert?<pre>${esc(fremde.map((d) => d.meldung).join('\n'))}</pre></div>`;
  }
  $('konsoleErgebnis').innerHTML = html;
  zeigeReiter('ergebnis');
  markiereFehlerzeilen(eigene.map((d) => d.zeile));
  for (const knopf of $('konsoleErgebnis').querySelectorAll('button.diagnose')) {
    knopf.addEventListener('click', () => {
      const zeile = Number(knopf.dataset.zeile) - 1;
      editor.focus();
      editor.setCursor({ line: zeile, ch: Math.max(0, Number(knopf.dataset.spalte) - 1) });
      editor.scrollIntoView({ line: zeile, ch: 0 }, 80);
    });
  }
}

function zeigeTests(r) {
  const tests = r.tests;
  const ok = tests.filter((t) => t.status === 'OK').length;
  let kopf;
  if (r.status === 'bestanden') {
    kopf = `<div class="ergebnis-kopf ergebnis-ok"><span class="symbol">✓</span><div>Alle ${tests.length} Tests bestanden!<small>Sehr gut gemacht.</small></div></div>`;
  } else if (r.status === 'zeitlimit') {
    kopf = `<div class="ergebnis-kopf ergebnis-warnung"><span class="symbol">⏱</span><div>Zeitlimit von 5 Sekunden überschritten
      <small>Vermutlich eine Endlosschleife – prüfe, ob sich deine Schleifenbedingung irgendwann ändert.</small></div></div>`;
  } else {
    kopf = `<div class="ergebnis-kopf ergebnis-fehler"><span class="symbol">✗</span><div>${ok} von ${tests.length} Tests bestanden
      <small>Schau dir die roten Tests an: erwartet und erhalten.</small></div></div>`;
  }
  let liste = '<ul class="test-liste">';
  for (const t of tests) {
    const klasse = t.status === 'OK' ? 'ok' : t.status === 'OFFEN' ? 'offen' : 'fehler';
    const symbol = t.status === 'OK' ? '✓' : t.status === 'OFFEN' ? '○' : '✗';
    let details = '';
    if (t.status === 'FEHLER' && (t.erwartet || t.erhalten)) {
      details = `<div class="vergleich"><span>erwartet</span><code class="soll">${esc(t.erwartet)}</code><span>erhalten</span><code class="ist">${esc(t.erhalten)}</code></div>`;
    } else if (t.status === 'ABSTURZ') {
      details = `<div class="vergleich"><span>Fehler</span><code class="ist">${esc(t.erhalten)}</code></div>`;
    }
    liste += `<li class="test ${klasse}"><span class="test-symbol">${symbol}</span><div>${esc(t.beschreibung)}${details}</div></li>`;
  }
  liste += '</ul>';
  if (!tests.length) {
    liste = '<p class="leer-hinweis">Es konnte kein Test ausgeführt werden. Schau im Reiter „Konsole“ nach Fehlermeldungen.</p>';
  }
  $('konsoleErgebnis').innerHTML = kopf + liste;
}

// ---------------------------------------------------------------------
//  Quiz
// ---------------------------------------------------------------------
function renderQuiz(l) {
  const kapitel = kurs.kapitel.find((k) => k.nummer === l.kapitel);
  const index = kurs.lektionen.indexOf(l);
  const erledigt = istErledigt(l.id);
  const b = $('quizBereich');
  b.innerHTML = `
    <div class="quiz-karte">
      <div class="brotkrumen">Kapitel ${Number(l.kapitel)} · ${esc(kapitel ? kapitel.titel : '')}</div>
      <h1 style="margin:0 0 10px;font-size:26px;letter-spacing:-0.02em">${esc(l.titel)}</h1>
      <div class="marken"><span class="marke">Quiz</span><span class="marke marke-xp">⚡ ${l.xp} XP</span>${erledigt ? '<span class="marke marke-erledigt">✓ gelöst</span>' : ''}</div>
      <div class="quiz-etikett">Frage</div>
      <div class="quiz-frage md">${md(l.frage)}</div>
      <div class="optionen" id="optionen"></div>
      <div class="quiz-fuss">
        <button class="knopf knopf-haupt" id="antwortKnopf" disabled>Antwort prüfen</button>
        <span class="gedaempft" id="quizMeldung"></span>
      </div>
      <div class="erklaerung-karte" id="quizErklaerung" hidden><div class="md">${md(l.nachher)}</div></div>
      <div class="navigation">
        <button class="knopf knopf-zweit" id="quizZurueck" ${index <= 0 ? 'disabled' : ''}>← Zurück</button>
        <button class="knopf knopf-zweit" id="quizWeiter">${index >= kurs.lektionen.length - 1 ? 'Zur Übersicht' : 'Nächste Lektion →'}</button>
      </div>
    </div>`;
  hebeCodeHervor(b);

  let gewaehlt = -1;
  let fehlversuche = 0;
  const knoepfe = [];
  l.optionen.forEach((text, i) => {
    const knopf = document.createElement('button');
    knopf.className = 'option';
    knopf.innerHTML = `<span class="option-buchstabe">${'ABCDEFGH'[i]}</span><span class="md">${inline(text)}</span>`;
    knopf.addEventListener('click', () => {
      gewaehlt = i;
      knoepfe.forEach((k, j) => k.classList.toggle('gewaehlt', j === i));
      $('antwortKnopf').disabled = false;
    });
    knoepfe.push(knopf);
    $('optionen').appendChild(knopf);
  });

  const aufloesen = () => {
    knoepfe.forEach((k, j) => {
      k.disabled = true;
      k.classList.remove('gewaehlt');
      if (j === l.richtig) {
        k.classList.add('richtig');
      }
    });
    $('antwortKnopf').hidden = true;
    $('quizErklaerung').hidden = false;
  };

  if (erledigt) {
    aufloesen();
    $('quizMeldung').textContent = 'Diese Frage hast du schon richtig beantwortet.';
  }

  $('antwortKnopf').addEventListener('click', () => {
    if (gewaehlt < 0) {
      return;
    }
    if (gewaehlt === l.richtig) {
      aufloesen();
      $('quizMeldung').textContent = fehlversuche ? 'Richtig – im ' + (fehlversuche + 1) + '. Versuch.' : 'Richtig!';
      lektionGeschafft(l, fehlversuche > 0);
    } else {
      fehlversuche++;
      const falsch = knoepfe[gewaehlt];
      falsch.classList.remove('gewaehlt');
      falsch.classList.add('falsch');
      falsch.disabled = true;
      gewaehlt = -1;
      $('antwortKnopf').disabled = true;
      $('quizMeldung').textContent = 'Leider falsch – versuch es noch einmal.';
    }
  });
  $('quizZurueck').addEventListener('click', () => geheZu(kurs.lektionen[index - 1]));
  $('quizWeiter').addEventListener('click', () => geheZu(kurs.lektionen[index + 1]));
}

// ---------------------------------------------------------------------
//  Erfolg
// ---------------------------------------------------------------------
function lektionGeschafft(l, halbeXp = false) {
  const schonVorher = istErledigt(l.id);
  let xp = 0;
  if (!schonVorher) {
    xp = l.xp;
    if (halbeXp || zustand.loesungGesehen[l.id]) {
      xp = Math.ceil(xp / 2);
    }
    zustand.erledigt[l.id] = { xp, datum: heute() };
    if (!zustand.tage.includes(heute())) {
      zustand.tage.push(heute());
    }
    speichern(true);
    renderKopf();
    for (const p of document.querySelectorAll('.pille')) {
      p.classList.remove('puls');
      void p.offsetWidth;
      p.classList.add('puls');
    }
  }
  renderSeitenleiste();
  if (l.typ !== 'quiz') {
    renderLektionText(l);
  }

  const kapitel = kurs.kapitel.find((k) => k.nummer === l.kapitel);
  const kapitelFertig = !schonVorher && kapitel && lektionenVon(kapitel).every((x) => istErledigt(x.id));
  const index = kurs.lektionen.indexOf(l);
  const naechste = kurs.lektionen[index + 1];

  $('erfolgSymbol').textContent = kapitelFertig ? '🏆' : '✓';
  $('erfolgTitel').textContent = kapitelFertig ? 'Kapitel abgeschlossen!' : schonVorher ? 'Wieder bestanden!' : 'Lektion geschafft!';
  $('erfolgText').textContent = kapitelFertig
    ? '„' + kapitel.titel + '“ ist komplett gelöst. Weiter so!'
    : schonVorher ? 'XP gibt es nur beim ersten Lösen – Übung schadet aber nie.' : '„' + l.titel + '“ ist gelöst.';
  $('erfolgXp').textContent = xp ? '+' + xp + ' XP' : '';
  $('erfolgWeiter').textContent = naechste ? 'Weiter →' : 'Zur Übersicht';
  $('erfolgWeiter').onclick = () => {
    schliesseOverlay('erfolg');
    geheZu(naechste);
  };
  $('erfolgBleiben').onclick = () => schliesseOverlay('erfolg');
  setTimeout(() => {
    $('erfolg').hidden = false;
    $('erfolgWeiter').focus();
    if (!schonVorher) {
      konfetti(kapitelFertig ? 220 : 120);
    }
  }, l.typ === 'quiz' ? 700 : 250);
}

function schliesseOverlay(id) {
  $(id).hidden = true;
}

function konfetti(anzahl) {
  const canvas = $('konfetti');
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * devicePixelRatio;
  canvas.height = rect.height * devicePixelRatio;
  const ctx = canvas.getContext('2d');
  ctx.scale(devicePixelRatio, devicePixelRatio);
  const farben = ['#7c5cff', '#2bd9a8', '#ffbe55', '#ff5f7e', '#4fa3ff'];
  const teile = Array.from({ length: anzahl }, () => ({
    x: rect.width / 2,
    y: rect.height * 0.32,
    vx: (Math.random() - 0.5) * 9,
    vy: -Math.random() * 8 - 3,
    groesse: 4 + Math.random() * 5,
    winkel: Math.random() * Math.PI,
    dreh: (Math.random() - 0.5) * 0.3,
    farbe: farben[Math.floor(Math.random() * farben.length)],
  }));
  const startZeit = performance.now();
  const schritt = (jetzt) => {
    const t = jetzt - startZeit;
    ctx.clearRect(0, 0, rect.width, rect.height);
    for (const p of teile) {
      p.vy += 0.22;
      p.vx *= 0.99;
      p.x += p.vx;
      p.y += p.vy;
      p.winkel += p.dreh;
      ctx.save();
      ctx.globalAlpha = Math.max(0, 1 - t / 1800);
      ctx.translate(p.x, p.y);
      ctx.rotate(p.winkel);
      ctx.fillStyle = p.farbe;
      ctx.fillRect(-p.groesse / 2, -p.groesse / 4, p.groesse, p.groesse / 2);
      ctx.restore();
    }
    if (t < 1800) {
      requestAnimationFrame(schritt);
    } else {
      ctx.clearRect(0, 0, rect.width, rect.height);
    }
  };
  requestAnimationFrame(schritt);
}

// ---------------------------------------------------------------------
//  Lösung
// ---------------------------------------------------------------------
async function zeigeLoesung(l) {
  if (!istErledigt(l.id) && !zustand.loesungGesehen[l.id]) {
    const versuche = zustand.versuche[l.id] || 0;
    const frage = (versuche < 2 ? 'Du hast erst ' + versuche + (versuche === 1 ? ' Versuch' : ' Versuche') + ' gemacht. ' : '')
      + 'Wenn du die Lösung vor dem Bestehen ansiehst, gibt es für diese Lektion nur die halben XP.\n\nTrotzdem ansehen?';
    if (!confirm(frage)) {
      return;
    }
    zustand.loesungGesehen[l.id] = true;
    speichern();
  }
  try {
    const r = await api('/api/loesung?id=' + encodeURIComponent(l.id));
    const pre = $('loesungCode');
    pre.textContent = '';
    CodeMirror.runMode(r.loesung, 'text/x-java', pre);
    $('loesungDialog').hidden = false;
    $('loesungOk').focus();
    $('loesungUebernehmen').onclick = () => {
      if (confirm('Deinen Code im Editor durch die Musterlösung ersetzen?')) {
        editor.setValue(r.loesung);
        schliesseOverlay('loesungDialog');
      }
    };
  } catch (e) {
    toast('Die Lösung konnte nicht geladen werden.');
  }
}

// ---------------------------------------------------------------------
//  Knöpfe, Tastatur, Thema
// ---------------------------------------------------------------------
function verbindeKnoepfe() {
  $('ausfuehrenKnopf').addEventListener('click', ausfuehren);
  $('pruefenKnopf').addEventListener('click', pruefen);
  $('zuruecksetzenKnopf').addEventListener('click', () => {
    if (aktuelle && confirm('Deinen Code verwerfen und die Vorlage wiederherstellen?')) {
      editor.setValue(aktuelle.vorlage);
    }
  });
  $('eingabeKnopf').addEventListener('click', () => {
    $('eingabeFeld').hidden = !$('eingabeFeld').hidden;
    $('eingabeKnopf').classList.toggle('aktiv', !$('eingabeFeld').hidden);
    if (!$('eingabeFeld').hidden) {
      $('eingabeText').focus();
    }
    editor.refresh();
  });
  $('reiterErgebnis').addEventListener('click', () => zeigeReiter('ergebnis'));
  $('reiterAusgabe').addEventListener('click', () => zeigeReiter('ausgabe'));
  $('logo').addEventListener('click', (e) => {
    e.preventDefault();
    geheZu(null);
  });
  $('themaKnopf').addEventListener('click', () => {
    setzeThema(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark');
    zustand.thema = document.documentElement.dataset.theme;
    speichern();
  });
  $('menueKnopf').addEventListener('click', () => {
    $('seitenleiste').classList.toggle('offen');
    $('abdunkler').classList.toggle('offen');
  });
  $('abdunkler').addEventListener('click', schliesseMenue);
  $('loesungSchliessen').addEventListener('click', () => schliesseOverlay('loesungDialog'));
  $('loesungOk').addEventListener('click', () => schliesseOverlay('loesungDialog'));
  for (const id of ['erfolg', 'loesungDialog']) {
    $(id).addEventListener('click', (e) => {
      if (e.target === $(id)) {
        schliesseOverlay(id);
      }
    });
  }
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      schliesseOverlay('erfolg');
      schliesseOverlay('loesungDialog');
      schliesseMenue();
    }
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter' && !editor.hasFocus()) {
      e.preventDefault();
      if (e.shiftKey) {
        ausfuehren();
      } else {
        pruefen();
      }
    }
  });
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') {
      speichern(true);
    }
  });
}

function schliesseMenue() {
  $('seitenleiste').classList.remove('offen');
  $('abdunkler').classList.remove('offen');
}

function setzeThema(thema) {
  document.documentElement.dataset.theme = thema === 'light' ? 'light' : 'dark';
}

let toastTimer = null;

function toast(text) {
  const t = $('toast');
  t.textContent = text;
  t.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    t.hidden = true;
  }, 3200);
}

// ---------------------------------------------------------------------
//  Mini-Markdown (Überschriften, Absätze, Listen, Tabellen, Code, Merke-Kästen)
// ---------------------------------------------------------------------
function esc(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function inline(text) {
  return String(text).split(/(`[^`]*`)/).map((teil, i) => {
    if (i % 2 === 1) {
      return '<code>' + esc(teil.slice(1, -1)) + '</code>';
    }
    return esc(teil)
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/(^|[\s(„])\*(\S(?:.*?\S)?)\*(?=[\s).,:;!?“]|$)/g, '$1<em>$2</em>')
      .replace(/\[([^\]]+)\]\((https?:[^)\s]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
  }).join('');
}

const BLOCKSTART = /^(```|#{1,3} |\||> |\s*[-*] |\s*\d+\. )/;

function md(text) {
  const zeilen = String(text || '').replace(/\r/g, '').split('\n');
  let html = '';
  let i = 0;
  while (i < zeilen.length) {
    const z = zeilen[i];
    if (z.trim() === '') {
      i++;
    } else if (z.startsWith('```')) {
      const sprache = z.slice(3).trim();
      const code = [];
      i++;
      while (i < zeilen.length && !zeilen[i].startsWith('```')) {
        code.push(zeilen[i++]);
      }
      i++;
      html += `<pre class="code-block cm-s-trainer"${sprache === 'java' ? ' data-java="1"' : ''}>${esc(code.join('\n'))}</pre>`;
    } else if (/^#{1,3} /.test(z)) {
      const n = z.match(/^#+/)[0].length;
      html += `<h${n + 1}>${inline(z.slice(n + 1))}</h${n + 1}>`;
      i++;
    } else if (z.startsWith('|')) {
      const reihen = [];
      while (i < zeilen.length && zeilen[i].startsWith('|')) {
        reihen.push(zeilen[i++]);
      }
      const zellen = (r) => r.replace(/\\\|/g, '\u0000').split('|').slice(1, -1).map((c) => c.replace(/\u0000/g, '|').trim());
      html += '<table><thead><tr>' + zellen(reihen[0]).map((c) => `<th>${inline(c)}</th>`).join('') + '</tr></thead><tbody>';
      for (const r of reihen.slice(2)) {
        html += '<tr>' + zellen(r).map((c) => `<td>${inline(c)}</td>`).join('') + '</tr>';
      }
      html += '</tbody></table>';
    } else if (z.startsWith('>')) {
      const innen = [];
      while (i < zeilen.length && zeilen[i].startsWith('>')) {
        innen.push(zeilen[i++].replace(/^> ?/, ''));
      }
      html += `<div class="merke">${md(innen.join('\n'))}</div>`;
    } else if (/^\s*([-*]|\d+\.) /.test(z)) {
      const geordnet = /^\s*\d+\. /.test(z);
      const punkte = [];
      while (i < zeilen.length && (/^\s*([-*]|\d+\.) /.test(zeilen[i]) || (/^\s{2,}\S/.test(zeilen[i]) && punkte.length))) {
        if (/^\s*([-*]|\d+\.) /.test(zeilen[i]) && !/^\s{3,}/.test(zeilen[i])) {
          punkte.push(zeilen[i].replace(/^\s*([-*]|\d+\.) /, ''));
        } else {
          punkte[punkte.length - 1] += '\n' + zeilen[i].trim();
        }
        i++;
      }
      const tag = geordnet ? 'ol' : 'ul';
      html += `<${tag}>` + punkte.map((p) => '<li>' + p.split('\n').map(inline).join('<br>') + '</li>').join('') + `</${tag}>`;
    } else {
      const absatz = [];
      while (i < zeilen.length && zeilen[i].trim() !== '' && !(absatz.length && BLOCKSTART.test(zeilen[i]))) {
        absatz.push(zeilen[i++]);
      }
      html += '<p>' + inline(absatz.join(' ')) + '</p>';
    }
  }
  return html;
}

function hebeCodeHervor(wurzel) {
  for (const pre of wurzel.querySelectorAll('pre[data-java]')) {
    const code = pre.textContent;
    pre.textContent = '';
    CodeMirror.runMode(code, 'text/x-java', pre);
  }
}

start();
