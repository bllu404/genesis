function dot(x,y,z, point) {
    return mul(x, point[0]) + mul(y, point[1]) + mul(z, point[2]);
}

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