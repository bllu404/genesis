// ********************************* CONSTANTS ********************************* // 
//
//
//
//
//
// ***************************************************************************** //
const F = 768614336404564650
const G = 384307168202282325
const R_SQUARED = 1383505805528216371
const ONE = 2**61

const gradients = [
    [ONE,ONE,0],
    [-ONE,ONE,0],
    [ONE,-ONE,0],
    [-ONE,-ONE,0],
    [ONE,0,ONE],
    [-ONE,0,ONE],
    [ONE,0,-ONE],
    [-ONE,0,-ONE],
    [0,ONE,ONE],
    [0,-ONE,ONE],
    [0,ONE,-ONE],
    [0,-ONE,-ONE]
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

// ********************************* MAIN ********************************* // 
//
//
//
//
//
// *********************************************************************** //
console.log("\nAlong x-axis");
for (let i = 0; i < 20; i++) {
    console.log(noise3DCustom(100 - i,100,100, 100, 69)/ONE);
}

console.log("\nAlong y-axis");
for (let i = 0; i < 20; i++) {
    console.log(noise3DCustom(100,100 + i,100, 100, 69)/ONE);
}

console.log("\nAlong z-axis");
for (let i = 0; i < 20; i++) {
    console.log(noise3DCustom(100,100 + i,100 + i, 100, 69)/ONE);
}

// ********************************* PERLIN NOISE ********************************* // 
//
//
//
//
//
// ******************************************************************************** //



function noise2DCustom(x,y, scale, seed) {

}

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
    return gradients[simplexRandNum(x,y,z,seed) % 12];
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
            i1 = 0; j1 = 0; k1 = ONE;
            i2 = 0; j2 = ONE; k2 = ONE;
        } else {
            if (x0 <= z0) {
                i1 = 0; j1 = ONE; k1 = 0;
                i2 = 0; j2 = ONE; k2 = ONE;
            }
            else {
                i1 = 0; j1 = ONE; k1 = 0;
                i2 = ONE; j2 = ONE; k2 = 0;
            }
        }
    } else {
        if (z0 <= y0) {
            i1 = ONE; j1 = 0; k1 = 0;
            i2 = ONE; j2 = ONE; k2 = 0;
        } else {
            if (z0 <= x0) {
                i1 = ONE; j1 = 0; k1 = 0;
                i2 = ONE; j2 = 0; k2 = ONE;
            } else {
                i1 = 0; j1 = 0; k1 = ONE;
                i2 = ONE; j2 = 0; k2 = ONE;
            }
        }
    }

    let x1 = x0 - i1 + G;
    let y1 = y0 - j1 + G; 
    let z1 = z0 - k1 + G; 

    let x2 = x0 - i2 + 2*G; 
    let y2 = y0 - j2 + 2*G; 
    let z2 = z0 - k2 + 2*G;

    let x3 = x0 - ONE + 3*G; 
    let y3 = y0 - ONE + 3*G; 
    let z3 = z0 - ONE + 3*G;

    let g0 = selectVector(i,j,k, seed);
    let g1 = selectVector(i + i1, j + j1, k + k1, seed);
    let g2 = selectVector(i + i2, j + j2, k + k2, seed);
    let g3 = selectVector(i + ONE, j + ONE, k + ONE, seed);

    let n0 = getContribution(x0, y0, z0, g0);
    let n1 = getContribution(x1, y1, z1, g1);
    let n2 = getContribution(x2, y2, z2, g2);
    let n3 = getContribution(x3, y3, z3, g3);

    return 32 * (n0 + n1 + n2 + n3);
}

function getContribution(x,y,z, point) {
    let xSqrd = mul(x,x);
    let ySqrd = mul(y,y);
    let zSqrd = mul(z,z);

    let t = R_SQUARED - xSqrd - ySqrd - zSqrd;

    if (t >= 0) {
        let tSqrd = mul(t,t);
        let tPow4 = mul(tSqrd, tSqrd);
        let dotProd = simplexDot(x,y,z, point);

        return mul(dotProd, tPow4);
    } else {
        return 0;
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
    return Math.floor(num/ONE);
}

function mul(a, b) {
    return Math.floor((a*b)/ONE);
}

function div(a, b) {
    return Math.floor(a*ONE/b);
}