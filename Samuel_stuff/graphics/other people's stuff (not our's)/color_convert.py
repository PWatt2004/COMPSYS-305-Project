from os import error
import sys
def hex_to_binary(color):
    # Remove the '#' symbol from the color code
    color = color.lstrip('#')
    
    # Split the color into its RGB components
    r, g, b = color[0:2], color[2:4], color[4:6]
    
    # Convert each component to binary
    r_bin = format(int(r, 16) >> 4, '04b')
    g_bin = format(int(g, 16) >> 4, '04b')
    b_bin = format(int(b, 16) >> 4, '04b')
    
    # Combine the binary components
    binary_color = r_bin + g_bin + b_bin
    
    return binary_color

if (len(sys.argv) > 1):
    color = sys.argv[1]
    print(hex_to_binary(color))

else:
    raise error()
