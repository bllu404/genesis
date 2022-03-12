%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math_cmp import is_le
from contracts.perlin_noise import noise_custom

from contracts.block_types import (
    BTYPE_UNINITIALIZED,
    BTYPE_AIR,
    BTYPE_STONE,
    BTYPE_DIRT,
    BTYPE_GRASS,
    BTYPE_ORE,
    BTYPE_WOOD,
    BTYPE_LEAF
)

from contracts.Math64x61 import (
    Math64x61_mul_unsafe,
    Math64x61_toFelt,
    Math64x61_ONE
)

# Defining the weight of each octave (64.61 format)
const OCTAVE1_W = 1152921504606846976 # 0.5
const OCTAVE2_W = 691752902764108185 # 0.3
const OCTAVE3_W = 461168601842738790 # 0.2

# Defining the scale of each octave (side-lengths of the grid squares)
const OCTAVE1_S = 300
const OCTAVE2_S = 100
const OCTAVE3_S = 50

const SURFACE_AMPLITUDE = 50 # At an amplitude of 50, the difference in height between the lowest point on the surface of the terrain and the tallest 100. 
const SURFACE_BASELINE = 100*Math64x61_ONE # At a baseline of 100 and amplitude of 50, the tallest block generated can have a height of 150. 

# This is the terrain generation algorithm
@view
func generate_block{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x, y, z) -> (block_type):
    alloc_locals

    # TO DO: Add asserts to ensure x y and z are within the correct bounds

    let (noise1) = noise_custom((x,y), OCTAVE1_S, 69)
    let (noise2) = noise_custom((x,y), OCTAVE2_S, 420)
    let (noise3) = noise_custom((x,y), OCTAVE3_S, 42069)

    let (octave1) = Math64x61_mul_unsafe(noise1, OCTAVE1_W)
    let (octave2) = Math64x61_mul_unsafe(noise2, OCTAVE2_W)
    let (octave3) = Math64x61_mul_unsafe(noise3, OCTAVE3_W)

    let (surface_height) = Math64x61_toFelt(SURFACE_AMPLITUDE*(octave1 + octave2 + octave3) + SURFACE_BASELINE)

    let (is_in_surface) = is_le(z, surface_height)

    if is_in_surface != 0:
        return(block_type=BTYPE_STONE)
    else:
        return(block_type=BTYPE_AIR) 
    end
end