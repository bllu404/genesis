%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import assert_le, unsigned_div_rem
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

##### BLOCK TYPES #####
const BTYPE_UNINITIALIZED = 0
const BTYPE_AIR = 1
const BTYPE_STONE = 2

# Stone block balance of each user
@storage_var
func stone_blocks_balance(user) -> (numBlocks):
end


##### GAME STATE MAPPING #####
# Whenever someone breaks or places a block, this mapping is updated to reflect that. 
# The value (as in key-value pair) of each coordinate is set to zero by default, and thus 0 is considered the uninitialized state.
# Whenever a block is interacted with, this value is updated to one of the block types defined above (not including the uninitialized type)

# TO DO: Look into packing the block_types of multiple blocks into one felt. Using 252 bits of storage per like 2 bits of info is incredibly wasteful. 
@storage_var 
func state(x, y, z) -> (block_type):
end

# This event should be emitted any time a block is updated (mined or placed)
@event
func block_updated(x,y,z, block_type):
end

@external
func mine_block{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x,y,z):
    alloc_locals

    let (user) = get_caller_address()

    let (block_state) = get_block(x,y,z)

    if block_state == BTYPE_STONE:
        let (balance) = stone_blocks_balance.read(user)
        stone_blocks_balance.write(user, balance + 1)

        # Rebinding all implicit pointers
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
        tempvar bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
        tempvar bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
        tempvar range_check_ptr = range_check_ptr
    end 

    state.write(x,y,z, BTYPE_AIR) # Setting the state of the block to "air" since it was just mined
    block_updated.emit(x,y,z, BTYPE_AIR)
    return()
end

@external 
func place_block{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x,y,z):
    alloc_locals 

    let (user) = get_caller_address() 

    let (block_state) = get_block(x,y,z)

    if block_state == BTYPE_AIR:
        let (user_balance) = stone_blocks_balance.read(user)
        assert_le(1, user_balance)
        state.write(x,y,z, BTYPE_STONE)
        stone_blocks_balance.write(user, user_balance - 1)
        block_updated.emit(x,y,z, BTYPE_STONE)
        
        # Rebinding all implicit pointers
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
        tempvar bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
        tempvar bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    return()
end

@view
func get_block{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x,y,z) -> (block_type):
    alloc_locals
    let (block_state) = state.read(x,y,z)

    if block_state == 0:
        let (block_state) = generate_block(x,y,z)
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
        tempvar bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
        tempvar bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
        tempvar range_check_ptr = range_check_ptr
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


####### STORAGE MAP UTILITIES ######

# The storage map `state` maps the coordinates of each block to its block type. (1,1,1) -> stone, (1,1,2) -> air, etc.
# The image of the map is a 252-bit felt for each coordinate, however each block_type (like stone and air) uses only a fraction of those bits. 
# So we can reduce the storage used significantly by packing together the state of many blocks into one felt.
# 
# Here we chose to pack blocks vertically. 
# This means that the felt associated with (x,y,0) will actually store the state of (x,y,0), (x,y,1), ..., (x,y,30).
# (x,y,1) will store the state of (x,y,31), (x,y,32), ..., (x,y,61), and so on. 

# Number of state values (e.g., BTYPE_AIR, BTYPE_STONE) to be stored per felt in the storage map. 
# By storing 31 state values per felt, we allocate 8 bits for each state value. 
const NUM_STATE_PER_FELT = 31
const FIRST_8BITS = 0xff # ANDing this with a felt yields the first 8 bits of the felt

func read_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(x,y,z) -> (block_state):
    let (q,r) = unsigned_div_rem(z, NUM_STATE_PER_FELT)

    let (packed_block_state) = state.read(x,y,q)
    let (shift) = pow_256(r)

    let (left_shifted_state,_) = unsigned_div_rem(packed_block_state, shift)
    let (block_state) = bitwise_and(left_shifted_state, FIRST_8BITS)
    return (block_state)
end 

# block_type must be 8 bits or less in size. The result will be unexpected otherwise.
func write_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(x,y,block_type):
    let (q,r) = unsigned_div_rem(z, NUM_STATE_PER_FELT)

    let (packed_block_state) = state.read(x,y,q)

    # pow_256(n) - 1 to get the bits before the 8 we want
    # bit shift pow_256(n) to get the ones after the one we want
    let (pow_r_plus1) = pow_256(r+1)
    let (bits_before) = bitwise_and(packed_block_state, pow_r_plus1 - 1)
    
    let (bits_after_shifted,_) = unsigned_div_rem(packed_block_state, power_r_plus1)
    tempvar bits_after = bits_after_shifted * pow_r_plus1

    state.write(x,y,q, bits_before + block_type + bits_after)

    return ()
end

# x // 256^n is equivalent to x >> 8*n
# x * 256^n is equivalent to x << 8*n

# Returns the nth power of 256
func pow_256(n) -> (power):
    let (pows_address) = get_label_location(pows)
    return (power=[pows_address + n])

    pows:
    dw 0x1 # 256^0
    dw 0x100 # 256^1
    dw 0x10000 # 256^2
    dw 0x1000000 # 256^3 
    dw 0x100000000 # 256^4
    dw 0x10000000000 # 256^5
    dw 0x1000000000000 # 256^6
    dw 0x100000000000000 # 256^7
    dw 0x10000000000000000 # 256^8
    dw 0x1000000000000000000 # 256^9
    dw 0x100000000000000000000 # 256^10
    dw 0x10000000000000000000000 # 256^11
    dw 0x1000000000000000000000000 # 256^12
    dw 0x100000000000000000000000000 # 256^13
    dw 0x10000000000000000000000000000 # 256^14
    dw 0x1000000000000000000000000000000 # 256^15
    dw 0x100000000000000000000000000000000 # 256^16
    dw 0x10000000000000000000000000000000000 # 256^17
    dw 0x1000000000000000000000000000000000000 # 256^18
    dw 0x100000000000000000000000000000000000000 # 256^19
    dw 0x10000000000000000000000000000000000000000 # 256^20
    dw 0x1000000000000000000000000000000000000000000 # 256^21
    dw 0x100000000000000000000000000000000000000000000 # 256^22
    dw 0x10000000000000000000000000000000000000000000000 # 256^23
    dw 0x1000000000000000000000000000000000000000000000000 # 256^24
    dw 0x100000000000000000000000000000000000000000000000000 # 256^25
    dw 0x10000000000000000000000000000000000000000000000000000 # 256^26
    dw 0x1000000000000000000000000000000000000000000000000000000 # 256^27
    dw 0x100000000000000000000000000000000000000000000000000000000 # 256^28
    dw 0x10000000000000000000000000000000000000000000000000000000000 # 256^29
    dw 0x1000000000000000000000000000000000000000000000000000000000000 # 256^30
end
