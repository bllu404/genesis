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
const BTYPE_DIRT = 3
const BTYPE_GRASS = 4
const BTYPE_ORE = 5
const BTYPE_WOOD = 6
const BTYPE_LEAF = 7

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
# By storing 41 state values per felt, we allocate 3 bits for each state value. 
# This means we are making use of 123 bits per felt, as opposed to 3. The reason 
const NUM_STATE_PER_FELT = 41
const FIRST_3BITS = 7 # ANDing this with a felt yields the first 3 bits of the felt

@external
func read_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(x,y,z) -> (block_state):
    alloc_locals
    let (q,r) = unsigned_div_rem(z, NUM_STATE_PER_FELT)

    let (packed_block_state) = state.read(x,y,q)
    let (shift) = pow_8(r)

    let (left_shifted_state,_) = unsigned_div_rem(packed_block_state, shift)
    let (block_state) = bitwise_and(left_shifted_state, FIRST_3BITS)
    return (block_state)
end 

# block_type must be 8 bits or less in size. The result will be unexpected otherwise.
@external
func write_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(x,y,z, block_type):
    alloc_locals

    let (q,r) = unsigned_div_rem(z, NUM_STATE_PER_FELT)
    let (packed_block_state) = state.read(x,y,q)

    let (pow_r) = pow_8(r)
    let (bits_before) = bitwise_and(packed_block_state, pow_r - 1)

    tempvar pow_r_plus1 = pow_r * 8

    let (bits_after_shifted,_) = unsigned_div_rem(packed_block_state, pow_r_plus1)
    tempvar bits_after = bits_after_shifted * pow_r_plus1

    state.write(x,y,q, bits_before + (block_type*pow_r) + bits_after)

    return ()
end

# x // 8^n is equivalent to x >> 3*n
# x * 8^n is equivalent to x << 3*n

# Returns the nth power of 2^3 = 8, up to 8^41
func pow_8(n) -> (power):
    let (pows_address) = get_label_location(pows)
    return (power=[pows_address + n])

    pows:
    dw 0x1 # 8^0
    dw 0x8 # 8^1
    dw 0x40 # 8^2
    dw 0x200 # 8^3
    dw 0x1000 # 8^4
    dw 0x8000 # 8^5
    dw 0x40000 # 8^6
    dw 0x200000 # 8^7
    dw 0x1000000 # 8^8
    dw 0x8000000 # 8^9
    dw 0x40000000 # 8^10
    dw 0x200000000 # 8^11
    dw 0x1000000000 # 8^12
    dw 0x8000000000 # 8^13
    dw 0x40000000000 # 8^14
    dw 0x200000000000 # 8^15
    dw 0x1000000000000 # 8^16
    dw 0x8000000000000 # 8^17
    dw 0x40000000000000 # 8^18
    dw 0x200000000000000 # 8^19
    dw 0x1000000000000000 # 8^16
    dw 0x8000000000000000 # 8^17
    dw 0x40000000000000000 # 8^18
    dw 0x200000000000000000 # 8^19
    dw 0x1000000000000000000 # 8^20
    dw 0x8000000000000000000 # 8^21
    dw 0x40000000000000000000 # 8^22
    dw 0x200000000000000000000 # 8^23
    dw 0x1000000000000000000000 # 8^24
    dw 0x8000000000000000000000 # 8^25
    dw 0x40000000000000000000000 # 8^26
    dw 0x200000000000000000000000 # 8^27
    dw 0x1000000000000000000000000 # 8^28
    dw 0x8000000000000000000000000 # 8^29
    dw 0x40000000000000000000000000 # 8^30
    dw 0x200000000000000000000000000 # 8^31
    dw 0x1000000000000000000000000000 # 8^32
    dw 0x8000000000000000000000000000 # 8^33
    dw 0x40000000000000000000000000000 # 8^34
    dw 0x200000000000000000000000000000 # 8^35
    dw 0x1000000000000000000000000000000 # 8^36
    dw 0x8000000000000000000000000000000 # 8^37
    dw 0x40000000000000000000000000000000 # 8^38
    dw 0x200000000000000000000000000000000 # 8^39
    dw 0x1000000000000000000000000000000000 # 8^40
    dw 0x8000000000000000000000000000000000 # 8^41
end
