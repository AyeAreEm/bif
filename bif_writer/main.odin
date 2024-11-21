package main

import "core:fmt"
import "core:strings"
import "core:os"

WIDTH :: 255
HEIGHT :: 255

Colour :: struct {
    r: u8,
    g: u8,
    b: u8,
}

WHITE :: Colour{255, 255, 255}
RED :: Colour{255, 0, 0}
GREEN :: Colour{0, 255, 0}
BLUE :: Colour{0, 0, 255}

fill_image :: proc(colour: Colour) -> (builder: strings.Builder) {
    content, err := strings.builder_init(&builder)
    if err != .None {
        panic("failed to allocate string")
    }

    fmt.sbprintf(content, "BIF %v %v\n", WIDTH, HEIGHT)

    for i in 0..<HEIGHT {
        number := WIDTH
        data := (u32(number) << 24) | (u32(colour.r) << 16) | (u32(colour.g) << 8) | (u32(colour.b))

        fmt.sbprintf(content, "%v\n", data)
    }

    return 
}

main :: proc() {
    content := fill_image(RED)

    if os.write_entire_file("../test.bif", content.buf[:]) {
        fmt.println("success")
    } else {
        fmt.println("unable to write to test.bif")
    }
}
