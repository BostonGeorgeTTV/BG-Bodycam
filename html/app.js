const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'bg_bodycam';
const bodycam = document.getElementById('bodycam');
const titleEl = document.getElementById('title');
const modelEl = document.getElementById('model');
const logoEl = document.getElementById('logo');
const recordDot = document.getElementById('recordDot');
const departmentEl = document.getElementById('department');
const playerNameEl = document.getElementById('playerName');
const jobLabelEl = document.getElementById('jobLabel');
const gradeLabelEl = document.getElementById('gradeLabel');
const clockEl = document.getElementById('clock');

let visible = false;
let editing = false;
let dragging = false;
let dragOffset = { x: 0, y: 0 };
let timeConfig = {
    locale: 'it-IT',
    hour12: false,
    showDate: true,
    showSeconds: true
};

const fetchNui = (eventName, data = {}) => {
    return fetch(`https://${resourceName}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(() => undefined);
};

const setText = (element, value, fallback = '') => {
    if (!element) return;
    element.textContent = value || fallback;
};

const clearPosition = () => {
    bodycam.style.top = '';
    bodycam.style.right = '';
    bodycam.style.bottom = '';
    bodycam.style.left = '';
};

const applyPosition = (position = {}) => {
    clearPosition();

    if (typeof position.left === 'number' || typeof position.top === 'number') {
        bodycam.style.left = `${position.left || 0}px`;
        bodycam.style.top = `${position.top || 0}px`;
        return;
    }

    bodycam.style.top = position.top || '6.5vh';
    bodycam.style.right = position.right || '2vw';

    if (position.left) bodycam.style.left = position.left;
    if (position.bottom) bodycam.style.bottom = position.bottom;
};

const getCurrentPosition = () => {
    const rect = bodycam.getBoundingClientRect();
    return {
        left: Math.max(0, Math.round(rect.left)),
        top: Math.max(0, Math.round(rect.top))
    };
};

const saveCurrentPosition = () => {
    fetchNui('savePosition', { position: getCurrentPosition() });
};

const updateClock = () => {
    if (!visible) return;

    const options = {
        hour: '2-digit',
        minute: '2-digit',
        hour12: Boolean(timeConfig.hour12)
    };

    if (timeConfig.showSeconds) {
        options.second = '2-digit';
    }

    if (timeConfig.showDate) {
        options.day = '2-digit';
        options.month = '2-digit';
        options.year = 'numeric';
    }

    clockEl.textContent = new Intl.DateTimeFormat(timeConfig.locale || 'it-IT', options).format(new Date());
};

const resolveLogoPath = (path) => {
    if (!path) return '';
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('nui://')) return path;
    return path;
};

const applyPayload = (payload) => {
    if (payload.time) {
        timeConfig = { ...timeConfig, ...payload.time };
    }

    if (payload.scale) {
        bodycam.style.setProperty('--scale', payload.scale);
        bodycam.style.transform = `scale(${payload.scale})`;
    }

    if (payload.position) {
        applyPosition(payload.position);
    }

    setText(titleEl, payload.title, 'BODYCAM');
    setText(modelEl, payload.model, 'BG-CAM X1');

    const player = payload.player || {};
    setText(departmentEl, player.department, 'BODY WORN CAMERA');
    setText(playerNameEl, player.name, 'Sconosciuto');
    setText(jobLabelEl, player.jobLabel, 'JOB');
    setText(gradeLabelEl, player.gradeLabel, 'N/D');

    if (payload.showLogo === false || !player.logo) {
        logoEl.classList.add('is-hidden');
        logoEl.removeAttribute('src');
    } else {
        logoEl.classList.remove('is-hidden');
        logoEl.src = resolveLogoPath(player.logo);
    }

    if (payload.showRecordingDot === false) {
        recordDot.classList.add('is-hidden');
    } else {
        recordDot.classList.remove('is-hidden');
    }

    updateClock();
};

const setVisible = (state) => {
    visible = state;
    bodycam.classList.toggle('hidden', !visible);
    bodycam.setAttribute('aria-hidden', String(!visible));
};

const setEditing = (state) => {
    editing = state;
    bodycam.classList.toggle('editing', editing);
    document.body.style.pointerEvents = editing ? 'auto' : 'none';
};

window.addEventListener('message', (event) => {
    const payload = event.data || {};

    if (payload.action === 'show') {
        applyPayload(payload);
        setVisible(true);
        return;
    }

    if (payload.action === 'hide') {
        setVisible(false);
        setEditing(false);
        return;
    }

    if (payload.action === 'update') {
        applyPayload(payload);
        return;
    }

    if (payload.action === 'editMode') {
        setEditing(Boolean(payload.enabled));
        return;
    }

    if (payload.action === 'resetPosition') {
        applyPosition(payload.position || {});
        saveCurrentPosition();
        return;
    }

    if (payload.action === 'hydrate') {
        if (payload.time) timeConfig = { ...timeConfig, ...payload.time };
        if (payload.position) applyPosition(payload.position);
    }
});

bodycam.addEventListener('mousedown', (event) => {
    if (!editing) return;

    dragging = true;
    const rect = bodycam.getBoundingClientRect();
    dragOffset.x = event.clientX - rect.left;
    dragOffset.y = event.clientY - rect.top;
});

window.addEventListener('mousemove', (event) => {
    if (!dragging || !editing) return;

    const width = bodycam.offsetWidth;
    const height = bodycam.offsetHeight;
    const left = Math.min(window.innerWidth - width, Math.max(0, event.clientX - dragOffset.x));
    const top = Math.min(window.innerHeight - height, Math.max(0, event.clientY - dragOffset.y));

    clearPosition();
    bodycam.style.left = `${left}px`;
    bodycam.style.top = `${top}px`;
});

window.addEventListener('mouseup', () => {
    if (!dragging) return;
    dragging = false;
    saveCurrentPosition();
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && editing) {
        fetchNui('closeEdit');
    }
});

setInterval(updateClock, 1000);
fetchNui('ready');
