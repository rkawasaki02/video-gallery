const KEY = 'nvim_vg_v1';
function load() { try { return JSON.parse(localStorage.getItem(KEY)) || []; } catch { return []; } }
function save(v) { localStorage.setItem(KEY, JSON.stringify(v)); }

let videos = load();

function extractId(url) {
	url = url.trim().replace(/^["']|["']$/g, '');
	const m = url.match(/(?:youtube\.com\/watch\?.*v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/shorts\/)([A-Za-z0-9_-]{11})/);
	if (m) return m[1];
	if (/^[A-Za-z0-9_-]{11}$/.test(url)) return url;
	return null;
}

function thumbUrl(id) { return `https://img.youtube.com/vi/${id}/hqdefault.jpg`; }
function embedUrl(id, muted = true) {
	return `https://www.youtube.com/embed/${id}?autoplay=1&mute=${muted ? 1 : 0}&controls=1&rel=0&modestbranding=1`;
}

function addVideo() {
	const urlEl = document.getElementById('urlInput');
	const titleEl = document.getElementById('titleInput');
	const url = urlEl.value.trim();
	const title = titleEl.value.trim().replace(/^["']|["']$/g, '');
	if (!url) { showToast('E: url required', true); return; }
	const id = extractId(url);
	if (!id) { showToast('E: invalid YouTube URL', true); return; }
	if (videos.find(v => v.id === id)) { showToast('W: already exists', true); return; }
	videos.unshift({ id, title: title || id, addedAt: Date.now() });
	save(videos);
	render();
	urlEl.value = '';
	titleEl.value = '';
	showToast('-- video added ✓');
}

document.getElementById('urlInput').addEventListener('keydown', e => { if (e.key === 'Enter') addVideo(); });
document.getElementById('titleInput').addEventListener('keydown', e => { if (e.key === 'Enter') addVideo(); });

function deleteVideo(id) {
	videos = videos.filter(v => v.id !== id);
	save(videos);
	render();
	showToast('-- deleted');
}

function render() {
	const n = videos.length;
	document.getElementById('count-display').textContent = `${n} video${n !== 1 ? 's' : ''}`;
	document.getElementById('sl-count').textContent = `${n}:1`;

	const lines = 5 + Math.max(n * 3, 2);
	document.getElementById('lineNums').innerHTML =
		Array.from({ length: lines }, (_, i) =>
			`<div class="line-num${i === 1 ? ' hl' : ''}">${i + 1}</div>`
		).join('');

	const gallery = document.getElementById('gallery');

	if (n === 0) {
		gallery.innerHTML = `<div class="empty">-- no videos yet<br>-- add a YouTube URL above</div>`;
		return;
	}

	gallery.innerHTML = videos.map(v => `
    <div class="card" id="card-${v.id}" data-id="${v.id}">
      <div class="card-bar">
        <div class="dot dot-r"></div>
        <div class="dot dot-y"></div>
        <div class="dot dot-g"></div>
        <div class="card-bar-title">${esc(v.title)}</div>
        <button class="btn-delete" onclick="event.stopPropagation();deleteVideo('${v.id}')" title=":bd">✕</button>
      </div>
      <div class="thumb-wrap">
        <img src="${thumbUrl(v.id)}" alt="${esc(v.title)}" loading="lazy">
        <iframe id="iframe-${v.id}" src="" allow="autoplay; encrypted-media" allowfullscreen></iframe>
        <div class="play-btn">
          <svg viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
            <circle cx="30" cy="30" r="30" fill="rgba(26,27,38,0.75)"/>
            <circle cx="30" cy="30" r="29" stroke="rgba(122,162,247,0.5)" stroke-width="1"/>
            <polygon points="24,18 46,30 24,42" fill="#7aa2f7"/>
          </svg>
        </div>
      </div>
      <div class="card-foot">
        <span style="color:var(--comment)">id =</span>
        <span class="vid-id">"${v.id}"</span>
      </div>
    </div>
  `).join('');

	document.querySelectorAll('.card').forEach(card => {
		const id = card.dataset.id;
		const iframe = card.querySelector('iframe');
		card.addEventListener('mouseenter', () => { iframe.src = embedUrl(id, true); card.classList.add('hovered'); });
		card.addEventListener('mouseleave', () => { card.classList.remove('hovered'); iframe.src = ''; });
		card.addEventListener('click', () => {
			if (window.innerWidth <= 640) {
				const already = card.classList.contains('active-mobile');
				document.querySelectorAll('.card.active-mobile').forEach(c => { c.classList.remove('active-mobile'); c.querySelector('iframe').src = ''; });
				if (!already) { iframe.src = embedUrl(id, false); card.classList.add('active-mobile'); }
			}
		});
	});

	if (window.innerWidth <= 640) setupCenter();
}

let st = null;
function setupCenter() {
	window.removeEventListener('scroll', onScroll);
	window.addEventListener('scroll', onScroll, { passive: true });
}
function onScroll() {
	clearTimeout(st);
	st = setTimeout(() => {
		const cy = window.innerHeight / 2;
		let best = null, dist = Infinity;
		document.querySelectorAll('.card').forEach(c => {
			const r = c.getBoundingClientRect();
			const d = Math.abs(r.top + r.height / 2 - cy);
			if (d < dist) { dist = d; best = c; }
		});
		document.querySelectorAll('.card').forEach(c => c.classList.remove('center-active'));
		if (best) best.classList.add('center-active');
	}, 150);
}

function showToast(msg, err = false) {
	const t = document.getElementById('toast');
	t.textContent = msg;
	t.className = 'toast' + (err ? ' err' : '');
	void t.offsetWidth;
	t.classList.add('show');
	setTimeout(() => t.classList.remove('show'), 2500);
}

function esc(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }

render();
