// ********************************* CONSTANTS ********************************* // 
//
//
//
//
//
// ***************************************************************************** //

// Simplex noise constants
const F = 768614336404564650n
const G = 384307168202282325n
const R_SQUARED = 1383505805528216371n
const ONE = BigInt(2**61)

// Perlin noise constants
const HALF_SQRT = 1630477227105714176n

//Gradient generation
const gradients = [
    [ONE,ONE,0n],
    [-ONE,ONE,0n],
    [ONE,-ONE,0n],
    [-ONE,-ONE,0n],
    [ONE,0n,ONE],
    [-ONE,0n,ONE],
    [ONE,0n,-ONE],
    [-ONE,0n,-ONE],
    [0n,ONE,ONE],
    [0n,-ONE,ONE],
    [0n,ONE,-ONE],
    [0n,-ONE,-ONE]
]

const perlinGradients = [
    [-HALF_SQRT, -HALF_SQRT],
    [-HALF_SQRT, HALF_SQRT],
    [HALF_SQRT, -HALF_SQRT],
    [HALF_SQRT, HALF_SQRT],
    [0n, ONE],
    [ONE, 0n],
    [0n, -ONE],
    [-ONE, 0n]
]

const p = [
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
    8,99,37,240,21,10,23,190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,
    117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,
    71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,
    55,46,245,40,244,102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,
    18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,
    250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,
    28,42,223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,
    9,129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
    251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
    49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
]

// Procedural generation constants
const UNINITIALIZED = 0;
const AIR = 1;
const STONE = 2;
const DIRT = 3;
const GRASS = 4;
const ORE = 5; 
const WOOD = 6;
const LEAF = 7;

// Defining the weight of each octave (64.61 format)
const HEIGHTMAP_OCTAVE1_W = 1152921504606846976n  // 0.5
const HEIGHTMAP_OCTAVE2_W = 691752902764108185n  // 0.3
const HEIGHTMAP_OCTAVE3_W = 461168601842738790n  // 0.2

// Defining the scale of each octave (side-lengths of the grid squares)
const HEIGHTMAP_OCTAVE1_S = 300n
const HEIGHTMAP_OCTAVE2_S = 100n
const HEIGHTMAP_OCTAVE3_S = 50n

// At an amplitude of 70, the difference in height between the lowest point on the surface of the terrain and the tallest is approximately 100.
// This is because the perlin noise function outputs a maximum value of ~0.7071 and a minimum value of about -0.7071
const SURFACE_AMPLITUDE = 70n
const SURFACE_BASELINE = 100n * ONE  // At a baseline of 100 and amplitude of 50, the tallest block generated can have a height of 150.

// How many blocks below the surface the soil goes before stone is reached
const TOPSOIL_BASELINE = 8n * ONE

// Maximum displacement (in either direction) of the baseline.
const TOPSOIL_AMPLITUDE = 5n

// Scale factor to be used in noise function for soil
const TOPSOIL_SCALE = 50n

// Defining the weight of each octave (64.61 format)
const CAVE_OCTAVE1_W = 1152921504606846976n // 0.5
const CAVE_OCTAVE2_W = 691752902764108185n // 0.3
const CAVE_OCTAVE3_W = 461168601842738790n  // 0.2

// Defining the scale of each octave (side-lengths of the grid squares)
const CAVE_OCTAVE1_S = 20n
const CAVE_OCTAVE2_S = 10n
const CAVE_OCTAVE3_S = 5n

// A Fractal noise value above this value means no block is there, otherwise a block is there. 
const CAVE_THRESHOLD = 161409010644958576n // 0.07


// ********************************* MAIN ********************************* // 
//
//
//
//
//
// *********************************************************************** //
console.log("\nAlong x-axis");
for (let i = 0n; i < 20n; i++) {
    console.log(Number(noise3DCustom(100n - i,100n,100n, 100n, 69n))/Number(ONE));
}

console.log("\nAlong x-axis - perlin");
for (let i = 0n; i < 20n; i++) {
    console.log(Number(noise2DCustom(150n - i,150n, 100n, 69n))/Number(ONE));
}

console.log("generator");
for (let i = 0n; i < 20n; i++) {
    console.log(generateBlock(50n, 50n, 80n + i));
}
/*
console.log("\nAlong y-axis");
for (let i = 0; i < 20; i++) {
    console.log(noise3DCustom(100,100 + i,100, 100, 69)/ONE);
}

console.log("\nAlong z-axis");
for (let i = 0; i < 20; i++) {
    console.log(noise3DCustom(100,100 + i,100 + i, 100, 69)/ONE);
}*/

// ********************************* PROCEDURAL TERRAIN GENERATION ********************************* // 
//
//
//
//
//
// *********************************************************************** //

function generateBlock(x,y,z) {
    let noise1 = noise2DCustom(x, y, HEIGHTMAP_OCTAVE1_S, 69)
    let noise2 = noise2DCustom(x, y, HEIGHTMAP_OCTAVE2_S, 420)
    let noise3 = noise2DCustom(x, y, HEIGHTMAP_OCTAVE3_S, 42069)

    let octave1 = mul(noise1, HEIGHTMAP_OCTAVE1_W)
    let octave2 = mul(noise2, HEIGHTMAP_OCTAVE2_W)
    let octave3 = mul(noise3, HEIGHTMAP_OCTAVE3_W)

    let surfaceHeight = from64x61(SURFACE_AMPLITUDE * (octave1 + octave2 + octave3) + SURFACE_BASELINE)

    if (z == surfaceHeight) {
        return GRASS;
    } else if (z < surfaceHeight) {
        let soilDisplacementNoise = noise2DCustom(x,y, TOPSOIL_SCALE);
        let soilDepth = from64x61(TOPSOIL_BASELINE + TOPSOIL_AMPLITUDE * soilDisplacementNoise);

        if (surfaceHeight - soilDepth <= z) {
            return DIRT;

        } else {
            let noise1 = noise3DCustom(x,y,z, CAVE_OCTAVE1_S, 69);
            let noise2 = noise3DCustom(x,y,z, CAVE_OCTAVE2_S, 420);
            let noise3 = noise3DCustom(x,y,z, CAVE_OCTAVE2_S, 42069);

            let octave1 = mul(noise1, CAVE_OCTAVE1_W);
            let octave2 = mul(noise2, CAVE_OCTAVE2_W);
            let octave3 = mul(noise3, CAVE_OCTAVE3_W);

            let sum = octave1 + octave2 + octave3;
            if (CAVE_THRESHOLD <= sum) {
                return AIR;
            } else {
                let isOre = perlinRandNum(x,y,z) % 8;
                if (isOre) {
                    return STONE;
                } else {
                    return ORE;
                }
            }
        }
    } else {
        return AIR;
    }
}



// ********************************* PERLIN NOISE ********************************* // 
//
//
//
//
//
// ******************************************************************************** //

function perlinDot(a, b) {
    return mul(a[0], b[0]) + mul(a[1], b[1]);
}

function perlinRandNum(a,b,c) {
    let temp1 = a % 256;
    let p1 = p[temp1];
    let temp2 = (b + p1) % 256;
    let p2 = p[temp2];
    let temp3 = (c + p2) % 256;
    return p[temp3];
}

function selectGradientPerlin(x, y, seed) {
    return perlinGradients[perlinRandNum(x,y, seed) % 8];
}

function getNearestGridline(coord, scale) {
    let scaledCoord = coord / scale;
    return to64x61(scaledCoord);
}

function vecToVec64x61(vec) {
    return [to64x61(vec[0]), to64x61(vec[1])];
}

function scaleVec(vec, scale) {
    return [div(vec[0], scale), div(vec[1], scale)];
}

function getOffsetVec(a, b) {
    return [a[0] - b[0], a[1] - b[1]];
}

function linterp(a, b, t) {
    let diff = a - b;
    let weightedDiff = mul(diff, t);
    return a + weightedDiff;
}

function fadeFunc(x) {
    let xSquared = mul(x,x);
    let xCubed = mul(xSquared,x);
    return 6n*mul(xSquared,xCubed) - 15n*mul(xSquared,xSquared) + 10n*xCubed;
}

function noise2DCustom(x, y, scale, seed) {
    let scale64x61 = to64x61(scale);

    let x64x61 = to64x61(x);
    let y64x61 = to64x61(y);

    let xScaled = div(to64x61(x), scale64x61);
    let yScaled = div(to64x61(y), scale64x61);
    let pointScaled = [xScaled, yScaled];

    let lowerX = getNearestGridline(x, scale);
    let lowerY = getNearestGridline(y, scale);

    let upperX = lowerX + ONE;
    let upperY = lowerY + ONE;

    let lowXLowYGradient = selectGradientPerlin(Number(lowerX), Number(lowerY), Number(seed));
    let lowXUppYGradient = selectGradientPerlin(Number(lowerX), Number(upperY), Number(seed));
    let uppXLowYGradient = selectGradientPerlin(Number(upperX), Number(lowerY), Number(seed));
    let uppXUppYGradient = selectGradientPerlin(Number(upperX), Number(upperY), Number(seed));

    let lowXLowYOffset = getOffsetVec(pointScaled, [lowerX, lowerY]);
    let lowXUppYOffset = getOffsetVec(pointScaled, [lowerX, upperY]);
    let uppXLowYOffset = getOffsetVec(pointScaled, [upperX, lowerY]);
    let uppXUppYOffset = getOffsetVec(pointScaled, [upperX, upperY]);

    let dotLowXLowY = perlinDot(lowXLowYGradient, lowXLowYOffset);
    let dotLowXUpperY = perlinDot(lowXUppYGradient, lowXUppYOffset);
    let dotUppXLowY = perlinDot(uppXLowYGradient, uppXLowYOffset);
    let dotUppXUppY = perlinDot(uppXUppYGradient, uppXUppYOffset);

    let diff1 = xScaled - lowerX;
    let diff2 = yScaled - lowerY;

    let faded1 = fadeFunc(diff1);
    let faded2 = fadeFunc(diff2);

    let linterpLowerY = linterp(dotLowXLowY, dotUppXLowY, faded1);
    let linterpUpperY = linterp(dotLowXUpperY, dotUppXUppY, faded1);
    let linterpFinal = linterp(linterpLowerY, linterpUpperY, faded2);

    return linterpFinal;
}
// ********************************* SIMPLEX NOISE ********************************* // 
//
//
//
//
//
// ********************************************************************************* //

function simplexRandNum(a, b, c, d) {

    let temp1 = a % 256;
    let p1 = p[temp1];
    let temp2 = (b + p1) % 256;
    let p2 = p[temp2];
    let temp3 = (c + p2) % 256;
    let p3 = p[temp3];
    let temp4 = (d + p3) % 256;
    return p[temp4];
}

function selectVector(x, y, z, seed) {
    return gradients[simplexRandNum(Number(x),Number(y),Number(z),Number(seed)) % 12];
}

function noise3DCustom(x,y,z, scale, seed) {

    let scale64x61 = to64x61(scale);
    let xScaled = div(to64x61(x), scale64x61);
    let yScaled = div(to64x61(y), scale64x61);
    let zScaled = div(to64x61(z), scale64x61);

    let skew = mul(xScaled + yScaled + zScaled, F);

    let i = to64x61(from64x61(xScaled + skew));
    let j = to64x61(from64x61(yScaled + skew));
    let k = to64x61(from64x61(zScaled + skew));

    let unskew = mul(i + j + k, G);

    let x0 = xScaled - i + unskew;
    let y0 = yScaled - j + unskew;
    let z0 = zScaled - k + unskew;

    let i1;
    let j1;
    let k1;

    let i2;
    let j2; 
    let k2;

    if (x0 <= y0) {
        if (y0 <= z0) {
            i1 = 0n; j1 = 0n; k1 = ONE;
            i2 = 0n; j2 = ONE; k2 = ONE;
        } else {
            if (x0 <= z0) {
                i1 = 0n; j1 = ONE; k1 = 0n;
                i2 = 0n; j2 = ONE; k2 = ONE;
            }
            else {
                i1 = 0n; j1 = ONE; k1 = 0n;
                i2 = ONE; j2 = ONE; k2 = 0n;
            }
        }
    } else {
        if (z0 <= y0) {
            i1 = ONE; j1 = 0n; k1 = 0n;
            i2 = ONE; j2 = ONE; k2 = 0n;
        } else {
            if (z0 <= x0) {
                i1 = ONE; j1 = 0n; k1 = 0n;
                i2 = ONE; j2 = 0n; k2 = ONE;
            } else {
                i1 = 0n; j1 = 0n; k1 = ONE;
                i2 = ONE; j2 = 0n; k2 = ONE;
            }
        }
    }

    let x1 = x0 - i1 + G;
    let y1 = y0 - j1 + G; 
    let z1 = z0 - k1 + G; 

    let x2 = x0 - i2 + 2n*G; 
    let y2 = y0 - j2 + 2n*G; 
    let z2 = z0 - k2 + 2n*G;

    let x3 = x0 - ONE + 3n*G; 
    let y3 = y0 - ONE + 3n*G; 
    let z3 = z0 - ONE + 3n*G;

    let g0 = selectVector(i,j,k, seed);
    let g1 = selectVector(i + i1, j + j1, k + k1, seed);
    let g2 = selectVector(i + i2, j + j2, k + k2, seed);
    let g3 = selectVector(i + ONE, j + ONE, k + ONE, seed);

    let n0 = getContribution(x0, y0, z0, g0);
    let n1 = getContribution(x1, y1, z1, g1);
    let n2 = getContribution(x2, y2, z2, g2);
    let n3 = getContribution(x3, y3, z3, g3);

    return 32n * (n0 + n1 + n2 + n3);
}

function getContribution(x,y,z, point) {
    let xSqrd = mul(x,x);
    let ySqrd = mul(y,y);
    let zSqrd = mul(z,z);

    let t = R_SQUARED - xSqrd - ySqrd - zSqrd;

    if (t >= 0n) {
        let tSqrd = mul(t,t);
        let tPow4 = mul(tSqrd, tSqrd);
        let dotProd = simplexDot(x,y,z, point);

        return mul(dotProd, tPow4);
    } else {
        return 0n;
    }
}

function simplexDot(x,y,z, point) {
    return mul(x, point[0]) + mul(y, point[1]) + mul(z, point[2]);
}

// ********************************* FIXED POINT MATH ********************************* // 
//
//
//
//
//
// ********************************************************************************* //



function to64x61(num) {
    return num*ONE; 
}

function from64x61(num) {
    return num/ONE;
}

function mul(a, b) {
    return (a*b)/ONE;
}

function div(a, b) {
    return (a*ONE)/b;
}