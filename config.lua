Config = {}

-- ── PRECIOS ────────────────────────────────────────────────────────────────
Config.PrecioPorLitro   = 3.5    -- $ por litro

-- ── COMBUSTIBLE ───────────────────────────────────────────────────────────
Config.MaxCombustible   = 100.0  -- nivel maximo del tanque
Config.NivelAdvertencia = 15.0   -- aviso de poco combustible
Config.NivelCritico     = 2.0    -- motor se apaga

-- Consumo por segundo segun velocidad
-- Ejemplo: a 100 km/h: 0.02 + (100 * 0.001) = 0.12 / seg
Config.ConsumoPorSegundo   = 0.02
Config.ConsumoPorVelocidad = 0.001

-- Velocidad de recarga: ms por litro
Config.MsPorLitro = 800

-- ── POSICIONES DE LAS BOMBAS ───────────────────────────────────────────────
-- Puedes agregar mas coordenadas segun tu servidor
Config.Bombas = {
    { coords = vector3(265.52,    -1261.42, 29.29),  nombre = "LTD Strawberry" },
    { coords = vector3(49.42,     -1767.72, 29.42),  nombre = "RON Elgin Ave" },
    { coords = vector3(-526.44,   -1213.36, 18.18),  nombre = "LTD Chamberlain" },
    { coords = vector3(-721.13,   -935.12,  19.22),  nombre = "RON Strawberry" },
    { coords = vector3(-1797.67,  793.36,  138.06),  nombre = "LTD Rockford" },
    { coords = vector3(-1438.50,  -276.06,  46.50),  nombre = "RON Morningwood" },
    { coords = vector3(1183.65,   -335.14,  69.30),  nombre = "LTD Vinewood" },
    { coords = vector3(817.72,    -1029.85, 26.20),  nombre = "RON La Mesa" },
    { coords = vector3(1699.17,   3250.84,  41.15),  nombre = "LTD Sandy Shores" },
    { coords = vector3(2005.48,   3773.57,  32.40),  nombre = "RON Tataviam" },
    { coords = vector3(913.11,    -150.14,  78.72),  nombre = "LTD Route 68" },
    { coords = vector3(-2553.19,  2334.37,  33.07),  nombre = "RON Paleto Bay" },
    { coords = vector3(-700.05,   5817.01,  17.34),  nombre = "LTD Braddock" },
    { coords = vector3(-88.97,    6419.22,  31.50),  nombre = "RON Paleto Norte" },
    { coords = vector3(-2095.19,  -320.04,  13.17),  nombre = "LTD Pacific Bluffs" },
}
