%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_le, unsigned_div_rem, assert_not_equal

from contracts.generator import generate_block

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

#### STORAGE VARIABLES ####

# Mapping of user's block balances block_balance[user][block_type] = numBlocks
@storage_var
func block_balance(user : felt, block_type : felt) -> (numBlocks : felt):
end

##### GAME STATE MAPPING #####
# Whenever someone breaks or places a block, this mapping is updated to reflect that. 
# The value (as in key-value pair) of each coordinate is set to zero by default, and thus 0 is considered the uninitialized state.
# Whenever a block is interacted with, this value is updated to one of the block types defined above (not including the uninitialized type)

@storage_var 
func state(x, y, z) -> (block_type):
end

# This event should be emitted any time a block is updated (mined or placed)
@event
func block_updated(x,y,z, block_type):
end

#### INTERNAL FUNCTIONS ####

# Mine block type and add to balance
func _mine_block{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(
        user : felt,
        block_type : felt
    ):
    let (balance) = block_balance.read(user, block_type)
    block_balance.write(user, block_type, balance + 1)
    return ()
end


# Place specific block type and decreases the user balance
func _place_block{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            bitwise_ptr : BitwiseBuiltin*
        }(
        x : felt,
        y : felt,
        z : felt,
        user : felt,
        block_type : felt
    ):
    alloc_locals
    let (local user_balance) = block_balance.read(user, block_type)
    assert_le(1, user_balance)
    write_state(x,y,z, block_type)
    block_balance.write(user, block_type, user_balance - 1)
    block_updated.emit(x,y,z, block_type)
    return ()    
end


# Reads the initial block state and mines (adds to user balance) it, then converts to an air block
@external
func mine_block{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x,y,z):
    alloc_locals

    let (user) = get_caller_address()

    let (block_state) = get_block(x,y,z)

    # Ensures the block isn't an air block
    assert_not_equal(block_state, BTYPE_AIR)

    # Mine the block
    _mine_block(user=user, block_type=block_state)

    write_state(x,y,z, BTYPE_AIR) # Setting the state of the block to "air" since it was just mined
    block_updated.emit(x,y,z, BTYPE_AIR)
    return()
end

@external 
func place_block{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x,y,z, block_type):
    alloc_locals 

    let (user) = get_caller_address() 

    let (block_state) = get_block(x,y,z)

    if block_state == BTYPE_AIR:

        # Place the block
        _place_block(x,y,z, user, block_type)

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
    let (block_state) = read_state(x,y,z)

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


####### STORAGE MAP UTILITIES ######

# The storage map `state` maps the coordinates of each block to its block type. (1,1,1) -> stone, (1,1,2) -> air, etc.
# The image of the map is a 252-bit felt for each coordinate, however each block_type (like stone and air) uses only a fraction of those bits. 
# So we can reduce the storage used significantly by packing together the state of many blocks into one felt.
# 
# Here we chose to pack blocks vertically. 
# This means that the felt associated with (0,y,z) will actually store the state of (0,y,z), (1,y,z), ..., (40,y,z).
# (1,y,z) will store the state of (41,y,z), (42,y,z), ..., (40,y,z), and so on. 

# Number of state values (e.g., BTYPE_AIR, BTYPE_STONE) to be stored per felt in the storage map. 
# By storing 41 state values per felt, we allocate 3 bits for each state value. 
# This means we are making use of 123 bits per felt, as opposed to 3. 
# The 123-bit limit has to do with restrictions imposed by the `unsigned_div_rem` function. 
const NUM_STATE_PER_FELT = 41
const FIRST_3BITS = 7 # ANDing this with a felt yields the first 3 bits of the felt

func read_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(x,y,z) -> (block_state):
    alloc_locals
    let (q,r) = unsigned_div_rem(x, NUM_STATE_PER_FELT)

    let (packed_block_state) = state.read(q,y,z)
    let (shift) = pow_8(r)

    let (left_shifted_state,_) = unsigned_div_rem(packed_block_state, shift)
    let (block_state) = bitwise_and(left_shifted_state, FIRST_3BITS)
    return (block_state)
end 

# block_type must be 8 bits or less in size. The result will be unexpected otherwise.
func write_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(x,y,z, block_type):
    alloc_locals

    let (q,r) = unsigned_div_rem(x, NUM_STATE_PER_FELT)
    let (packed_block_state) = state.read(q,y,z)

    let (pow_r) = pow_8(r)
    tempvar pow_r_plus1 = pow_r * 8
    let (bits_before) = bitwise_and(packed_block_state, pow_r - 1)


    let (bits_after_shifted,_) = unsigned_div_rem(packed_block_state, pow_r_plus1)
    tempvar bits_after = bits_after_shifted * pow_r_plus1

    state.write(q,y,z, bits_before + pow_r*block_type + bits_after)

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
