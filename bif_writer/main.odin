package main

import "core:fmt"
import "core:strings"
import "core:os"

WIDTH: u32 : 500
HEIGHT: u32 : 500

Colour :: struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}

WHITE :: Colour{255, 255, 255, 255}
RED :: Colour{255, 0, 0, 255}
GREEN :: Colour{0, 255, 0, 255}
BLUE :: Colour{0, 0, 255, 255}

fill_image :: proc(colour: Colour) -> (builder: strings.Builder) {
    content, err := strings.builder_init(&builder)
    if err != .None {
        panic("failed to allocate string")
    }

    fmt.sbprintf(content, "BIF %v %v\n", WIDTH, HEIGHT)

    for i in 0..<HEIGHT {
        number := WIDTH
        data := (u64(number) << 32) | (u64(colour.r) << 24) | (u64(colour.g) << 16) | (u64(colour.b) << 8) | (u64(colour.a))

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
