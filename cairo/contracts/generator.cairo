%lang starknet

from starkware.cairo.common.math_cmp import is_le
from perlin_noise import noise_custom
from Math64x61 import (
    Math64x61_add
    Math64x61_mul_unsafe
    Math64x61_toFelt

)

# Defining the weight of each octave (64.61 format)
const OCTAVE1_W = 1152921504606846976 # 0.5
const OCTAVE2_W = 691752902764108185 # 0.3
const OCTAVE3_W = 461168601842738790 # 0.2

const SURFACE_AMPLITUDE = 50 # At an amplitude of 50, the difference in height between the lowest point on the surface of the terrain and the tallest 100. 
const SURFACE_BASELINE = 100 # At a baseline of 100 and amplitude of 50, the tallest block generated can have a height of 150. 

##### BLOCK TYPES #####
# 1 = Air
# 2 = stone
func get_block{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x, y, z) -> (block_type):

    # TO DO: Add asserts to ensure x y and z are within the correct bounds

    let (noise1) = noise_custom((x,y), 300, 69)
    let (noise2) = noise_custom((x,y), 100, 420)
    let (noise3) = noise_custom((x,y), 50, 42069)

    tempvar octave1 = Math64x61_mul_unsafe(noise1, OCTAVE1_W)
    tempvar octave2 = Math64x61_mul_unsafe(noise2, OCTAVE2_W)
    tempvar octave3 = Math64x61_mul_unsafe(noise3, OCTAVE3_W)

    tempvar surface_height = Math64x61_toFelt(SURFACE_AMPLITUDE*(octave1 + octave2 + octave3) + SURFACE_BASELINE)

    let (is_in_surface) = is_le(z, surface_height)

    jmp in_surface if is_in_surface != 0
    return (block_type=1)

    in_surface:
    return (block_type=2)
end