%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.hash import hash2
from contracts.perlin_noise import noise_custom
from contracts.simplex3D import noise3D_custom
from contracts.permutation_table import p 
from contracts.block_types import (
    BTYPE_UNINITIALIZED,
    BTYPE_AIR,
    BTYPE_STONE,
    BTYPE_DIRT,
    BTYPE_GRASS,
    BTYPE_ORE,
    BTYPE_WOOD,
    BTYPE_LEAF,
)

from contracts.Math64x61 import Math64x61_mul_unsafe, Math64x61_toFelt, Math64x61_ONE

# Defining the weight of each octave (64.61 format)
const HEIGHTMAP_OCTAVE1_W = 1152921504606846976  # 0.5
const HEIGHTMAP_OCTAVE2_W = 691752902764108185  # 0.3
const HEIGHTMAP_OCTAVE3_W = 461168601842738790  # 0.2

# Defining the scale of each octave (side-lengths of the grid squares)
const HEIGHTMAP_OCTAVE1_S = 300
const HEIGHTMAP_OCTAVE2_S = 100
const HEIGHTMAP_OCTAVE3_S = 50

# At an amplitude of 70, the difference in height between the lowest point on the surface of the terrain and the tallest is approximately 100.
# This is because the perlin noise function outputs a maximum value of ~0.7071 and a minimum value of about -0.7071
const SURFACE_AMPLITUDE = 70
const SURFACE_BASELINE = 100 * Math64x61_ONE  # At a baseline of 100 and amplitude of 50, the tallest block generated can have a height of 150.

# How many blocks below the surface the soil goes before stone is reached
const TOPSOIL_BASELINE = 8 * Math64x61_ONE

# Maximum displacement (in either direction) of the baseline.
const TOPSOIL_AMPLITUDE = 5

# Scale factor to be used in noise function for soil
const TOPSOIL_SCALE = 50

# Defining the weight of each octave (64.61 format)
const CAVE_OCTAVE1_W = 1152921504606846976  # 0.5
const CAVE_OCTAVE2_W = 691752902764108185  # 0.3
const CAVE_OCTAVE3_W = 461168601842738790  # 0.2

# Defining the scale of each octave (side-lengths of the grid squares)
const CAVE_OCTAVE1_S = 20
const CAVE_OCTAVE2_S = 10
const CAVE_OCTAVE3_S = 5

# A Fractal noise value above this value means no block is there, otherwise a block is there. 
const CAVE_THRESHOLD = 161409010644958576 # 0.07

# This is the terrain generation algorithm
@view
func generate_block{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
    x, y, z
) -> (block_type):
    alloc_locals

    # TO DO: Add asserts to ensure x y and z are within the correct bounds

    let (noise1) = noise_custom((x, y), HEIGHTMAP_OCTAVE1_S, 69)
    let (noise2) = noise_custom((x, y), HEIGHTMAP_OCTAVE2_S, 420)
    let (noise3) = noise_custom((x, y), HEIGHTMAP_OCTAVE3_S, 42069)

    let (octave1) = Math64x61_mul_unsafe(noise1, HEIGHTMAP_OCTAVE1_W)
    let (octave2) = Math64x61_mul_unsafe(noise2, HEIGHTMAP_OCTAVE2_W)
    let (octave3) = Math64x61_mul_unsafe(noise3, HEIGHTMAP_OCTAVE3_W)

    let (surface_height) = Math64x61_toFelt(
        SURFACE_AMPLITUDE * (octave1 + octave2 + octave3) + SURFACE_BASELINE
    )

    let (is_in_surface) = is_le(z, surface_height)

    if is_in_surface != 0:
        if z == surface_height:
            return (block_type=BTYPE_GRASS)
        end

        # Computing how deep the soil goes before stone is reached
        let (soil_displacement_noise) = noise_custom((x, y), TOPSOIL_SCALE, 12345)
        let (soil_depth) = Math64x61_toFelt(
            TOPSOIL_BASELINE + TOPSOIL_AMPLITUDE * soil_displacement_noise
        )

        let (is_in_soil) = is_le(surface_height - soil_depth, z)

        if is_in_soil != 0:
            return (block_type=BTYPE_DIRT)
        else:
            let (noise1) = noise3D_custom(x,y,z, CAVE_OCTAVE1_S, 69)
            let (noise2) = noise3D_custom(x,y,z, CAVE_OCTAVE2_S, 420)
            let (noise3) = noise3D_custom(x,y,z, CAVE_OCTAVE3_S, 42069)

            let (octave1) = Math64x61_mul_unsafe(noise1, CAVE_OCTAVE1_W)
            let (octave2) = Math64x61_mul_unsafe(noise2, CAVE_OCTAVE2_W)
            let (octave3) = Math64x61_mul_unsafe(noise3, CAVE_OCTAVE3_W)

            let sum = octave1 + octave2 + octave3 
            let (is_air) = is_le(CAVE_THRESHOLD, sum)
            if is_air != 0:
                return (block_type=BTYPE_AIR)
            else:
                let (is_ore) = get_rand_num(x, y, z)
                if is_ore != 0:
                    return (block_type=BTYPE_STONE)
                else:
                    return (block_type=BTYPE_ORE)
                end
            end
        end
    else:
        return (block_type=BTYPE_AIR)
    end
end

# Returns a pseudo-random number between 0 and 127, using (x,y,z) as a seed
#func get_rand_num{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*}(x, y, z) -> (
#    rand_num
#):
#    alloc_locals
#
#    let (first_hash) = hash2{hash_ptr=pedersen_ptr}(x, y)
#    let (final_hash) = hash2{hash_ptr=pedersen_ptr}(first_hash, z)
#    let (rand_num) = bitwise_and(final_hash, 15)
#    return (rand_num)
#end

func get_rand_num{range_check_ptr}(seed1,seed2,seed3) -> (
    rand_num
):
    let (_, seed1_mod) = unsigned_div_rem(seed1, 256)

    let (p1) = p(seed1_mod)
    let (_, temp1) = unsigned_div_rem(p1 + seed2, 256)
    let (p2) = p(temp1)
    let (_, temp2) = unsigned_div_rem(p2 + seed3, 256)
    let (p3) = p(temp2)
    let (_, rand_num) = unsigned_div_rem(p3, 20)
    return (rand_num)
end
