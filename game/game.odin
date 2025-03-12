package game
import "core:fmt"
import "core:mem"
import "core:c"

import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 800

State :: struct {
    variant: union {
        ^Loading_Screen_Transition,
        ^Loading_Screen,
    }
}

Loading_Screen_Transition :: struct {
    using state: State,
    from: rl.Color,
    to: rl.Color,
    duration: f32,
    current: f32,
}

Loading_Screen :: struct {
    using state: State,
    from: rl.Color,
    to: rl.Color,
    duration: f32,
    current: f32,
}

Draw_Command :: struct {
    variant: union {
        ^Draw_Rectangle,
    }
}

Draw_Rectangle :: struct {
    using command: Draw_Command,
    x, y, width, height: c.int,
    color: rl.Color,
}

Game :: struct {
    state: ^State,
    draw_commands: [dynamic] ^Draw_Command,
}
g: Game 

main :: proc() {

    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    defer mem.tracking_allocator_destroy(&track)
    context.allocator = mem.tracking_allocator(&track)

    { // game 
        rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Odin 7-day")
        defer rl.CloseWindow()

        rl.SetExitKey(rl.KeyboardKey.ESCAPE)
        rl.SetTargetFPS(60)
        dpi_initialize(SCREEN_WIDTH, SCREEN_HEIGHT)
        defer dpi_cleanup()

        g = Game {}

        set_new_state(new_loading_screen_transition())

        for !rl.WindowShouldClose() {
            input() 
            update()
            render()
        }

        quit()
    }

    for _, leak in track.allocation_map {
        fmt.printf("%v leaked %m\n", leak.location, leak.size)
    }

}

new_state :: proc($T: typeid) -> ^T {
    e := new(T)
    e.variant = e
    return e
}

new_draw_command :: proc($T: typeid) -> ^T {
    e := new(T)
    e.variant = e
    return e
}

push_draw_rect ::proc(x, y, w, h: c.int, color: rl.Color) {
    cmd := new_draw_command(Draw_Rectangle)
    cmd.x = x
    cmd.y = y
    cmd.width = w
    cmd.height = h
    append_elem(&g.draw_commands, cmd)
}

input :: proc() {
    if rl.IsKeyPressed(rl.KeyboardKey.F10) {
        dpi_toggle()
        fmt.println("TOGGLE")
    }
}

update :: proc() {
    // Handle State Machine
    switch state in g.state.variant {
        case ^Loading_Screen_Transition:
            do_loading_screen_transition(state)
        case ^Loading_Screen:
            do_loading_screen(state)
    }
}

do_loading_screen_transition :: proc(s: ^Loading_Screen_Transition) {
     s.current += rl.GetFrameTime()
     if s.duration <= s.current {
        free(g.state)
        g.state = new_state(Loading_Screen)
     }
     rect := new_draw_command(Draw_Rectangle)
     color := rl.ColorLerp(s.from, s.to, s.current / s.duration)
     rect.color = color
     rect.x = 0
     rect.y = 0
     rect.width = SCREEN_WIDTH
     rect.height = SCREEN_HEIGHT
     append_elem(&g.draw_commands, rect)
}

new_loading_screen_transition :: proc() -> ^Loading_Screen_Transition {
    new_state := new_state(Loading_Screen_Transition)
    new_state.duration = 3.0
    new_state.current = 0.0
    new_state.from = rl.BLACK
    new_state.to = rl.WHITE
    return new_state
}

do_loading_screen :: proc(s: ^Loading_Screen) {
    set_new_state(new_loading_screen_transition())
}

set_new_state :: proc(state: ^State) {
    if g.state != nil do free(g.state)
    g.state = state
}

render :: proc() {

    dpi_begin_drawing();

        rl.ClearBackground(rl.GRAY)
        for command in g.draw_commands {
            switch cmd in command.variant {
                case ^Draw_Rectangle:
                    using cmd
                    rl.DrawRectangle(x, y, width, height, color)
            }
            free(command)
        }
        clear_dynamic_array(&g.draw_commands)
    dpi_end_drawing();

    rl.BeginDrawing()

        rl.ClearBackground(rl.RAYWHITE)
        dpi_render()

    rl.EndDrawing()

}

quit :: proc() {
    for item in g.draw_commands {
        free(item)
    }
    delete(g.draw_commands)
    free(g.state)
}