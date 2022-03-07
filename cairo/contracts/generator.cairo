%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import assert_le
from contracts.perlin_noise import noise_custom
from contracts.Math64x61 import (
    Math64x61_add,
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

# Stone block balance of each user
@storage_var
func stone_blocks_balance(user) -> (numBlocks):
end

##### GAME STATE MAPPING #####
# Whenever someone breaks or places a block, this mapping is updated to reflect that. 
# The value (as in key-value pair) of each coordinate is set to zero by default, and thus 0 is considered the uninitialized state.
# Whenever a block is interacted with, this value is updated to one of the following block types:

##### BLOCK TYPES #####
const BTYPE_UNINITIALIZED = 0
const BTYPE_AIR = 1
const BTYPE_STONE = 2

@storage_var 
func game_state(x, y, z) -> (block_type):
end

@external
func mine_block{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x,y,z):
    alloc_locals

    let (user) = get_caller_address()

    let (block_state) = get_block(x,y,z)

    if block_state == BTYPE_STONE:
        let (balance) = stone_blocks_balance.read(user)
        stone_blocks_balance.write(user, balance + 1)
    end 

    game_state.write(x,y,z, BTYPE_AIR) # Setting the state of the block to "air" since it was just mined
    ret
end

@external 
func place_block{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x,y,z):
    alloc_locals 

    let (user) = get_caller_address() 

    let (block_state) = get_block(x,y,z)

    if block_state == BTYPE_AIR:
        let (user_balance) = stone_blocks_balance.read(user)
        assert_le(1, user_balance)
        game_state.write(x,y,z, BTYPE_STONE)
        stone_blocks_balance.write(user, user_balance - 1)
    end
    ret
end

@view
func get_block{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x,y,z) -> (block_type):
    let (block_state) = game_state.read(x,y,z)

    if block_state == 0:
        let (block_state) = generate_block(x,y,z)
    end

    return (block_type=block_state)
end

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