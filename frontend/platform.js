// ── Platform detection & helpers ──

const ALLOWED_DOMAINS = [
	'youtube.com', 'youtu.be',
	'vimeo.com',
	'twitch.tv',
	'video.twimg.com',
];

export function detectPlatform(url) {
	url = url.trim().replace(/^["']|["']$/g, '');

	// YouTube
	const yt = url.match(/(?:youtube\.com\/watch\?.*v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/shorts\/)([A-Za-z0-9_-]{11})/);
	if (yt) return { type: 'youtube', id: yt[1], url };
	if (/^[A-Za-z0-9_-]{11}$/.test(url)) return { type: 'youtube', id: url, url };

	// Vimeo
	const vimeo = url.match(/vimeo\.com\/(?:video\/)?(\d+)/);
	if (vimeo) return { type: 'vimeo', id: vimeo[1], url };

	// Twitch clip
	const twitchClip = url.match(/twitch\.tv\/\w+\/clip\/([A-Za-z0-9_-]+)/);
	if (twitchClip) return { type: 'twitch_clip', id: twitchClip[1], url };

	// Twitch channel
	const twitch = url.match(/twitch\.tv\/([A-Za-z0-9_]+)/);
	if (twitch) return { type: 'twitch', id: twitch[1], url };

	// mp4直リンク / X動画
	if (/\.(mp4|webm|ogg|mov)(\?.*)?$/i.test(url) || url.includes('video.twimg.com')) {
		return { type: 'mp4', id: url, url };
	}

	return null;
}

export function getThumb(platform) {
	switch (platform.type) {
		case 'youtube': return `https://img.youtube.com/vi/${platform.id}/hqdefault.jpg`;
		case 'vimeo': return `https://vumbnail.com/${platform.id}.jpg`;
		default: return '';
	}
}

export function getEmbedUrl(platform, muted = true) {
	switch (platform.type) {
		case 'youtube':
			return `https://www.youtube.com/embed/${platform.id}?autoplay=1&mute=${muted ? 1 : 0}&controls=1&rel=0&modestbranding=1`;
		case 'vimeo':
			return `https://player.vimeo.com/video/${platform.id}?autoplay=1&muted=${muted ? 1 : 0}`;
		case 'twitch':
			return `https://player.twitch.tv/?channel=${platform.id}&autoplay=true&muted=${muted}&parent=${location.hostname}`;
		case 'twitch_clip':
			return `https://clips.twitch.tv/embed?clip=${platform.id}&autoplay=true&muted=${muted}&parent=${location.hostname}`;
		default:
			return null;
	}
}

export function getPlatformLabel(type) {
	const map = { youtube: 'yt', vimeo: 'vimeo', twitch: 'twitch', twitch_clip: 'twitch', mp4: 'mp4' };
	return map[type] || type;
}

export function getPlatformColor(type) {
	const map = {
		youtube: 'var(--red)',
		vimeo: 'var(--blue)',
		twitch: 'var(--purple)',
		twitch_clip: 'var(--purple)',
		mp4: 'var(--green)'
	};
	return map[type] || 'var(--muted)';
}
