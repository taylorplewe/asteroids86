Asteroid struct
        pos        Point  <?>
        velocity   Vector <?>
        mass       dd     ?   ; 0 when dead
        shape      dd     ?
        rot        db     ?
Asteroid ends

MAX_NUM_ASTEROIDS       = 64


.data

asteroids Asteroid MAX_NUM_ASTEROIDS dup (<>)

asteroid_shapes FatPtr {asteroid_shape1, asteroid_shape1_len}

asteroid_shape1 BasePoint {32, 0}, {32, 64}, {32, 128}, {32, 196}
asteroid_shape1_len = ($ - asteroid_shape1) / BasePoint


.code

asteroids_updateAll proc
        mov eax, MAX_NUM_ASTEROIDS
        lea rdi, asteroids
        mainLoop:
                cmp [rdi].Asteroid.mass, 0
                je next

                call asteroids_draw

                next:
                add rdi, sizeof Asteroid
                loop mainLoop
        ret
asteroids_updateAll endp

; in:
        ; rdi - pointer to current asteroid
asteroids_draw proc
        ; draw all the points of this asteroid's shape
        ret
asteroids_draw endp
