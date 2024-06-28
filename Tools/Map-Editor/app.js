document.getElementById('fileInput').addEventListener('change', handleFileSelect, false);

function handleFileSelect(event) {
    const file = event.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const mapData = JSON.parse(e.target.result);
            drawMap(mapData);
        };
        reader.readAsText(file);
    }
}

function drawMap(mapData) {
    const canvas = document.getElementById('mapCanvas');
    const ctx = canvas.getContext('2d');
    const cellSize = 10;
    const offsetX = 300; // To center the map
    const offsetY = 300; // To center the map

    // Function to map height to color
    function heightToColor(height) {
        const minColor = {r: 0, g: 0, b: 255}; // Blue for lowest
        const maxColor = {r: 255, g: 255, b: 255}; // White for highest
        const heightRange = 10; // Adjust based on your data range

        let t = (height + heightRange) / (2 * heightRange); // Normalize height to 0-1
        t = Math.max(0, Math.min(1, t)); // Clamp between 0 and 1

        const r = minColor.r + t * (maxColor.r - minColor.r);
        const g = minColor.g + t * (maxColor.g - minColor.g);
        const b = minColor.b + t * (maxColor.b - minColor.b);

        return `rgb(${Math.round(r)}, ${Math.round(g)}, ${Math.round(b)})`;
    }

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw map
    for (let coord in mapData) {
        if (mapData.hasOwnProperty(coord)) {
            const data = mapData[coord];
            const [x, y] = coord.slice(1, -1).split(', ').map(Number);
            const screenX = x * cellSize + offsetX;
            const screenY = y * cellSize + offsetY;
            const height = data.height;

            // Draw cell
            ctx.fillStyle = heightToColor(height);
            ctx.fillRect(screenX, screenY, cellSize, cellSize);

            // Draw tree if present
            if (data.entity === "ASH_TREE") {
                ctx.fillStyle = 'green';
                ctx.beginPath();
                ctx.moveTo(screenX + cellSize / 2, screenY);
                ctx.lineTo(screenX + cellSize, screenY + cellSize);
                ctx.lineTo(screenX, screenY + cellSize);
                ctx.closePath();
                ctx.fill();
            }
        }
    }

    // Add event listener to show coordinates on hover
    canvas.addEventListener('mousemove', function(event) {
        const rect = canvas.getBoundingClientRect();
        const mouseX = event.clientX - rect.left;
        const mouseY = event.clientY - rect.top;

        const gridX = Math.floor((mouseX - offsetX) / cellSize);
        const gridY = Math.floor((mouseY - offsetY) / cellSize);

        const mapCoord = `(${gridX}, ${gridY})`;

        if (mapCoord in mapData) {
            document.getElementById('coordinates').innerText = `Coordinate: ${mapCoord}`;
        } else {
            document.getElementById('coordinates').innerText = `Hover over a tile to see the coordinates`;
        }
    });
}