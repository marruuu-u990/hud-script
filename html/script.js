window.addEventListener('load', function() {
    cargarPosicionHUD();
});

// ── Elementos HUD ───────────────────────────────────────────────
var hud         = document.getElementById('hud');
var velNum      = document.getElementById('vel-num');
var fuelFill    = document.getElementById('fuel-fill');
var fuelPct     = document.getElementById('fuel-pct');
var rpmFill     = document.getElementById('rpm-fill');
var marchNum    = document.getElementById('marcha-num');
var cruceroTag  = document.getElementById('crucero-tag');
var cruceroVel  = document.getElementById('crucero-vel');
var lowFuelTag  = document.getElementById('low-fuel-tag');
var indCinturon = document.getElementById('ind-cinturon');
var indLuces    = document.getElementById('ind-luces');
var indAltas    = document.getElementById('ind-altas');
var indIzq      = document.getElementById('ind-izq');
var indDer      = document.getElementById('ind-der');
var indMotor    = document.getElementById('ind-motor');

// ── Elementos overlay gasolinera ────────────────────────────────
var fuelOverlay  = document.getElementById('fuel-overlay');
var foNombre     = document.getElementById('fo-nombre');
var foLitrosAct  = document.getElementById('fo-litros-act');
var foPrecio     = document.getElementById('fo-precio');
var foBarraFill  = document.getElementById('fo-barra-fill');

// ── Estado ──────────────────────────────────────────────────────
var editMode     = false;
var dragging     = false;
var dragOX       = 0;
var dragOY       = 0;
var precioTotal  = 0;
var litrosTotal  = 0;

// ── Helpers ─────────────────────────────────────────────────────
function setInd(el, activo, clase) {
    el.className = 'ind ' + (activo ? clase : '');
}

// ── Posicion del HUD ─────────────────────────────────────────────
function cargarPosicionHUD() {
    var x = localStorage.getItem('vr_hud_x');
    var y = localStorage.getItem('vr_hud_y');
    if (x !== null && y !== null) {
        hud.style.left      = x;
        hud.style.top       = y;
        hud.style.bottom    = 'auto';
        hud.style.transform = 'none';
    }
}

function guardarPosicionHUD() {
    localStorage.setItem('vr_hud_x', hud.style.left);
    localStorage.setItem('vr_hud_y', hud.style.top);
}

// ── Drag logic ───────────────────────────────────────────────────
hud.addEventListener('mousedown', function(e) {
    if (!editMode) return;
    dragging = true;
    var rect = hud.getBoundingClientRect();
    dragOX = e.clientX - rect.left;
    dragOY = e.clientY - rect.top;
    e.preventDefault();
});

document.addEventListener('mousemove', function(e) {
    if (!dragging) return;
    hud.style.left      = (e.clientX - dragOX) + 'px';
    hud.style.top       = (e.clientY - dragOY) + 'px';
    hud.style.bottom    = 'auto';
    hud.style.transform = 'none';
});

document.addEventListener('mouseup', function() {
    if (dragging) {
        dragging = false;
        guardarPosicionHUD();
    }
});

// ESC cierra edit mode
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && editMode) {
        editMode = false;
        hud.classList.remove('editable');
        guardarPosicionHUD();
        fetch('https://velocidad_real/cerrarEditMode', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        });
    }
});

// ── Mensajes desde Lua ───────────────────────────────────────────
window.addEventListener('message', function(e) {
    var d = e.data;

    if (d.action === 'mostrar') {
        hud.classList.remove('oculto');
        indCinturon.className = 'ind apagado';
        return;
    }

    if (d.action === 'ocultar') {
        hud.classList.add('oculto');
        cruceroTag.classList.add('oculto');
        lowFuelTag.classList.add('oculto');
        return;
    }

    if (d.action === 'editMode') {
        editMode = d.activo;
        if (d.activo) {
            hud.classList.add('editable');
        } else {
            hud.classList.remove('editable');
        }
        return;
    }

    if (d.action === 'cinturon') {
        indCinturon.className = 'ind ' + (d.estado ? 'encendido' : 'apagado');
        return;
    }

    if (d.action === 'crucero') {
        if (d.estado) {
            cruceroVel.textContent = d.speed;
            cruceroTag.classList.remove('oculto');
        } else {
            cruceroTag.classList.add('oculto');
        }
        return;
    }

    // ── Overlay gasolinera ───────────────────────────────────────
    if (d.action === 'iniciarRecarga') {
        litrosTotal  = d.litros;
        precioTotal  = d.precio;
        foNombre.textContent    = d.nombre.toUpperCase();
        foLitrosAct.textContent = '0.0 L';
        foPrecio.textContent    = '$0.00';
        foBarraFill.style.width = '0%';
        fuelOverlay.classList.remove('oculto');
        return;
    }

    if (d.action === 'progresoRecarga') {
        var pct    = d.pct || 0;
        var litros = d.litrosAct || 0;
        var precio = (pct * precioTotal).toFixed(2);
        foLitrosAct.textContent = litros.toFixed(1) + ' L';
        foPrecio.textContent    = '$' + precio;
        foBarraFill.style.width = Math.min(pct * 100, 100) + '%';
        return;
    }

    if (d.action === 'finRecarga') {
        foLitrosAct.textContent = litrosTotal.toFixed(1) + ' L';
        foPrecio.textContent    = '$' + precioTotal.toFixed(2);
        foBarraFill.style.width = '100%';
        setTimeout(function() { fuelOverlay.classList.add('oculto'); }, 1500);
        return;
    }

    // ── Update principal ─────────────────────────────────────────
    if (d.action === 'actualizar') {
        velNum.textContent   = d.speed;
        marchNum.textContent = d.gear;

        var fp = Math.max(0, Math.min(d.fuel, 100));
        fuelFill.style.width      = fp + '%';
        fuelPct.textContent       = fp + '%';
        fuelFill.style.background = fp > 50 ? '#4ade80' : fp > 20 ? '#fb923c' : '#f87171';

        var rp = Math.min(d.rpm * 100, 100);
        rpmFill.style.width      = rp + '%';
        rpmFill.style.background = rp >= 80 ? '#f87171' : '#d4d4d4';

        setInd(indLuces, d.luces,      'on');
        setInd(indAltas, d.altas,      'on');
        setInd(indIzq,   d.blinkerIzq, 'on');
        setInd(indDer,   d.blinkerDer, 'on');
        setInd(indMotor, d.motor,      'on');

        if (d.lowFuel) {
            lowFuelTag.classList.remove('oculto');
        } else {
            lowFuelTag.classList.add('oculto');
        }
    }
});
