package main

import "core:fmt"
import "core:os"
import "core:strconv"
import rl "vendor:raylib"

validate :: proc(buffer: []byte) -> (int, bool) {
    if !(buffer[0] == 'B' && buffer[1] == 'I' && buffer[2] == 'F' && buffer[3] == ' ') {
        return 0, false
    }

    return 4, true
}

get_width_height :: proc(content: []byte) -> (width: int, height: int, index: int) {
    buffer: [dynamic]byte

    for ch, i in content {
        if ch == ' ' {
            width = strconv.atoi(string(buffer[:]))
            clear(&buffer)
        } else if ch == '\n' {
            height = strconv.atoi(string(buffer[:]))
            index = i + 1
            break
        } else {
            append(&buffer, ch)
        }
    }

    return
}

expand_image_data :: proc(pixel_data: [dynamic]u64) -> (pixel_info: [dynamic]rl.Color) {
    for data, i in pixel_data {
        if data == 0 {
            continue
        }

        no_of_pixels: u64 = (data >> 32) & 0xFFFFFFFF
        r: u64 = (data >> 24) & 0xFF
        g: u64 = (data >> 16) & 0xFF
        b: u64 = (data >> 8) & 0xFF
        a: u64 = data & 0xFF

        for j: u64 = 0; j < no_of_pixels; j += 1 {
            append(&pixel_info, rl.Color{u8(r), u8(g), u8(b), u8(a)})
        }
    }

    return
}

handle_image_data :: proc(image: []byte) -> (pixel_info: [dynamic]rl.Color) {
    buffer: [dynamic]byte
    pixel_data: [dynamic]u64

    for ch, _ in image {
        if ch == ' ' {
            append(&pixel_data, u64(strconv.atoi(string(buffer[:]))))
            clear(&buffer)
        } else if ch == '\n' {
            append(&pixel_data, u64(strconv.atoi(string(buffer[:]))))
            append(&pixel_data, u64(0x00000000))
            clear(&buffer)
        } else {
            append(&buffer, ch)
        }
    }

    pixel_info = expand_image_data(pixel_data)

    return
}

draw :: proc(image: [dynamic]rl.Color, width: int, height: int) {
    rl.BeginDrawing()
    rl.ClearBackground(rl.WHITE)

    for i := 0; i < height; i += 1{
        for j := 0; j < width; j += 1{
            rl.DrawPixel(i32(i), i32(j), image[i * width + j])
        }
    }

    rl.EndDrawing()
}

main :: proc() {
    image_data, image_success := os.read_entire_file("../test.bif")
    if !image_success {
        panic("unable to read bif file")
    }

    aspect_index, valid := validate(image_data)
    if !valid {
        panic("file isn't a bif")
    }
    image_data = image_data[aspect_index:]

    width, height, content_index := get_width_height(image_data)
    image_data = image_data[content_index:]

    image := handle_image_data(image_data)

    rl.InitWindow(i32(width), i32(height), "bif viewer")
    defer rl.CloseWindow()

    for !rl.WindowShouldClose() {
        draw(image, width, height)
    }
}
