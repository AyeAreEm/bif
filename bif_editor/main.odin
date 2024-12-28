package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:math"
import rl "vendor:raylib"

current_colour := rl.Color{0, 0, 0, 255}
last_mouse_pos := [2]f32{}

get_indices_from_mouse_position :: proc(mouse_pos: rl.Vector2, grid_rec: rl.Rectangle) -> (int, int) {
    return int(mouse_pos.x - grid_rec.x), int(mouse_pos.y - grid_rec.y)
}

get_image :: proc(grid: ^[dynamic][dynamic]rl.Color, width: int, height: int) -> (builder: strings.Builder) {
    content, err := strings.builder_init(&builder)
    if err != .None {
        panic("failed to allocate string")
    }

    fmt.sbprintf(content, "BIF %v %v\n", width, height)

    same_colour_count: u32 = 0
    last_colour := grid[0][0]
    have_new_line := false
    for row in grid {
        for colour, index in row {
            if index == len(row)-1 {
                if last_colour == colour {
                    same_colour_count += 1
                }

                data := (u64(same_colour_count) << 32) | (u64(last_colour.r) << 24) | (u64(last_colour.g) << 16) | (u64(last_colour.b) << 8) | (u64(last_colour.a))
                same_colour_count = 0

                fmt.sbprintf(content, "%v\n", data)
                have_new_line = true
                continue
            }

            if last_colour == colour {
                same_colour_count += 1
            } else {
                data := (u64(same_colour_count) << 32) | (u64(last_colour.r) << 24) | (u64(last_colour.g) << 16) | (u64(last_colour.b) << 8) | (u64(last_colour.a))
                same_colour_count = 1

                fmt.sbprintf(content, "%v ", data)
            }
            last_colour = colour
        }

        if !have_new_line {
            fmt.sbprintf(content, "\n")
            have_new_line = false
        }
    }

    return
}

bezier_curve :: proc(start: [2]f32, mid: [2]f32, end: [2]f32, t: f32) -> [2]f32 {
    temp := [3][2]f32{start, mid, end}

    for r := 1; r < 3; r += 1 {
        for j := 0; j < 3 - r; j += 1 {
            temp[j].x = (1 - t) * temp[j].x + t * temp[int(t) + 1].x;
            temp[j].y = (1 - t) * temp[j].y + t * temp[int(t) + 1].y;
        }
    }

    return temp[0]
}

update :: proc(grid: ^[dynamic][dynamic]rl.Color, grid_rec: rl.Rectangle) {
    // changing colours keybinds
    if rl.IsKeyPressed(.R) {
        current_colour = rl.RED
    } else if rl.IsKeyPressed(.G) {
        current_colour = rl.GREEN
    } else if (rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT)) && rl.IsKeyPressed(.B) {
        current_colour = rl.BLACK
    } else if rl.IsKeyPressed(.B) {
        current_colour = rl.BLUE
    } else if (rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT)) && rl.IsKeyPressed(.P) {
        current_colour = rl.PURPLE
    } else if rl.IsKeyPressed(.P) {
        current_colour = rl.PINK
    } else if rl.IsKeyPressed(.Y) {
        current_colour = rl.YELLOW
    }



    mouse_pos := rl.GetMousePosition()
    if last_mouse_pos[0] == 0 && last_mouse_pos[1] == 0 {
        last_mouse_pos = mouse_pos
    }
    x, y := get_indices_from_mouse_position(mouse_pos, grid_rec)

    if rl.IsMouseButtonDown(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, grid_rec) {
        last_x, last_y := get_indices_from_mouse_position(last_mouse_pos, grid_rec)
        mp_x := (x+last_x) / 2
        mp_y := (y+last_y) / 2

        for i: f32 = 0.0; int(i) <= 1; i += 0.1 {
            bezier_point := bezier_curve([2]f32{f32(last_x), f32(last_y)}, [2]f32{f32(mp_x), f32(mp_y)}, [2]f32{f32(x), f32(y)}, i)
            if int(bezier_point.x) < int(grid_rec.width) && bezier_point.x > 0 && int(bezier_point.y) < int(grid_rec.height) && bezier_point.y > 0 {
                grid[int(bezier_point.x)][int(bezier_point.y)] = current_colour
            }
        }

        grid[x][y] = current_colour
    }
    if rl.IsMouseButtonDown(.RIGHT) && rl.CheckCollisionPointRec(mouse_pos, grid_rec) {
        last_x, last_y := get_indices_from_mouse_position(last_mouse_pos, grid_rec)
        mp_x := (x+last_x) / 2
        mp_y := (y+last_y) / 2

        for i: f32 = 0.0; int(i) <= 1; i += 0.1 {
            bezier_point := bezier_curve([2]f32{f32(last_x), f32(last_y)}, [2]f32{f32(mp_x), f32(mp_y)}, [2]f32{f32(x), f32(y)}, i)
            if int(bezier_point.x) < int(grid_rec.width) && bezier_point.x > 0 && int(bezier_point.y) < int(grid_rec.height) && bezier_point.y > 0 {
                grid[int(bezier_point.x)][int(bezier_point.y)] = rl.Color{255, 255, 255, 255}
            }
        }
        grid[x][y] = rl.Color{255, 255, 255, 255}
    }

    if rl.IsKeyDown(.LEFT_CONTROL) && rl.IsKeyDown(.S) {
        image := get_image(grid, int(grid_rec.width), int(grid_rec.height))
        if os.write_entire_file("../test.bif", image.buf[:]) {
            fmt.println("success")
        } else {
            fmt.println("unable to write to test.bif")
        }
    }

    last_mouse_pos = mouse_pos
}

draw :: proc(grid: [dynamic][dynamic]rl.Color, grid_rec: rl.Rectangle) {
    rl.BeginDrawing()
    rl.ClearBackground(current_colour)

    for i in 0..<int(grid_rec.height) {
        for j in 0..<int(grid_rec.width) {
            colour := grid[i][j]
            rl.DrawPixel(i32(i) + i32(grid_rec.x), i32(j) + i32(grid_rec.y), rl.Color{colour.r, colour.g, colour.b, colour.a})
        }
    }

    rl.EndDrawing()
}

main :: proc() {
    os.args = os.args[1:]
    image_width := strconv.atoi(os.args[0])
    image_height := strconv.atoi(os.args[1])

    grid: [dynamic][dynamic]rl.Color
    for i in 0..<image_height {
        append(&grid, [dynamic]rl.Color{})
        for j in 0..<image_width {
            append(&grid[i], rl.Color{255, 255, 255, 255})
        }
    }

    middle_pos := rl.Vector2{f32(image_width)/2, f32(image_height)/2}
    grid_start_pos := rl.Vector2{middle_pos.x - f32(image_width / 2), middle_pos.y - f32(image_height / 2)}
    grid_rec := rl.Rectangle{grid_start_pos.x, grid_start_pos.y, f32(image_width), f32(image_height)}

    rl.InitWindow(i32(image_width), i32(image_height + 40), "BIF editor")
    defer rl.CloseWindow()

    for !rl.WindowShouldClose() {
        update(&grid, grid_rec)
        draw(grid, grid_rec)
    }
}
