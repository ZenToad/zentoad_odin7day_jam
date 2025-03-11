package game
import "core:fmt"
import rl "vendor:raylib"

SCALE_FACTOR :: 2.0
SCALE_FACTOR_INV :: 1.0 / SCALE_FACTOR

acme :: struct {
    screen_width: i32,
    screen_height: i32,
    screen_size_double: bool,
    mouse_scale: f32,
    screen_target: rl.RenderTexture2D,
}

_acme := acme{}

dpi_initialize :: proc(screen_width: i32, screen_height: i32) {
    fmt.printfln("Screen width: %v, Screen height: %v", screen_width, screen_height)
    _acme.screen_width = screen_width
    _acme.screen_height = screen_height
    _acme.screen_size_double = false
    
    _acme.screen_target = rl.LoadRenderTexture(_acme.screen_width, _acme.screen_height)
    rl.SetTextureFilter(_acme.screen_target.texture, rl.TextureFilter.POINT)

    monitor_width := rl.GetMonitorWidth(rl.GetCurrentMonitor())
    monitor_height := rl.GetMonitorHeight(rl.GetCurrentMonitor())

    if rl.GetWindowScaleDPI().x > 1 || monitor_width > _acme.screen_width * SCALE_FACTOR {
        if monitor_height - 24 - 40 > _acme.screen_height * SCALE_FACTOR {
            _acme.screen_size_double = true
            rl.SetWindowSize(_acme.screen_width * SCALE_FACTOR, _acme.screen_height * SCALE_FACTOR)
            _acme.mouse_scale = SCALE_FACTOR_INV
            rl.SetMouseScale(SCALE_FACTOR_INV, SCALE_FACTOR_INV)
            rl.SetWindowPosition(monitor_width / 2 - _acme.screen_width, monitor_height / 2 - _acme.screen_height)
        }
    }
}

dpi_toggle :: proc() {

    monitor_width := rl.GetMonitorWidth(rl.GetCurrentMonitor())
    monitor_height := rl.GetMonitorHeight(rl.GetCurrentMonitor())
    _acme.screen_size_double = !_acme.screen_size_double
    if _acme.screen_size_double {
        if rl.GetScreenWidth() < _acme.screen_width * SCALE_FACTOR {
            rl.SetWindowSize(_acme.screen_width * SCALE_FACTOR, _acme.screen_height * SCALE_FACTOR)
            _acme.mouse_scale = SCALE_FACTOR_INV
            _acme.mouse_scale = SCALE_FACTOR_INV
            rl.SetMouseScale(SCALE_FACTOR_INV, SCALE_FACTOR_INV)
            rl.SetWindowPosition(monitor_width / 2 - _acme.screen_width, monitor_height / 2 - _acme.screen_height)
        }
    } else {
        if _acme.screen_width * 2 >= rl.GetScreenWidth() {
            rl.SetWindowSize(_acme.screen_width, _acme.screen_height)
            _acme.mouse_scale = 1.0
            rl.SetMouseScale(1.0, 1.0)
            rl.SetWindowPosition(monitor_width / 2 - _acme.screen_width / 2, monitor_height / 2 - _acme.screen_height / 2);
        }    
    }
}

dpi_get_mouse_scale :: proc() -> f32 {
    return _acme.mouse_scale
}

dpi_render :: proc() {
    if _acme.screen_size_double {
        source := rl.Rectangle{0, 0, f32(_acme.screen_target.texture.width), -f32(_acme.screen_target.texture.height)}
        dest := rl.Rectangle{0, 0, f32(_acme.screen_target.texture.width * SCALE_FACTOR), f32(_acme.screen_target.texture.height * SCALE_FACTOR)}
        origin := rl.Vector2{}
        rotation: f32 = 0.0
        tint := rl.WHITE
        rl.DrawTexturePro(_acme.screen_target.texture, source, dest, origin, rotation, tint)
    } else {
        source := rl.Rectangle{0, 0, f32(_acme.screen_target.texture.width), -f32(_acme.screen_target.texture.height)}
        position := rl.Vector2{}
        tint := rl.WHITE
        rl.DrawTextureRec(_acme.screen_target.texture, source, position, tint)
    }
}

dpi_begin_drawing :: proc() {
    rl.BeginTextureMode(_acme.screen_target)
}

dpi_end_drawing :: proc() {
    rl.EndTextureMode()
}

dpi_cleanup :: proc() {
    rl.UnloadRenderTexture(_acme.screen_target)
}