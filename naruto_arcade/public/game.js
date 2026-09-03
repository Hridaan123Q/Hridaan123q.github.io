// Game Engine Setup
const canvas = document.getElementById('game-canvas');
const ctx = canvas.getContext('2d');
const GAME_WIDTH = canvas.width;
const GAME_HEIGHT = canvas.height;

// DOM Elements for UI
const titleScreen = document.getElementById('title-screen');
const charSelectScreen = document.getElementById('char-select-screen');
const hud = document.getElementById('hud');
const pauseScreen = document.getElementById('pause-screen');
const gameOverScreen = document.getElementById('game-over-screen');
const leaderboardScreen = document.getElementById('leaderboard-screen');

// HUD Elements
const hudScore = document.getElementById('hud-score');
const hudDistance = document.getElementById('hud-distance');
const hudLives = document.getElementById('hud-lives');
const hudShuriken = document.getElementById('hud-shuriken');
const hudJutsu = document.getElementById('hud-jutsu');
const finalScoreText = document.getElementById('final-score');

// Game State
let gameState = 'TITLE'; // TITLE, SELECT, PLAYING, PAUSED, GAMEOVER, LEADERBOARD
let animationId;
let frames = 0;
let score = 0;
let distance = 0;
let gameSpeed = 5;

// Input State
const keys = {
    ArrowUp: false,
    ArrowDown: false,
    Space: false, // Shuriken
    KeyZ: false,  // Jutsu
    Enter: false,
    KeyP: false
};

// Event Listeners for Input
window.addEventListener('keydown', (e) => {
    if (keys.hasOwnProperty(e.code)) keys[e.code] = true;

    // State transitions based on input
    if (e.code === 'Enter') {
        if (gameState === 'TITLE') switchState('SELECT');
        else if (gameState === 'SELECT') startGame();
        else if (gameState === 'GAMEOVER') {
            // Prevent restarting if the user is typing in the input field
            if (document.activeElement !== document.getElementById('player-name')) {
                switchState('TITLE');
            }
        }
    }
    if (e.code === 'KeyP') {
        if (gameState === 'PLAYING') switchState('PAUSED');
        else if (gameState === 'PAUSED') switchState('PLAYING');
    }
});

window.addEventListener('keyup', (e) => {
    if (keys.hasOwnProperty(e.code)) keys[e.code] = false;
});

// Character Selection Logic
const charCards = document.querySelectorAll('.char-card');
let selectedCharIndex = 0;
const characters = ['naruto', 'sasuke', 'sakura'];

function updateCharSelect() {
    charCards.forEach((card, idx) => {
        if (idx === selectedCharIndex) card.classList.add('selected');
        else card.classList.remove('selected');
    });
}

window.addEventListener('keydown', (e) => {
    if (gameState === 'SELECT') {
        if (e.code === 'ArrowRight') {
            selectedCharIndex = (selectedCharIndex + 1) % characters.length;
            updateCharSelect();
        } else if (e.code === 'ArrowLeft') {
            selectedCharIndex = (selectedCharIndex - 1 + characters.length) % characters.length;
            updateCharSelect();
        }
    }
});

// Buttons
document.getElementById('btn-leaderboard-view').addEventListener('click', () => switchState('LEADERBOARD'));
document.getElementById('btn-back-title').addEventListener('click', () => switchState('TITLE'));
document.getElementById('btn-submit-score').addEventListener('click', submitScore);


// --- Game Entities ---

class Player {
    constructor(charType) {
        this.charType = charType;
        this.width = 40;
        this.height = 60;
        this.x = 100;
        this.y = GAME_HEIGHT - 100 - this.height; // Above ground
        this.vy = 0;
        this.gravity = 0.6;
        this.jumpPower = -12;
        this.jumps = 0;
        this.maxJumps = 2;
        this.grounded = false;

        // Stats based on character
        this.shurikens = 10;
        this.lives = 3;
        this.jutsuCooldown = 0;
        this.maxJutsuCooldown = 300; // frames
        this.isInvincible = false;
        this.invincibleTimer = 0;

        // Set colors based on char (placeholder for sprites)
        if (charType === 'naruto') this.color = '#ff7b00';
        else if (charType === 'sasuke') this.color = '#0044ff';
        else if (charType === 'sakura') this.color = '#ff69b4';
    }

    update() {
        // Gravity
        this.vy += this.gravity;
        this.y += this.vy;

        // Ground Collision (Hardcoded floor at y = 500)
        if (this.y + this.height >= GAME_HEIGHT - 100) {
            this.y = GAME_HEIGHT - 100 - this.height;
            this.vy = 0;
            this.grounded = true;
            this.jumps = 0;
        } else {
            this.grounded = false;
        }

        // Jumping
        if (keys.ArrowUp && this.jumps < this.maxJumps && this.vy >= -this.jumpPower * 0.5) { // Simple debounce via velocity
            this.vy = this.jumpPower;
            this.jumps++;
            keys.ArrowUp = false; // Require release for next jump
        }

        // Attack (Shuriken)
        if (keys.Space && this.shurikens > 0) {
            projectiles.push(new Projectile(this.x + this.width, this.y + this.height/2));
            this.shurikens--;
            keys.Space = false;
        }

        // Jutsu (Special)
        if (keys.KeyZ && this.jutsuCooldown <= 0) {
            this.activateJutsu();
            this.jutsuCooldown = this.maxJutsuCooldown;
        }

        if (this.jutsuCooldown > 0) this.jutsuCooldown--;

        // Invincibility frames
        if (this.isInvincible) {
            this.invincibleTimer--;
            if (this.invincibleTimer <= 0) this.isInvincible = false;
        }
    }

    draw() {
        if (this.isInvincible && frames % 10 < 5) return; // Blink effect

        ctx.fillStyle = this.color;
        ctx.fillRect(this.x, this.y, this.width, this.height);

        // Draw simple eye band to look like a ninja
        ctx.fillStyle = '#111';
        ctx.fillRect(this.x + 20, this.y + 10, 20, 10);
    }

    activateJutsu() {
        if (this.charType === 'naruto') {
            // Shadow Clone: Screen clear + invincibility
            enemies = [];
            this.isInvincible = true;
            this.invincibleTimer = 90;
            score += 500;
            ctx.fillStyle = 'rgba(255, 123, 0, 0.5)'; // Orange flash
            ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
        } else if (this.charType === 'sasuke') {
            // Chidori Dash: Dash forward fast, destroy enemies
            this.isInvincible = true;
            this.invincibleTimer = 60;
            enemies.forEach(e => e.markedForDeletion = true);
            score += 600;
            ctx.fillStyle = 'rgba(0, 68, 255, 0.6)'; // Blue flash
            ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
            // Dash effect handled by logic (invincibility lets player run through)
        } else if (this.charType === 'sakura') {
            // Ground Smash: Destroy ground enemies + heal 1 life
            enemies.forEach(e => {
                if (e.y > GAME_HEIGHT - 200) e.markedForDeletion = true;
            });
            if (this.lives < 5) this.lives++; // Small heal
            score += 300;
            ctx.fillStyle = 'rgba(255, 105, 180, 0.5)'; // Pink flash
            ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
        }
    }
}

class Projectile {
    constructor(x, y) {
        this.x = x;
        this.y = y;
        this.width = 10;
        this.height = 10;
        this.speed = 10;
        this.markedForDeletion = false;
    }
    update() {
        this.x += this.speed;
        if (this.x > GAME_WIDTH) this.markedForDeletion = true;
    }
    draw() {
        ctx.fillStyle = '#ccc';
        ctx.save();
        ctx.translate(this.x + this.width/2, this.y + this.height/2);
        ctx.rotate(frames * 0.5); // Spin
        ctx.fillRect(-this.width/2, -this.height/2, this.width, this.height);
        ctx.restore();
    }
}

class Enemy {
    constructor() {
        this.width = 40;
        this.height = 50;
        this.x = GAME_WIDTH;
        this.y = GAME_HEIGHT - 100 - this.height;
        this.speed = gameSpeed + Math.random() * 2;
        this.markedForDeletion = false;
        this.color = '#ff003c'; // Red enemy
        this.hp = 1;
        this.isBoss = false;
    }
    update() {
        this.x -= this.speed;
        if (this.x + this.width < 0) this.markedForDeletion = true;
    }
    draw() {
        ctx.fillStyle = this.color;
        ctx.fillRect(this.x, this.y, this.width, this.height);
        // Evil eyes
        ctx.fillStyle = '#fff';
        ctx.fillRect(this.x + 5, this.y + 15, 8, 8);
        ctx.fillRect(this.x + 20, this.y + 15, 8, 8);
    }
}

class Boss extends Enemy {
    constructor() {
        super();
        this.width = 80;
        this.height = 100;
        this.x = GAME_WIDTH;
        this.y = GAME_HEIGHT - 100 - this.height;
        this.speed = gameSpeed * 0.5; // Slower
        this.color = '#800080'; // Purple boss
        this.hp = 10;
        this.isBoss = true;
    }
    draw() {
        ctx.fillStyle = this.color;
        ctx.fillRect(this.x, this.y, this.width, this.height);
        // Scary eyes
        ctx.fillStyle = '#ff0';
        ctx.fillRect(this.x + 10, this.y + 20, 15, 10);
        ctx.fillRect(this.x + 50, this.y + 20, 15, 10);

        // HP Bar
        ctx.fillStyle = '#f00';
        ctx.fillRect(this.x, this.y - 15, this.width * (this.hp / 10), 5);
    }
}

class Platform {
    constructor(x, width) {
        this.x = x;
        this.y = GAME_HEIGHT - 100;
        this.width = width;
        this.height = 100;
    }
    update() {
        this.x -= gameSpeed;
    }
    draw() {
        ctx.fillStyle = '#333';
        ctx.fillRect(this.x, this.y, this.width, this.height);
        // Top edge
        ctx.fillStyle = '#555';
        ctx.fillRect(this.x, this.y, this.width, 10);
    }
}

// --- Game Variables ---
let player;
let projectiles = [];
let enemies = [];
let platforms = [];

// --- Core Game Functions ---

function initGame() {
    player = new Player(characters[selectedCharIndex]);
    projectiles = [];
    enemies = [];
    platforms = [new Platform(0, GAME_WIDTH + 200)];
    score = 0;
    distance = 0;
    frames = 0;
    gameSpeed = 5;
}

function startGame() {
    initGame();
    switchState('PLAYING');
    loop();
}

function switchState(newState) {
    // Hide all
    [titleScreen, charSelectScreen, hud, pauseScreen, gameOverScreen, leaderboardScreen].forEach(el => el.classList.add('hidden'));

    gameState = newState;

    if (newState === 'TITLE') {
        titleScreen.classList.remove('hidden');
        updateCharSelect(); // Initialize selection visually
    } else if (newState === 'SELECT') {
        charSelectScreen.classList.remove('hidden');
    } else if (newState === 'PLAYING') {
        hud.classList.remove('hidden');
    } else if (newState === 'PAUSED') {
        hud.classList.remove('hidden');
        pauseScreen.classList.remove('hidden');
    } else if (newState === 'GAMEOVER') {
        hud.classList.remove('hidden');
        gameOverScreen.classList.remove('hidden');
        finalScoreText.innerText = `SCORE: ${Math.floor(score)}`;
    } else if (newState === 'LEADERBOARD') {
        leaderboardScreen.classList.remove('hidden');
        fetchLeaderboard();
    }
}

function handleCollisions() {
    // Projectiles hit Enemies
    projectiles.forEach(p => {
        enemies.forEach(e => {
            if (p.x < e.x + e.width && p.x + p.width > e.x && p.y < e.y + e.height && p.y + p.height > e.y) {
                p.markedForDeletion = true;
                e.hp--;
                if (e.hp <= 0) {
                    e.markedForDeletion = true;
                    score += e.isBoss ? 1000 : 100;
                }
            }
        });
    });

    // Player hits Enemies
    if (!player.isInvincible) {
        enemies.forEach(e => {
            if (player.x < e.x + e.width && player.x + player.width > e.x && player.y < e.y + e.height && player.y + player.height > e.y) {
                player.lives--;
                e.markedForDeletion = true;
                player.isInvincible = true;
                player.invincibleTimer = 60;

                if (player.lives <= 0) {
                    switchState('GAMEOVER');
                }
            }
        });
    }
}

function manageSpawns() {
    // Infinite Platforms (simple scrolling floor)
    let lastPlatform = platforms[platforms.length - 1];
    if (lastPlatform.x + lastPlatform.width < GAME_WIDTH + 200) {
        platforms.push(new Platform(lastPlatform.x + lastPlatform.width, 500));
    }
    if (platforms[0].x + platforms[0].width < 0) platforms.shift();

    // Spawn Enemies and Bosses
    if (frames > 0 && frames % 1000 === 0) {
        enemies.push(new Boss()); // Spawn boss every 1000 frames
    } else if (frames % 120 === 0) {
        // Only spawn normal enemy if no boss is on screen to keep it fair
        if (!enemies.some(e => e.isBoss)) {
            enemies.push(new Enemy());
        }
    }

    // Periodically give shurikens
    if (frames % 300 === 0 && player.shurikens < 20) {
        player.shurikens += 3;
    }
}

function updateHUD() {
    hudScore.innerText = `SCORE: ${Math.floor(score)}`;
    hudDistance.innerText = `DIST: ${Math.floor(distance)}m`;
    hudLives.innerText = `LIVES: ${player.lives}`;
    hudShuriken.innerText = `SHURIKEN: ${player.shurikens}`;

    if (player.jutsuCooldown <= 0) {
        hudJutsu.innerText = `JUTSU: READY`;
        hudJutsu.style.color = '#fff';
    } else {
        hudJutsu.innerText = `JUTSU: ${Math.ceil(player.jutsuCooldown/60)}s`;
        hudJutsu.style.color = '#555';
    }
}

function drawBackground() {
    // Clear canvas
    ctx.fillStyle = '#0d0e15';
    ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);

    // Draw simple parallax moon/sun
    ctx.fillStyle = 'rgba(255, 123, 0, 0.2)';
    ctx.beginPath();
    ctx.arc(GAME_WIDTH - 150, 150, 80, 0, Math.PI * 2);
    ctx.fill();
}

function loop() {
    if (gameState !== 'PLAYING') {
        if (gameState === 'PAUSED') requestAnimationFrame(loop); // Keep loop alive but don't update logic
        return;
    }

    // Update logic
    player.update();
    projectiles.forEach(p => p.update());
    enemies.forEach(e => e.update());
    platforms.forEach(p => p.update());

    // Clean up
    projectiles = projectiles.filter(p => !p.markedForDeletion);
    enemies = enemies.filter(e => !e.markedForDeletion);

    handleCollisions();
    manageSpawns();

    // Difficulty scaling
    distance += gameSpeed * 0.05;
    score += 0.1;
    if (frames % 600 === 0) gameSpeed += 0.5;

    updateHUD();

    // Render
    drawBackground();
    platforms.forEach(p => p.draw());
    enemies.forEach(e => e.draw());
    projectiles.forEach(p => p.draw());
    player.draw();

    frames++;
    animationId = requestAnimationFrame(loop);
}


// --- API Integrations ---

async function fetchLeaderboard() {
    const list = document.getElementById('leaderboard-list');
    list.innerHTML = '<li>LOADING...</li>';
    try {
        const response = await fetch('/api/leaderboard');
        const data = await response.json();
        list.innerHTML = '';
        if (data.length === 0) {
            list.innerHTML = '<li>NO SCORES YET</li>';
            return;
        }
        data.forEach((entry, i) => {
            const li = document.createElement('li');
            const spanName = document.createElement('span');
            spanName.textContent = `${i + 1}. ${entry.name}`;
            const spanScore = document.createElement('span');
            spanScore.textContent = entry.score;

            li.appendChild(spanName);
            li.appendChild(spanScore);
            list.appendChild(li);
        });
    } catch (err) {
        list.innerHTML = '<li>ERROR LOADING SCORES</li>';
    }
}

async function submitScore() {
    const nameInput = document.getElementById('player-name');
    let name = nameInput.value.trim();
    if (!name) name = "NINJA";

    const btn = document.getElementById('btn-submit-score');
    btn.disabled = true;
    btn.innerText = "SAVING...";

    try {
        await fetch('/api/leaderboard', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: name, score: Math.floor(score) })
        });

        switchState('LEADERBOARD');
    } catch (err) {
        console.error("Failed to submit score", err);
        alert("Failed to save score!");
    } finally {
        btn.disabled = false;
        btn.innerText = "SUBMIT";
    }
}


// Start application at Title
switchState('TITLE');
