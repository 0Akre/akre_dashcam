window.addEventListener('message', function(event) {
    if (event.data.action === 'openMenu') {
        document.getElementById('vehicle-list').innerHTML = '';
        event.data.vehicles.forEach(vehicle => {
            let li = document.createElement('li');
            li.className = 'vehicle-item';
            li.textContent = `Vehicle Plate: ${vehicle.plate}`;
            let btn = document.createElement('button');
            btn.textContent = 'VIEW';
            btn.addEventListener('click', function() {
                fetch(`https://${GetParentResourceName()}/viewCamera`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ netId: vehicle.netId })
                });
                document.getElementById('vehicle-plate').textContent = `Plate: [${vehicle.plate}]`;
                document.getElementById('dashcam-code').textContent = `Dashcam Code: ${generateRandomCode()}`;
                document.getElementById('vehicle-info').style.display = 'block';
                document.getElementById('dashcam-help').textContent = `Right Click for EXIT`;
                updateDateTime();
            });
            li.appendChild(btn);
            document.getElementById('vehicle-list').appendChild(li);
        });
        document.getElementById('menu').style.display = 'block';
    } else if (event.data.action === 'preloading') {
        document.getElementById('preloading').style.display = 'block';
    } else if (event.data.action === 'hidePreloading') {
        document.getElementById('preloading').style.display = 'none';
    } else if (event.data.action === 'disconnecting') {
        document.getElementById('disconnecting').style.display = 'block';
    } else if (event.data.action === 'hideDisconnecting') {
        document.getElementById('disconnecting').style.display = 'none';
    } else if (event.data.action === 'updateStatus') {
        const sirens = event.data.sirens ? 'green' : 'white';
        const handbrake = event.data.handbrake ? 'red' : 'white';

        const sirensElement = document.getElementById('status-sirens');
        sirensElement.style.color = sirens;

        if (event.data.sirens) {
            sirensElement.classList.add('blinking');
        } else {
            sirensElement.classList.remove('blinking');
        }

        document.getElementById('status-handbrake').style.color = handbrake;
    } else if (event.data.action === 'showStatus') {
        document.getElementById('status').style.display = 'flex';
    } else if (event.data.action === 'hideStatus') {
        document.getElementById('status').style.display = 'none';
    } else if (event.data.action === 'showVehicleInfo') {
        document.getElementById('vehicle-info').style.display = 'block';
    } else if (event.data.action === 'hideVehicleInfo') {
        document.getElementById('vehicle-info').style.display = 'none';
    }
});

document.getElementById('close-btn').addEventListener('click', function() {
    closeMenu();
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeMenu();
    }
});

function closeMenu() {
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST'
    });
    document.getElementById('menu').style.display = 'none';
}

function generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    const usedChars = new Set();
    while (code.length < 12) {
        const char = chars.charAt(Math.floor(Math.random() * chars.length));
        if (!usedChars.has(char)) {
            code += char;
            usedChars.add(char);
        }
    }
    return code;
}

function updateDateTime() {
    setInterval(() => {
        const now = new Date();
        document.getElementById('current-datetime').textContent = `Date & Time: ${now.toLocaleString()}`;
    }, 1000);
}