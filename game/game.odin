package game
import "core:fmt"

import rl "vendor:raylib"


SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 800

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Odin 7-day")
    defer rl.CloseWindow()

    rl.SetExitKey(rl.KeyboardKey.ESCAPE)
    rl.SetTargetFPS(60)
    dpi_initialize(SCREEN_WIDTH, SCREEN_HEIGHT)
    defer dpi_cleanup()


    for !rl.WindowShouldClose() {
        input()
        update()
        render()
    }

}

input :: proc() {
    if rl.IsKeyPressed(rl.KeyboardKey.F10) {
        dpi_toggle()
        fmt.println("TOGGLE")
    }
}

update :: proc() {
}

render :: proc() {

    dpi_begin_drawing();

        rl.ClearBackground(rl.GRAY)

    dpi_end_drawing();

    rl.BeginDrawing()

        rl.ClearBackground(rl.RAYWHITE)
        dpi_render()

    rl.EndDrawing()

}