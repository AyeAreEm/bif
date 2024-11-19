package main

import "core:fmt"
import "core:os"
import "core:strconv"
import rl "vendor:raylib"

Colour :: struct {
    r: u8,
    g: u8,
    b: u8,
}

get_indices_from_mouse_position :: proc(mouse_pos: rl.Vector2, grid_rec: rl.Rectangle) -> (int, int) {
    return int(mouse_pos.x - grid_rec.x), int(mouse_pos.y - grid_rec.y)
}

update :: proc(grid: ^[dynamic][dynamic]Colour, grid_rec: rl.Rectangle) {
    mouse_pos := rl.GetMousePosition()
    if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, grid_rec) {
        x, y := get_indices_from_mouse_position(mouse_pos, grid_rec)
        grid[x][y] = Colour{255, 0, 0}
    }

    if rl.IsMouseButtonPressed(.RIGHT) && rl.CheckCollisionPointRec(mouse_pos, grid_rec) {
        x, y := get_indices_from_mouse_position(mouse_pos, grid_rec)
        grid[x][y] = Colour{255, 255, 255}
    }
}

draw :: proc(grid: [dynamic][dynamic]Colour, grid_rec: rl.Rectangle) {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    for i in 0..<int(grid_rec.height) {
        for j in 0..<int(grid_rec.width) {
            colour := grid[i][j]
            rl.DrawPixel(i32(i) + i32(grid_rec.x), i32(j) + i32(grid_rec.y), rl.Color{colour.r, colour.g, colour.b, 255})
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
            append(&grid[i], Colour{255, 255, 255})
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
