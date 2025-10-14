ifndef shipShard_h
shipShard_h = 1

include <globaldefs.inc>

include <array.s>


ShipShard struct
	pos          Point  <?>
	velocity     Vector <?>
	len          dd     ?
	rot          dw     ?   ; 8.8 fixed point
	rot_velocity dw     ?   ; 8.8 fixed point
ShipShard ends
MAX_NUM_SHIP_SHARDS = 8


.data

ship_shards     ShipShard MAX_NUM_SHIP_SHARDS dup (<>)
ship_shards_arr Array     { { ship_shards, 0 }, MAX_NUM_SHIP_SHARDS, sizeof ShipShard }


.code

; in:
	; rbx - pos
	; rcx - velocity
	; edx - len
shipShard_create proc
	lea rsi, ship_shards_arr
	call array_push
	test eax, eax
	je _end

	mov qword ptr [rsi].ShipShard.pos, rbx
	mov qword ptr [rsi].ShipShard.velocity, rcx
	mov [rsi].ShipShard.len, edx

	; rot is random
	; rot_velocity is random
	
	_end:
	ret
shipShard_create endp

shipShard_updateAll proc
	lea rsi, ship_shards_arr
	lea r8, shipShard_update
	jmp array_forEach
shipShard_updateAll endp

; in:
	; rdi - pointer to ship shard
; out:
	; eax - 1 if ship shard is destroyed, 0 else
shipShard_update proc
shipShard_update endp

shipShard_drawAll proc
	lea rsi, ship_shards_arr
	lea r8, shipShard_draw
	jmp array_forEach
shipShard_drawAll endp

; in:
	; rdi - pointer to ship shard
; out:
	; eax - 0 (ship shard not destroyed)
shipShard_draw proc
	xor eax, eax
	ret
shipShard_draw endp


endif
