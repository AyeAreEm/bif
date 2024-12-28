# BIF
Bad Image Format

## Note
This project is just meant to be a learning experience

# Specification
All bif files must start with "BIF {width} {height}\n" as the header<br>
The data is an unsigned 32bit integer where the first 8bits are number of pixels this data represents, and the next 24bits are RGB values in 8bits<br>
<br>
| no. of pixels |  r  |  g  |  b  |  a  |<br>
      u32         u8    u8    u8    u8<br>
<br>
At the end of each row needs to be a newline character

## Example
Here is a 10x10 image of red
```
BIF 10 10
184483840
184483840
184483840
184483840
184483840
184483840
184483840
184483840
184483840
184483840
```
