package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

Colour :: struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}

get_indices_from_mouse_position :: proc(mouse_pos: rl.Vector2, grid_rec: rl.Rectangle) -> (int, int) {
    return int(mouse_pos.x - grid_rec.x), int(mouse_pos.y - grid_rec.y)
}

get_image :: proc(grid: ^[dynamic][dynamic]Colour, width: int, height: int) -> (builder: strings.Builder) {
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

update :: proc(grid: ^[dynamic][dynamic]Colour, grid_rec: rl.Rectangle) {
    mouse_pos := rl.GetMousePosition()
    x, y := get_indices_from_mouse_position(mouse_pos, grid_rec)

    if rl.IsMouseButtonDown(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, grid_rec) {
        grid[x][y] = Colour{255, 0, 0, 255}
    }
    if rl.IsMouseButtonDown(.RIGHT) && rl.CheckCollisionPointRec(mouse_pos, grid_rec) {
        grid[x][y] = Colour{255, 255, 255, 255}
    }

    if rl.IsKeyDown(.LEFT_CONTROL) && rl.IsKeyDown(.S) {
        image := get_image(grid, int(grid_rec.width), int(grid_rec.height))
        if os.write_entire_file("../test.bif", image.buf[:]) {
            fmt.println("success")
        } else {
            fmt.println("unable to write to test.bif")
        }
    }
}

draw :: proc(grid: [dynamic][dynamic]Colour, grid_rec: rl.Rectangle) {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

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

    grid: [dynamic][dynamic]Colour
    for i in 0..<image_height {
        append(&grid, [dynamic]Colour{})
        for j in 0..<image_width {
            append(&grid[i], Colour{255, 255, 255, 255})
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
