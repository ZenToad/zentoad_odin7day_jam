package game
import "core:fmt"
import "core:mem"
import "core:c"
import "core:strings"

import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 800

Texture_ID :: enum {
    Loading_Screen,
    Sprite001,
}

Audio_ID :: enum {
    LaunchScreen,
}

TextureResource :: struct {
    id: Texture_ID,
    path: cstring,
}

AudioResource :: struct {
    id: Audio_ID,
    path: cstring,
}

audio_resources: []AudioResource = {
    AudioResource{ id = Audio_ID.LaunchScreen, path = "res/launch-screen.wav" },
}

texture_resources: []TextureResource = {
    TextureResource{ id = Texture_ID.Loading_Screen, path = "res/loading-screen-bkg.png" },
    TextureResource{ id = Texture_ID.Sprite001, path = "res/Sprite-0001.png" },
}

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

// the other way to do the draw command is just do it
// the other way where the union has all the types and we can just
// create an array of a fixed size for those items.
Draw_Command :: struct {
    variant: union {
        ^Draw_Rectangle,
        ^Draw_Text,
        ^Draw_Sprite,
    }
}

Draw_Rectangle :: struct {
    using command: Draw_Command,
    x, y, width, height: c.int,
    color: rl.Color,
}

Draw_Text :: struct {
    using command: Draw_Command,
    x, y: c.int,
    text: cstring,
    color: rl.Color,
    point: i32,
}

Draw_Sprite :: struct {
    using command: Draw_Command,
    id: Texture_ID,
    x, y: c.int,
    color: rl.Color,
}

Game :: struct {
    state: ^State,
    draw_commands: [dynamic] ^Draw_Command,
    intern: strings.Intern,
    sounds: map[Audio_ID]rl.Sound,
    textures: map[Texture_ID]rl.Texture2D,
}
g: Game 

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

push_draw_text :: proc(s: cstring, x, y, pt: c.int, c: rl.Color) {
    cmd := new_draw_command(Draw_Text)
    cmd.text = s
    cmd.x = x
    cmd.y = y
    cmd.point = pt
    cmd.color = c
    append_elem(&g.draw_commands, cmd)
}

push_draw_sprite :: proc(id: Texture_ID, x, y: c.int, c: rl.Color) {
    cmd := new_draw_command(Draw_Sprite)
    cmd.id = id
    cmd.x = x
    cmd.y = y
    cmd.color = c
    append_elem(&g.draw_commands, cmd)
}

play_sound :: proc(id: Audio_ID) {
    sound := g.sounds[id]
    if rl.IsSoundValid(sound) && rl.IsSoundReady(sound) {
        if rl.IsSoundPlaying(sound) == false {
            rl.PlaySound(sound)
        }
    } else {
        fmt.printfln("Error Playing audio: %v", id)
        assert(false)
    }
}

stop_sound :: proc(id: Audio_ID) {
    sound := g.sounds[id]
    if rl.IsSoundValid(sound) && rl.IsSoundReady(sound) {
        if rl.IsSoundPlaying(sound) == true {
            rl.StopSound(sound)
        }
    } else {
        fmt.printfln("Error Playing audio: %v", id)
        assert(false)
    }
}

stop_all_sounds :: proc() {
    for _, sound in g.sounds {
        rl.StopSound(sound)
    }
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
    new_state.duration = 1.5
    new_state.current = 0.0
    new_state.from = rl.GRAY
    new_state.to = rl.BLACK
    return new_state
}

do_loading_screen :: proc(s: ^Loading_Screen) {
    str := fmt.caprintf("Press Space to continue... Time: %f", f32(rl.GetTime()), allocator = context.temp_allocator)
    push_draw_sprite(.Loading_Screen, 0, 0, rl.WHITE)
    push_draw_text(str, 100, 100, 32, rl.GREEN)
    play_sound(.LaunchScreen)

    // but, so then let's say we're waiting for some event, like press any key,
    // how tf does that work?
    if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
        set_new_state(new_loading_screen_transition())
        stop_sound(.LaunchScreen)
    }
}

set_new_state :: proc(state: ^State) {
    if g.state != nil do free(g.state)
    g.state = state
}

render :: proc() {

    dpi_begin_drawing();

        rl.ClearBackground(rl.BLACK)
        for command in g.draw_commands {
            switch cmd in command.variant {
                case ^Draw_Rectangle:
                    rl.DrawRectangle(cmd.x, cmd.y, cmd.width, cmd.height, cmd.color)
                case ^Draw_Text: 
                    rl.DrawText(cmd.text, cmd.x, cmd.y, cmd.point, cmd.color)
                case ^Draw_Sprite:
                    sprite := g.textures[cmd.id]
                    rl.DrawTexture(sprite, cmd.x, cmd.y, cmd.color)
            }
            free(command)
        }
        clear_dynamic_array(&g.draw_commands)

    dpi_end_drawing()

    rl.BeginDrawing()

        rl.ClearBackground(rl.BLACK)
        dpi_render()

    rl.EndDrawing()

}

load_resources :: proc() {

    // load textures
    g.textures = make(map[Texture_ID]rl.Texture2D)
    for res in texture_resources {
        texture := rl.LoadTexture(res.path)
        if !rl.IsTextureValid(texture) {
            fmt.printfln("Error loading resource: %s", res.path)
            assert(false)
        } else {
            fmt.printfln("Texture Loaded: %s", res.path)
        }
        g.textures[res.id] = texture
    }

    // load sounds
    g.sounds = make(map[Audio_ID]rl.Sound)
    for res in audio_resources {
        sound := rl.LoadSound(res.path)
        if !rl.IsSoundValid(sound) {
            fmt.printfln("Error loading resource: %s", res.path)
            assert(false)
        } else {
            fmt.printfln("Audio Loaded: %s", res.path)
        }
        g.sounds[res.id] = sound
    }
}

unload_resources :: proc() {
    for _, sound in g.sounds {
        rl.UnloadSound(sound)
    }
    for _, texture in g.textures {
        rl.UnloadTexture(texture)
    }
}

quit :: proc() {
    unload_resources()
    for item in g.draw_commands {
        free(item)
    }
    delete(g.draw_commands)
    delete(g.sounds)
    delete(g.textures)
    free(g.state)
    strings.intern_destroy(&g.intern)
    dpi_cleanup()
    rl.CloseWindow()

}

main :: proc() {

    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    defer mem.tracking_allocator_destroy(&track)
    context.allocator = mem.tracking_allocator(&track)

    { // game 
        rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Odin 7-day")
        
        rl.SetExitKey(rl.KeyboardKey.ESCAPE)
        rl.SetTargetFPS(60)
        dpi_initialize(SCREEN_WIDTH, SCREEN_HEIGHT)
        
        g = Game {}
        
        rl.InitAudioDevice()
        
        strings.intern_init(&g.intern)
        load_resources()
        set_new_state(new_loading_screen_transition())

        for !rl.WindowShouldClose() {
            input() 
            update()
            render()
            free_all(context.temp_allocator)
        }

        quit()
    }

    for _, leak in track.allocation_map {
        fmt.printf("%v leaked %m\n", leak.location, leak.size)
    }

}

